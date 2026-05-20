using GasFinder.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GasFinder.Infrastructure.Persistence.Configurations;

public class RetailerStatusChangeConfiguration : IEntityTypeConfiguration<RetailerStatusChange>
{
    public void Configure(EntityTypeBuilder<RetailerStatusChange> b)
    {
        b.ToTable("retailer_status_changes");
        b.HasKey(c => c.Id);

        b.Property(c => c.FromStatus).HasConversion<string>().IsRequired();
        b.Property(c => c.ToStatus).HasConversion<string>().IsRequired();
        b.Property(c => c.Reason).HasMaxLength(1024);
        b.Property(c => c.ChangedAt).IsRequired();

        b.HasIndex(c => new { c.RetailerId, c.ChangedAt });
    }
}
