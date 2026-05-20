namespace GasFinder.Shared.Contracts.Admin;

public record UserListItemDto(
    Guid Id,
    string Phone,
    string Role,
    string? DisplayName,
    Guid? RetailerId,
    string? RetailerShopName,
    string? RetailerStatus,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt
);

public record ResetUserPinRequest(string NewPin);

public record UpdateUserRoleRequest(string Role);
