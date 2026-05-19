using GasFinder.Infrastructure.Persistence;
using GasFinder.Shared.Contracts.Brands;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GasFinder.Api.Controllers;

[ApiController]
[Route("api/brands")]
public class BrandsController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IReadOnlyList<BrandDto>> List(CancellationToken ct)
        => await db.Brands
            .AsNoTracking()
            .OrderBy(b => b.DisplayOrder).ThenBy(b => b.Name)
            .Select(b => new BrandDto(b.Id, b.Name, b.LogoUrl, b.DisplayOrder, b.UpdatedAt))
            .ToListAsync(ct);
}
