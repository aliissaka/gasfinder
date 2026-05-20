using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using GasFinder.Domain.Entities;
using GasFinder.Domain.Enums;
using GasFinder.Infrastructure.Auth;
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
public class AdminController(AppDbContext db, IPinHasher pinHasher, ILogger<AdminController> log) : ControllerBase
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

        if (!TryGetAdminId(out var adminId))
            return Unauthorized();

        var retailer = await db.Retailers.FirstOrDefaultAsync(r => r.Id == id, ct);
        if (retailer is null) return NotFound();

        var previous = retailer.Status;
        if (previous == newStatus)
        {
            return NoContent();
        }

        var now = DateTimeOffset.UtcNow;
        retailer.Status = newStatus;
        retailer.UpdatedAt = now;

        db.RetailerStatusChanges.Add(new RetailerStatusChange
        {
            Id = Guid.NewGuid(),
            RetailerId = id,
            FromStatus = previous,
            ToStatus = newStatus,
            ChangedByUserId = adminId,
            Reason = string.IsNullOrWhiteSpace(body.Reason) ? null : body.Reason.Trim(),
            ChangedAt = now
        });

        await db.SaveChangesAsync(ct);

        log.LogInformation("Retailer {RetailerId} status {From} -> {To} by {AdminId}", id, previous, newStatus, adminId);
        return NoContent();
    }

    [HttpGet("retailers/{id:guid}/history")]
    public async Task<IActionResult> GetRetailerHistory(Guid id, CancellationToken ct)
    {
        var rows = await db.RetailerStatusChanges
            .AsNoTracking()
            .Where(c => c.RetailerId == id)
            .OrderByDescending(c => c.ChangedAt)
            .Join(db.Users, c => c.ChangedByUserId, u => u.Id, (c, u) => new RetailerStatusChangeDto(
                c.Id,
                c.FromStatus.ToString(),
                c.ToStatus.ToString(),
                c.ChangedByUserId,
                u.DisplayName,
                c.Reason,
                c.ChangedAt))
            .ToListAsync(ct);

        return Ok(rows);
    }

    [HttpGet("dashboard")]
    public async Task<IActionResult> GetDashboard(CancellationToken ct)
    {
        var retailerCounts = await db.Retailers
            .AsNoTracking()
            .GroupBy(r => r.Status)
            .Select(g => new { Status = g.Key, Count = g.Count() })
            .ToListAsync(ct);

        var userCounts = await db.Users
            .AsNoTracking()
            .GroupBy(u => u.Role)
            .Select(g => new { Role = g.Key, Count = g.Count() })
            .ToListAsync(ct);

        var brandCount = await db.Brands.CountAsync(ct);
        var stockCounts = await db.StockItems
            .AsNoTracking()
            .GroupBy(s => s.Status)
            .Select(g => new { Status = g.Key, Count = g.Count() })
            .ToListAsync(ct);
        var stockCount = stockCounts.Sum(x => x.Count);
        var outCount = stockCounts.FirstOrDefault(x => x.Status == StockStatus.Out)?.Count ?? 0;
        var lowCount = stockCounts.FirstOrDefault(x => x.Status == StockStatus.Low)?.Count ?? 0;

        var recent = await db.RetailerStatusChanges
            .AsNoTracking()
            .OrderByDescending(c => c.ChangedAt)
            .Take(10)
            .Join(db.Retailers, c => c.RetailerId, r => r.Id, (c, r) => new { c, r })
            .Join(db.Users, x => x.c.ChangedByUserId, u => u.Id, (x, u) => new RecentStatusChangeDto(
                x.c.RetailerId,
                x.r.ShopName,
                x.c.FromStatus.ToString(),
                x.c.ToStatus.ToString(),
                u.DisplayName,
                x.c.Reason,
                x.c.ChangedAt))
            .ToListAsync(ct);

        int CountForStatus(RetailerStatus s) =>
            retailerCounts.FirstOrDefault(x => x.Status == s)?.Count ?? 0;
        int CountForRole(UserRole r) =>
            userCounts.FirstOrDefault(x => x.Role == r)?.Count ?? 0;

        return Ok(new DashboardSummaryDto(
            CountForStatus(RetailerStatus.Pending),
            CountForStatus(RetailerStatus.Approved),
            CountForStatus(RetailerStatus.Suspended),
            brandCount,
            stockCount,
            outCount,
            lowCount,
            CountForRole(UserRole.Consumer),
            CountForRole(UserRole.Retailer),
            CountForRole(UserRole.Admin),
            recent));
    }

    [HttpGet("users")]
    public async Task<IActionResult> ListUsers([FromQuery] string? role, [FromQuery] string? q, CancellationToken ct)
    {
        var query = db.Users.AsNoTracking();

        if (!string.IsNullOrWhiteSpace(role)
            && Enum.TryParse<UserRole>(role, ignoreCase: true, out var parsedRole))
        {
            query = query.Where(u => u.Role == parsedRole);
        }

        if (!string.IsNullOrWhiteSpace(q))
        {
            var needle = q.Trim();
            query = query.Where(u => u.Phone.Contains(needle)
                                     || (u.DisplayName != null && u.DisplayName.Contains(needle)));
        }

        var rows = await query
            .OrderByDescending(u => u.CreatedAt)
            .Take(200)
            .GroupJoin(db.Retailers, u => u.Id, r => r.UserId, (u, rs) => new { u, rs })
            .SelectMany(x => x.rs.DefaultIfEmpty(), (x, r) => new UserListItemDto(
                x.u.Id,
                x.u.Phone,
                x.u.Role.ToString(),
                x.u.DisplayName,
                r != null ? r.Id : (Guid?)null,
                r != null ? r.ShopName : null,
                r != null ? r.Status.ToString() : null,
                x.u.CreatedAt,
                x.u.UpdatedAt))
            .ToListAsync(ct);

        return Ok(rows);
    }

    [HttpPatch("users/{id:guid}/pin")]
    public async Task<IActionResult> ResetUserPin(Guid id, [FromBody] ResetUserPinRequest body, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(body.NewPin) || body.NewPin.Length is < 4 or > 8 || !body.NewPin.All(char.IsDigit))
            return BadRequest(new { error = "pin must be 4-8 digits" });

        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == id, ct);
        if (user is null) return NotFound();

        user.PinHash = pinHasher.Hash(body.NewPin);
        user.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);

        log.LogWarning("Admin reset PIN for user {UserId}", id);
        return NoContent();
    }

    [HttpPatch("users/{id:guid}/role")]
    public async Task<IActionResult> ChangeUserRole(Guid id, [FromBody] UpdateUserRoleRequest body, CancellationToken ct)
    {
        if (!Enum.TryParse<UserRole>(body.Role, ignoreCase: true, out var newRole))
            return BadRequest(new { error = "invalid role" });

        if (!TryGetAdminId(out var adminId)) return Unauthorized();

        if (adminId == id && newRole != UserRole.Admin)
            return Conflict(new { error = "you cannot demote yourself" });

        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == id, ct);
        if (user is null) return NotFound();

        if (user.Role == UserRole.Admin && newRole != UserRole.Admin)
        {
            var adminCount = await db.Users.CountAsync(u => u.Role == UserRole.Admin, ct);
            if (adminCount <= 1)
                return Conflict(new { error = "cannot remove the last admin" });
        }

        if (user.Role == newRole) return NoContent();

        user.Role = newRole;
        user.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);

        log.LogWarning("User {UserId} role changed to {Role} by {AdminId}", id, newRole, adminId);
        return NoContent();
    }

    [HttpGet("stock")]
    public async Task<IActionResult> ListStock(
        [FromQuery] Guid? brandId,
        [FromQuery] string? status,
        [FromQuery] string? retailerStatus,
        CancellationToken ct)
    {
        var query = from s in db.StockItems.AsNoTracking()
                    join r in db.Retailers on s.RetailerId equals r.Id
                    join b in db.Brands on s.BrandId equals b.Id
                    select new { s, r, b };

        if (brandId is not null)
            query = query.Where(x => x.s.BrandId == brandId);

        if (!string.IsNullOrWhiteSpace(status)
            && Enum.TryParse<StockStatus>(status, ignoreCase: true, out var parsedStatus))
        {
            query = query.Where(x => x.s.Status == parsedStatus);
        }

        if (!string.IsNullOrWhiteSpace(retailerStatus)
            && Enum.TryParse<RetailerStatus>(retailerStatus, ignoreCase: true, out var parsedRetailer))
        {
            query = query.Where(x => x.r.Status == parsedRetailer);
        }

        var rows = await query
            .OrderBy(x => x.s.Status == StockStatus.Out ? 0 : x.s.Status == StockStatus.Low ? 1 : 2)
            .ThenByDescending(x => x.s.LastUpdatedAt)
            .Take(500)
            .Select(x => new AdminStockItemDto(
                x.r.Id, x.r.ShopName, x.r.Status.ToString(),
                x.b.Id, x.b.Name, x.b.LogoUrl,
                x.s.Status.ToString(), x.s.Quantity, x.s.LastUpdatedAt))
            .ToListAsync(ct);

        return Ok(rows);
    }

    [HttpGet("stock/recent")]
    public async Task<IActionResult> ListRecentStockUpdates([FromQuery] int? take, CancellationToken ct)
    {
        var limit = Math.Clamp(take ?? 50, 1, 200);

        var rows = await (from u in db.StockUpdates.AsNoTracking()
                          join r in db.Retailers on u.RetailerId equals r.Id
                          join b in db.Brands on u.BrandId equals b.Id
                          orderby u.ReceivedAt descending
                          select new AdminStockUpdateDto(
                              u.Id, u.RetailerId, r.ShopName,
                              u.BrandId, b.Name,
                              u.Status.ToString(), u.Quantity,
                              u.ReportedAt, u.ReceivedAt))
                         .Take(limit)
                         .ToListAsync(ct);

        return Ok(rows);
    }

    private bool TryGetAdminId(out Guid id)
    {
        var sub = User.FindFirstValue(JwtRegisteredClaimNames.Sub)
                  ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(sub, out id);
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
