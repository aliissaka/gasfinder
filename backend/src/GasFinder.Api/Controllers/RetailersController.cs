using GasFinder.Domain.Enums;
using GasFinder.Infrastructure.Persistence;
using GasFinder.Shared.Contracts.Retailers;
using GasFinder.Shared.Contracts.Stock;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NetTopologySuite.Geometries;

namespace GasFinder.Api.Controllers;

[ApiController]
[Route("api/retailers")]
public class RetailersController(AppDbContext db) : ControllerBase
{
    private const int DefaultRadiusMeters = 5_000;
    private const int MaxRadiusMeters = 50_000;
    private const int DefaultTake = 50;
    private const int MaxTake = 200;

    [HttpGet]
    public async Task<IActionResult> List(
        [FromQuery] double lat,
        [FromQuery] double lon,
        [FromQuery] int? radiusMeters,
        [FromQuery] string? brandIds,
        [FromQuery] int? take,
        CancellationToken ct)
    {
        if (lat is < -90 or > 90 || lon is < -180 or > 180)
            return BadRequest(new { error = "lat/lon out of range" });

        var radius = Math.Clamp(radiusMeters ?? DefaultRadiusMeters, 1, MaxRadiusMeters);
        var limit  = Math.Clamp(take ?? DefaultTake, 1, MaxTake);

        var filterBrandIds = ParseGuidCsv(brandIds);

        var center = new Point(lon, lat) { SRID = 4326 };

        var query = db.Retailers
            .AsNoTracking()
            .Where(r => r.Status == RetailerStatus.Approved
                        && r.Location.IsWithinDistance(center, radius));

        if (filterBrandIds.Count > 0)
        {
            query = query.Where(r => r.StockItems.Any(s =>
                filterBrandIds.Contains(s.BrandId) && s.Status != StockStatus.Out));
        }

        var rows = await query
            .OrderBy(r => r.Location.Distance(center))
            .Take(limit)
            .Select(r => new
            {
                r.Id,
                r.ShopName,
                r.Location,
                r.Phone,
                r.PhotoUrl,
                r.UpdatedAt,
                AvailableBrandIds = r.StockItems
                    .Where(s => s.Status != StockStatus.Out)
                    .Select(s => s.BrandId)
                    .ToList()
            })
            .ToListAsync(ct);

        var items = rows.Select(r => new RetailerListItem(
            r.Id, r.ShopName, r.Location.Y, r.Location.X, r.Phone, r.PhotoUrl, r.UpdatedAt, r.AvailableBrandIds))
            .ToList();

        return Ok(items);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id, CancellationToken ct)
    {
        var row = await db.Retailers
            .AsNoTracking()
            .Where(r => r.Id == id && r.Status == RetailerStatus.Approved)
            .Select(r => new
            {
                r.Id, r.ShopName, r.Phone, r.Address, r.PhotoUrl, r.OpeningHours, r.UpdatedAt,
                r.Location
            })
            .FirstOrDefaultAsync(ct);

        if (row is null) return NotFound();

        var stockRows = await db.StockItems
            .AsNoTracking()
            .Where(s => s.RetailerId == id)
            .Join(db.Brands, s => s.BrandId, b => b.Id, (s, b) => new
            {
                b.Id, b.Name, b.LogoUrl, s.Status, s.Quantity, s.LastUpdatedAt
            })
            .ToListAsync(ct);

        var stock = stockRows
            .OrderBy(s => s.Name)
            .Select(s => new StockItemDto(
                s.Id, s.Name, s.LogoUrl, s.Status.ToString(), s.Quantity, s.LastUpdatedAt))
            .ToList();

        return Ok(new RetailerDetail(
            row.Id, row.ShopName, row.Location.Y, row.Location.X, row.Phone, row.Address, row.PhotoUrl,
            row.OpeningHours, row.UpdatedAt, stock));
    }

    private static List<Guid> ParseGuidCsv(string? csv)
    {
        if (string.IsNullOrWhiteSpace(csv)) return [];
        return csv.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(s => Guid.TryParse(s, out var g) ? g : (Guid?)null)
            .Where(g => g.HasValue)
            .Select(g => g!.Value)
            .ToList();
    }
}
