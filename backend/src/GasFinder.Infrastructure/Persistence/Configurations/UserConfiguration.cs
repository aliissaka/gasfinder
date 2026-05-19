using GasFinder.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GasFinder.Infrastructure.Persistence.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> b)
    {
        b.ToTable("users");
        b.HasKey(u => u.Id);

        b.Property(u => u.Phone).IsRequired().HasMaxLength(32);
        b.HasIndex(u => u.Phone).IsUnique();

        b.Property(u => u.PinHash).IsRequired();
        b.Property(u => u.Role).HasConversion<string>().IsRequired();
        b.Property(u => u.DisplayName).HasMaxLength(128);

        b.Property(u => u.CreatedAt).IsRequired();
        b.Property(u => u.UpdatedAt).IsRequired();
    }
}
