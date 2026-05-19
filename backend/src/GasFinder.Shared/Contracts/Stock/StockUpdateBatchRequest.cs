namespace GasFinder.Shared.Contracts.Stock;

public record StockUpdateBatchRequest(IReadOnlyList<StockUpdateRequest> Updates);
