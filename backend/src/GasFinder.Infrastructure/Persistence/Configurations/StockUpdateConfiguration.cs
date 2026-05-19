using GasFinder.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GasFinder.Infrastructure.Persistence.Configurations;

public class StockUpdateConfiguration : IEntityTypeConfiguration<StockUpdate>
{
    public void Configure(EntityTypeBuilder<StockUpdate> b)
    {
        b.ToTable("stock_updates");
        b.HasKey(s => s.Id);

        b.Property(s => s.Status).HasConversion<string>().IsRequired();
        b.Property(s => s.ReportedAt).IsRequired();
        b.Property(s => s.ReceivedAt).IsRequired();
        b.Property(s => s.ClientOutboxId).IsRequired();

        b.HasIndex(s => s.ReceivedAt);
        b.HasIndex(s => new { s.RetailerId, s.ClientOutboxId }).IsUnique();

        b.HasOne(s => s.Retailer)
            .WithMany()
            .HasForeignKey(s => s.RetailerId)
            .OnDelete(DeleteBehavior.Restrict);

        b.HasOne(s => s.Brand)
            .WithMany()
            .HasForeignKey(s => s.BrandId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
