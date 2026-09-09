namespace GasFinder.Shared.Contracts.Stock;

public record StockUpdateRequest(
    Guid ClientOutboxId,
    Guid BrandId,
    string BottleSize,
    string Status,
    int? Quantity,
    DateTimeOffset ReportedAt
);
