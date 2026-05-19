using GasFinder.Domain.Entities;

namespace GasFinder.Infrastructure.Auth;

public interface IJwtTokenIssuer
{
    (string Token, DateTimeOffset ExpiresAt) Issue(User user, Guid? retailerId);
}
