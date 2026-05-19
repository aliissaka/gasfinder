using GasFinder.Infrastructure.Versioning;
using GasFinder.Shared.Contracts.Version;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace GasFinder.Api.Controllers;

[ApiController]
[Route("api/version")]
public class VersionController(IOptionsMonitor<AppVersionOptions> options) : ControllerBase
{
    [HttpGet("{app}")]
    public ActionResult<AppVersionResponse> Get(string app)
    {
        var policy = options.CurrentValue.Apps.GetValueOrDefault(app);
        if (policy is null) return NotFound(new { error = "unknown app" });

        return new AppVersionResponse(
            app.ToLowerInvariant(),
            policy.MinimumVersion,
            policy.RecommendedVersion,
            policy.Critical,
            policy.PlayStoreUrl,
            policy.Message
        );
    }
}
