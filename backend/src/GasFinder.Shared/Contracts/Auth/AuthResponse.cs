namespace GasFinder.Shared.Contracts.Auth;

public record AuthResponse(
    string AccessToken,
    DateTimeOffset ExpiresAt,
    Guid UserId,
    string Role,
    Guid? RetailerId,
    string? RetailerStatus
);
