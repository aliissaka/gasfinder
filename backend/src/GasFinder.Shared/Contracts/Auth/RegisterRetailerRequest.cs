namespace GasFinder.Shared.Contracts.Auth;

public record RegisterRetailerRequest(
    string OwnerPhone,
    string Pin,
    string? OwnerName,
    string ShopName,
    string ShopPhone,
    double ShopLatitude,
    double ShopLongitude,
    string? ShopAddress
);
