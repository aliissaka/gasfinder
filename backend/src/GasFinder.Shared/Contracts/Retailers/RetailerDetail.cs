using GasFinder.Shared.Contracts.Stock;

namespace GasFinder.Shared.Contracts.Retailers;

public record RetailerDetail(
    Guid Id,
    string ShopName,
    double Latitude,
    double Longitude,
    string Phone,
    string? Address,
    string? PhotoUrl,
    string OpeningHours,
    DateTimeOffset UpdatedAt,
    IReadOnlyList<StockItemDto> Stock
);
