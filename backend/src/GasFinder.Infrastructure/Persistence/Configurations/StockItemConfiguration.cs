using GasFinder.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GasFinder.Infrastructure.Persistence.Configurations;

public class StockItemConfiguration : IEntityTypeConfiguration<StockItem>
{
    public void Configure(EntityTypeBuilder<StockItem> b)
    {
        b.ToTable("stock_items");
        b.HasKey(s => new { s.RetailerId, s.BrandId });

        b.Property(s => s.Status).HasConversion<string>().IsRequired();
        b.Property(s => s.LastUpdatedAt).IsRequired();
        b.HasIndex(s => s.LastUpdatedAt);
        b.HasIndex(s => s.RetailerId);

        b.HasOne(s => s.Retailer)
            .WithMany(r => r.StockItems)
            .HasForeignKey(s => s.RetailerId)
            .OnDelete(DeleteBehavior.Cascade);

        b.HasOne(s => s.Brand)
            .WithMany()
            .HasForeignKey(s => s.BrandId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
