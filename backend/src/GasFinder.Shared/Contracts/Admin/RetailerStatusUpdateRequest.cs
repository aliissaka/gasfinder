namespace GasFinder.Shared.Contracts.Admin;

public record RetailerStatusUpdateRequest(string Status, string? Reason = null);
