namespace GasFinder.Domain.Entities;

public class Brand
{
    public Guid Id { get; set; }
    public string Name { get; set; } = default!;
    public string LogoUrl { get; set; } = default!;
    public int DisplayOrder { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
}
