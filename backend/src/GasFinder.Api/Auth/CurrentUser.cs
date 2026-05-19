using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace GasFinder.Api.Auth;

public static class CurrentUser
{
    public static Guid? UserId(this ClaimsPrincipal user)
    {
        var raw = user.FindFirst(JwtRegisteredClaimNames.Sub)?.Value
                  ?? user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return Guid.TryParse(raw, out var id) ? id : null;
    }

    public static Guid? RetailerId(this ClaimsPrincipal user)
    {
        var raw = user.FindFirst("retailer_id")?.Value;
        return Guid.TryParse(raw, out var id) ? id : null;
    }

    public static string? Role(this ClaimsPrincipal user)
        => user.FindFirst(ClaimTypes.Role)?.Value;
}
