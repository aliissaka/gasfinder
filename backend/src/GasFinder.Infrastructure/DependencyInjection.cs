using GasFinder.Infrastructure.Auth;
using GasFinder.Infrastructure.Persistence;
using GasFinder.Infrastructure.Versioning;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace GasFinder.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration config)
    {
        var conn = config.GetConnectionString("Default")
                   ?? throw new InvalidOperationException("ConnectionStrings:Default not configured");

        services.AddDbContext<AppDbContext>(opts =>
            opts.UseNpgsql(conn, npg => npg.UseNetTopologySuite()));

        services.AddOptions<JwtOptions>()
            .Bind(config.GetSection(JwtOptions.SectionName))
            .Validate(o => !string.IsNullOrWhiteSpace(o.SigningKey), "Jwt:SigningKey is required")
            .Validate(o => !string.IsNullOrWhiteSpace(o.Issuer),     "Jwt:Issuer is required")
            .Validate(o => !string.IsNullOrWhiteSpace(o.Audience),   "Jwt:Audience is required")
            .ValidateOnStart();

        services.AddSingleton<IPinHasher, Argon2PinHasher>();
        services.AddSingleton<IJwtTokenIssuer, JwtTokenIssuer>();

        services.Configure<AppVersionOptions>(config.GetSection(AppVersionOptions.SectionName));

        return services;
    }
}
