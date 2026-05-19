namespace GasFinder.Shared.Contracts.Admin;

public record BrandUpdateRequest(
    string Name,
    string LogoUrl,
    int DisplayOrder
);
