namespace GasFinder.Shared.Contracts.Stock;

public record StockUpdateBatchResponse(IReadOnlyList<StockUpdateResult> Results);
