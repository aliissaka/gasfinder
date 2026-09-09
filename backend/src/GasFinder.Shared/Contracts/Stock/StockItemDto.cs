namespace GasFinder.Shared.Contracts.Stock;

public record StockItemDto(
    Guid BrandId,
    string BrandName,
    string LogoUrl,
    string BottleSize,
    string Status,
    int? Quantity,
    DateTimeOffset LastUpdatedAt
);
