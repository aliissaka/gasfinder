using GasFinder.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GasFinder.Infrastructure.Persistence.Configurations;

public class RetailerConfiguration : IEntityTypeConfiguration<Retailer>
{
    public void Configure(EntityTypeBuilder<Retailer> b)
    {
        b.ToTable("retailers");
        b.HasKey(r => r.Id);

        b.Property(r => r.ShopName).IsRequired().HasMaxLength(256);
        b.Property(r => r.Phone).IsRequired().HasMaxLength(32);
        b.Property(r => r.Address).HasMaxLength(512);
        b.Property(r => r.PhotoUrl).HasMaxLength(1024);

        b.Property(r => r.Location)
            .HasColumnType("geography (Point, 4326)")
            .IsRequired();
        b.HasIndex(r => r.Location).HasMethod("GIST");

        b.Property(r => r.OpeningHours).HasColumnType("jsonb").IsRequired();
        b.Property(r => r.Status).HasConversion<string>().IsRequired();

        b.Property(r => r.CreatedAt).IsRequired();
        b.Property(r => r.UpdatedAt).IsRequired();
        b.HasIndex(r => r.UpdatedAt);

        b.HasOne(r => r.User)
            .WithMany()
            .HasForeignKey(r => r.UserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
