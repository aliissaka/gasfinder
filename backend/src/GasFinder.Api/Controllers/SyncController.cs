using GasFinder.Domain.Enums;
using GasFinder.Infrastructure.Persistence;
using GasFinder.Shared.Contracts.Brands;
using GasFinder.Shared.Contracts.Retailers;
using GasFinder.Shared.Contracts.Sync;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NetTopologySuite.Geometries;

namespace GasFinder.Api.Controllers;

[ApiController]
[Route("api/sync")]
public class SyncController(AppDbContext db) : ControllerBase
{
    private const int DefaultRadiusMeters = 10_000;
    private const int MaxRadiusMeters = 50_000;
    private const int MaxPageSize = 500;

    [HttpGet("brands")]
    public async Task<BrandSyncResponse> Brands([FromQuery] string? cursor, CancellationToken ct)
    {
        var since = SyncCursor.Parse(cursor);

        var changes = await db.Brands
            .AsNoTracking()
            .Where(b => b.UpdatedAt > since)
            .OrderBy(b => b.UpdatedAt)
            .Take(MaxPageSize)
            .Select(b => new BrandDto(b.Id, b.Name, b.LogoUrl, b.DisplayOrder, b.UpdatedAt))
            .ToListAsync(ct);

        var nextCursor = changes.Count > 0
            ? SyncCursor.Encode(changes[^1].UpdatedAt)
            : cursor ?? SyncCursor.Encode(since);

        return new BrandSyncResponse(nextCursor, changes, Array.Empty<Guid>());
    }

    [HttpGet("retailers")]
    public async Task<IActionResult> Retailers(
        [FromQuery] double lat,
        [FromQuery] double lon,
        [FromQuery] int? radiusMeters,
        [FromQuery] string? cursor,
        CancellationToken ct)
    {
        if (lat is < -90 or > 90 || lon is < -180 or > 180)
            return BadRequest(new { error = "lat/lon out of range" });

        var radius = Math.Clamp(radiusMeters ?? DefaultRadiusMeters, 1, MaxRadiusMeters);
        var since = SyncCursor.Parse(cursor);
        var center = new Point(lon, lat) { SRID = 4326 };

        var changed = await db.Retailers
            .AsNoTracking()
            .Where(r => r.UpdatedAt > since
                        && r.Status == RetailerStatus.Approved
                        && r.Location.IsWithinDistance(center, radius))
            .OrderBy(r => r.UpdatedAt)
            .Take(MaxPageSize)
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

        var deletes = await db.Retailers
            .AsNoTracking()
            .Where(r => r.UpdatedAt > since
                        && r.Status != RetailerStatus.Approved
                        && r.Location.IsWithinDistance(center, radius))
            .Select(r => r.Id)
            .ToListAsync(ct);

        var changes = changed.Select(r => new RetailerListItem(
            r.Id, r.ShopName, r.Location.Y, r.Location.X, r.Phone, r.PhotoUrl, r.UpdatedAt, r.AvailableBrandIds))
            .ToList();

        var lastTimestamp = changed.Count > 0 ? changed[^1].UpdatedAt : since;
        var nextCursor = SyncCursor.Encode(lastTimestamp);

        return Ok(new RetailerSyncResponse(nextCursor, changes, deletes));
    }
}
