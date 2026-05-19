namespace GasFinder.Shared.Contracts.Stock;

public record StockItemDto(
    Guid BrandId,
    string BrandName,
    string LogoUrl,
    string Status,
    int? Quantity,
    DateTimeOffset LastUpdatedAt
);
