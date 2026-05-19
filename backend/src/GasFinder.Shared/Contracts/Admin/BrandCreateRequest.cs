namespace GasFinder.Shared.Contracts.Admin;

public record BrandCreateRequest(
    string Name,
    string LogoUrl,
    int DisplayOrder
);
