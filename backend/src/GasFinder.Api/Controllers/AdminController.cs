using GasFinder.Domain.Entities;
using GasFinder.Domain.Enums;
using GasFinder.Infrastructure.Persistence;
using GasFinder.Shared.Contracts.Admin;
using GasFinder.Shared.Contracts.Brands;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GasFinder.Api.Controllers;

[ApiController]
[Route("api/admin")]
[Authorize(Roles = nameof(UserRole.Admin))]
public class AdminController(AppDbContext db, ILogger<AdminController> log) : ControllerBase
{
    [HttpGet("retailers")]
    public async Task<IActionResult> ListRetailers([FromQuery] string? status, CancellationToken ct)
    {
        var q = db.Retailers.AsNoTracking().Join(db.Users, r => r.UserId, u => u.Id, (r, u) => new { r, u });

        if (!string.IsNullOrWhiteSpace(status)
            && Enum.TryParse<RetailerStatus>(status, ignoreCase: true, out var parsed))
        {
            q = q.Where(x => x.r.Status == parsed);
        }

        var raw = await q
            .OrderByDescending(x => x.r.CreatedAt)
            .Select(x => new
            {
                x.r.Id, x.r.ShopName, x.r.Phone, x.u.DisplayName, x.r.Address,
                x.r.Location, Status = x.r.Status, x.r.CreatedAt
            })
            .ToListAsync(ct);

        var rows = raw.Select(x => new PendingRetailerDto(
            x.Id, x.ShopName, x.Phone, x.DisplayName, x.Address,
            x.Location.Y, x.Location.X,
            x.Status.ToString(), x.CreatedAt)).ToList();

        return Ok(rows);
    }

    [HttpPatch("retailers/{id:guid}/status")]
    public async Task<IActionResult> SetRetailerStatus(Guid id, [FromBody] RetailerStatusUpdateRequest body, CancellationToken ct)
    {
        if (!Enum.TryParse<RetailerStatus>(body.Status, ignoreCase: true, out var newStatus))
            return BadRequest(new { error = "invalid status" });

        var retailer = await db.Retailers.FirstOrDefaultAsync(r => r.Id == id, ct);
        if (retailer is null) return NotFound();

        retailer.Status = newStatus;
        retailer.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);

        log.LogInformation("Retailer {RetailerId} status set to {Status}", id, newStatus);
        return NoContent();
    }

    [HttpGet("brands")]
    public async Task<IReadOnlyList<BrandDto>> ListBrands(CancellationToken ct)
        => await db.Brands
            .AsNoTracking()
            .OrderBy(b => b.DisplayOrder).ThenBy(b => b.Name)
            .Select(b => new BrandDto(b.Id, b.Name, b.LogoUrl, b.DisplayOrder, b.UpdatedAt))
            .ToListAsync(ct);

    [HttpPost("brands")]
    public async Task<IActionResult> CreateBrand([FromBody] BrandCreateRequest body, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(body.Name) || string.IsNullOrWhiteSpace(body.LogoUrl))
            return BadRequest(new { error = "name and logoUrl are required" });

        var nameTaken = await db.Brands.AnyAsync(b => b.Name == body.Name, ct);
        if (nameTaken) return Conflict(new { error = "brand name already exists" });

        var now = DateTimeOffset.UtcNow;
        var brand = new Brand
        {
            Id = Guid.NewGuid(),
            Name = body.Name.Trim(),
            LogoUrl = body.LogoUrl.Trim(),
            DisplayOrder = body.DisplayOrder,
            CreatedAt = now,
            UpdatedAt = now
        };
        db.Brands.Add(brand);
        await db.SaveChangesAsync(ct);

        return CreatedAtAction(nameof(ListBrands), null,
            new BrandDto(brand.Id, brand.Name, brand.LogoUrl, brand.DisplayOrder, brand.UpdatedAt));
    }

    [HttpPut("brands/{id:guid}")]
    public async Task<IActionResult> UpdateBrand(Guid id, [FromBody] BrandUpdateRequest body, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(body.Name) || string.IsNullOrWhiteSpace(body.LogoUrl))
            return BadRequest(new { error = "name and logoUrl are required" });

        var brand = await db.Brands.FirstOrDefaultAsync(b => b.Id == id, ct);
        if (brand is null) return NotFound();

        brand.Name = body.Name.Trim();
        brand.LogoUrl = body.LogoUrl.Trim();
        brand.DisplayOrder = body.DisplayOrder;
        brand.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);

        return NoContent();
    }

    [HttpDelete("brands/{id:guid}")]
    public async Task<IActionResult> DeleteBrand(Guid id, CancellationToken ct)
    {
        var brand = await db.Brands.FirstOrDefaultAsync(b => b.Id == id, ct);
        if (brand is null) return NotFound();

        var inUse = await db.StockItems.AnyAsync(s => s.BrandId == id, ct);
        if (inUse) return Conflict(new { error = "brand is referenced by stock items" });

        db.Brands.Remove(brand);
        await db.SaveChangesAsync(ct);
        return NoContent();
    }
}
