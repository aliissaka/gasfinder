namespace GasFinder.Shared.Contracts.Admin;

public record PendingRetailerDto(
    Guid Id,
    string ShopName,
    string Phone,
    string? OwnerName,
    string? Address,
    double Latitude,
    double Longitude,
    string Status,
    DateTimeOffset CreatedAt
);
