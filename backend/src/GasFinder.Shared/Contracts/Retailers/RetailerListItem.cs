namespace GasFinder.Shared.Contracts.Retailers;

public record RetailerListItem(
    Guid Id,
    string ShopName,
    double Latitude,
    double Longitude,
    string Phone,
    string? PhotoUrl,
    DateTimeOffset UpdatedAt,
    IReadOnlyList<Guid> AvailableBrandIds
);
