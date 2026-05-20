namespace GasFinder.Shared.Contracts.Admin;

public record AdminStockItemDto(
    Guid RetailerId,
    string RetailerShopName,
    string RetailerStatus,
    Guid BrandId,
    string BrandName,
    string? BrandLogoUrl,
    string Status,
    int? Quantity,
    DateTimeOffset LastUpdatedAt
);

public record AdminStockUpdateDto(
    Guid Id,
    Guid RetailerId,
    string RetailerShopName,
    Guid BrandId,
    string BrandName,
    string Status,
    int? Quantity,
    DateTimeOffset ReportedAt,
    DateTimeOffset ReceivedAt
);
