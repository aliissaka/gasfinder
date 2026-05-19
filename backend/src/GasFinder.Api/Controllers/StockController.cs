using GasFinder.Api.Auth;
using GasFinder.Domain.Entities;
using GasFinder.Domain.Enums;
using GasFinder.Infrastructure.Persistence;
using GasFinder.Shared.Contracts.Stock;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GasFinder.Api.Controllers;

[ApiController]
[Route("api/stock")]
[Authorize(Roles = nameof(UserRole.Retailer))]
public class StockController(AppDbContext db, ILogger<StockController> log) : ControllerBase
{
    private const int MaxBatchSize = 100;

    [HttpGet("me")]
    public async Task<IActionResult> GetMine(CancellationToken ct)
    {
        var retailerId = User.RetailerId();
        if (retailerId is null) return Unauthorized();

        var rows = await db.StockItems
            .AsNoTracking()
            .Where(s => s.RetailerId == retailerId)
            .Join(db.Brands, s => s.BrandId, b => b.Id, (s, b) => new
            {
                b.Id, b.Name, b.LogoUrl, s.Status, s.Quantity, s.LastUpdatedAt
            })
            .ToListAsync(ct);

        var stock = rows
            .OrderBy(s => s.Name)
            .Select(s => new StockItemDto(
                s.Id, s.Name, s.LogoUrl, s.Status.ToString(), s.Quantity, s.LastUpdatedAt))
            .ToList();

        return Ok(stock);
    }

    [HttpPost("updates")]
    public async Task<IActionResult> Submit([FromBody] StockUpdateBatchRequest body, CancellationToken ct)
    {
        var retailerId = User.RetailerId();
        if (retailerId is null) return Unauthorized();

        if (body.Updates is null || body.Updates.Count == 0)
            return BadRequest(new { error = "updates is required" });
        if (body.Updates.Count > MaxBatchSize)
            return BadRequest(new { error = $"batch size exceeds {MaxBatchSize}" });

        var now = DateTimeOffset.UtcNow;
        var results = new List<StockUpdateResult>(body.Updates.Count);

        var clientIds = body.Updates.Select(u => u.ClientOutboxId).ToList();
        var alreadySeen = await db.StockUpdates
            .Where(s => s.RetailerId == retailerId && clientIds.Contains(s.ClientOutboxId))
            .Select(s => s.ClientOutboxId)
            .ToListAsync(ct);
        var alreadySeenSet = alreadySeen.ToHashSet();

        var validBrandIds = await db.Brands
            .Where(b => body.Updates.Select(u => u.BrandId).Contains(b.Id))
            .Select(b => b.Id)
            .ToListAsync(ct);
        var validBrandSet = validBrandIds.ToHashSet();

        foreach (var u in body.Updates)
        {
            if (alreadySeenSet.Contains(u.ClientOutboxId))
            {
                results.Add(new StockUpdateResult(u.ClientOutboxId, StockUpdateOutcomes.Duplicate, null));
                continue;
            }

            if (!Enum.TryParse<StockStatus>(u.Status, ignoreCase: true, out var status))
            {
                results.Add(new StockUpdateResult(u.ClientOutboxId, StockUpdateOutcomes.Rejected,
                    $"unknown status '{u.Status}'"));
                continue;
            }

            if (!validBrandSet.Contains(u.BrandId))
            {
                results.Add(new StockUpdateResult(u.ClientOutboxId, StockUpdateOutcomes.Rejected,
                    "unknown brandId"));
                continue;
            }

            db.StockUpdates.Add(new StockUpdate
            {
                Id = Guid.NewGuid(),
                RetailerId = retailerId.Value,
                BrandId = u.BrandId,
                Status = status,
                Quantity = u.Quantity,
                ReportedAt = u.ReportedAt,
                ReceivedAt = now,
                ClientOutboxId = u.ClientOutboxId
            });

            var item = await db.StockItems
                .FirstOrDefaultAsync(s => s.RetailerId == retailerId && s.BrandId == u.BrandId, ct);
            if (item is null)
            {
                db.StockItems.Add(new StockItem
                {
                    RetailerId = retailerId.Value,
                    BrandId = u.BrandId,
                    Status = status,
                    Quantity = u.Quantity,
                    LastUpdatedAt = u.ReportedAt
                });
            }
            else if (u.ReportedAt >= item.LastUpdatedAt)
            {
                item.Status = status;
                item.Quantity = u.Quantity;
                item.LastUpdatedAt = u.ReportedAt;
            }

            results.Add(new StockUpdateResult(u.ClientOutboxId, StockUpdateOutcomes.Accepted, null));
        }

        try
        {
            await db.SaveChangesAsync(ct);

            if (results.Any(r => r.Outcome == StockUpdateOutcomes.Accepted))
            {
                await db.Retailers
                    .Where(r => r.Id == retailerId)
                    .ExecuteUpdateAsync(s => s.SetProperty(r => r.UpdatedAt, now), ct);
            }
        }
        catch (DbUpdateException ex)
        {
            log.LogWarning(ex, "Concurrent stock update collision for retailer {RetailerId}", retailerId);
            return Conflict(new { error = "stale update, retry" });
        }

        return Ok(new StockUpdateBatchResponse(results));
    }
}
