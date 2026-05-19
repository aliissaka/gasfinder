namespace GasFinder.Shared.Contracts.Version;

public record AppVersionResponse(
    string App,
    int MinimumVersion,
    int RecommendedVersion,
    bool Critical,
    string? PlayStoreUrl,
    string? Message
);
