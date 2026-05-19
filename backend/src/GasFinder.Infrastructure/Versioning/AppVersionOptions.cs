namespace GasFinder.Infrastructure.Versioning;

public class AppVersionOptions
{
    public const string SectionName = "AppVersion";

    public Dictionary<string, AppVersionPolicy> Apps { get; set; } = new(StringComparer.OrdinalIgnoreCase);
}

public class AppVersionPolicy
{
    public int MinimumVersion { get; set; }
    public int RecommendedVersion { get; set; }
    public bool Critical { get; set; }
    public string? PlayStoreUrl { get; set; }
    public string? Message { get; set; }
}
