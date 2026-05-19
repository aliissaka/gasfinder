using GasFinder.Shared.Contracts.Retailers;

namespace GasFinder.Shared.Contracts.Sync;

public record RetailerSyncResponse(
    string Cursor,
    IReadOnlyList<RetailerListItem> Changes,
    IReadOnlyList<Guid> Deletes
);
