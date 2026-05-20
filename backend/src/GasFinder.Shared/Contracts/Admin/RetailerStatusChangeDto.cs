namespace GasFinder.Shared.Contracts.Admin;

public record RetailerStatusChangeDto(
    Guid Id,
    string FromStatus,
    string ToStatus,
    Guid ChangedByUserId,
    string? ChangedByDisplayName,
    string? Reason,
    DateTimeOffset ChangedAt
);
