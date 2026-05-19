using GasFinder.Shared.Contracts.Brands;

namespace GasFinder.Shared.Contracts.Sync;

public record BrandSyncResponse(
    string Cursor,
    IReadOnlyList<BrandDto> Changes,
    IReadOnlyList<Guid> Deletes
);
