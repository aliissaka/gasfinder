namespace GasFinder.Shared.Contracts.Stock;

public record StockUpdateResult(
    Guid ClientOutboxId,
    string Outcome,
    string? Message
);

public static class StockUpdateOutcomes
{
    public const string Accepted = "accepted";
    public const string Duplicate = "duplicate";
    public const string Rejected = "rejected";
}
