using GasFinder.Domain.Enums;

namespace GasFinder.Domain.Entities;

public class User
{
    public Guid Id { get; set; }
    public string Phone { get; set; } = default!;
    public string PinHash { get; set; } = default!;
    public UserRole Role { get; set; }
    public string? DisplayName { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
}
