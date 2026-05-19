namespace GasFinder.Shared.Contracts.Brands;

public record BrandDto(
    Guid Id,
    string Name,
    string LogoUrl,
    int DisplayOrder,
    DateTimeOffset UpdatedAt
);
