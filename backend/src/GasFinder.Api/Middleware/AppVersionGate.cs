using GasFinder.Infrastructure.Versioning;
using GasFinder.Shared.Contracts.Version;
using Microsoft.Extensions.Options;

namespace GasFinder.Api.Middleware;

/// <summary>
/// If the client sends X-App-Name + X-App-Version and the version is below the
/// configured minimum for that app, returns 426 Upgrade Required with the
/// version policy in the body. The /api/version and /health endpoints are
/// always allowed through so the client can recover.
/// </summary>
public class AppVersionGate(RequestDelegate next, IOptionsMonitor<AppVersionOptions> options)
{
    private static readonly PathString VersionPath = new("/api/version");
    private static readonly PathString HealthPath = new("/health");

    public async Task InvokeAsync(HttpContext ctx)
    {
        if (ctx.Request.Path.StartsWithSegments(VersionPath) ||
            ctx.Request.Path.StartsWithSegments(HealthPath))
        {
            await next(ctx);
            return;
        }

        var appName = ctx.Request.Headers["X-App-Name"].ToString();
        var versionHeader = ctx.Request.Headers["X-App-Version"].ToString();

        if (!string.IsNullOrEmpty(appName)
            && int.TryParse(versionHeader, out var clientVersion)
            && options.CurrentValue.Apps.TryGetValue(appName, out var policy)
            && clientVersion < policy.MinimumVersion)
        {
            ctx.Response.StatusCode = StatusCodes.Status426UpgradeRequired;
            await ctx.Response.WriteAsJsonAsync(new AppVersionResponse(
                appName.ToLowerInvariant(),
                policy.MinimumVersion,
                policy.RecommendedVersion,
                policy.Critical,
                policy.PlayStoreUrl,
                policy.Message
            ));
            return;
        }

        await next(ctx);
    }
}
