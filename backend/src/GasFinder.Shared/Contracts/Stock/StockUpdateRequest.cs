namespace GasFinder.Shared.Contracts.Stock;

public record StockUpdateRequest(
    Guid ClientOutboxId,
    Guid BrandId,
    string Status,
    int? Quantity,
    DateTimeOffset ReportedAt
);
