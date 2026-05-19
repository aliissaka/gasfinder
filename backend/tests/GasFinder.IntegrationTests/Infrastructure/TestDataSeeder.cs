using GasFinder.Domain.Entities;
using GasFinder.Domain.Enums;
using GasFinder.Infrastructure.Auth;
using GasFinder.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace GasFinder.IntegrationTests.Infrastructure;

public static class TestDataSeeder
{
    public static async Task<(Guid AdminId, Guid ShellId, Guid TotalId)> SeedAsync(string connectionString)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql(connectionString, npg => npg.UseNetTopologySuite())
            .Options;
        await using var db = new AppDbContext(options);

        var hasher = new Argon2PinHasher();
        var now = DateTimeOffset.UtcNow;

        var admin = new User
        {
            Id = Guid.NewGuid(),
            Phone = "+221000000000",
            PinHash = hasher.Hash("9999"),
            Role = UserRole.Admin,
            DisplayName = "Admin",
            CreatedAt = now,
            UpdatedAt = now
        };
        db.Users.Add(admin);

        var shell = new Brand { Id = Guid.NewGuid(), Name = "Shell", LogoUrl = "https://example/shell.webp", DisplayOrder = 10, CreatedAt = now, UpdatedAt = now };
        var total = new Brand { Id = Guid.NewGuid(), Name = "Total", LogoUrl = "https://example/total.webp", DisplayOrder = 20, CreatedAt = now, UpdatedAt = now };
        db.Brands.AddRange(shell, total);

        await db.SaveChangesAsync();

        return (admin.Id, shell.Id, total.Id);
    }
}
