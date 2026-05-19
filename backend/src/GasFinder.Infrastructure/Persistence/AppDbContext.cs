using GasFinder.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace GasFinder.Infrastructure.Persistence;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Retailer> Retailers => Set<Retailer>();
    public DbSet<Brand> Brands => Set<Brand>();
    public DbSet<StockItem> StockItems => Set<StockItem>();
    public DbSet<StockUpdate> StockUpdates => Set<StockUpdate>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasPostgresExtension("postgis");
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
    }
}
