using GasFinder.Infrastructure.Auth;
using GasFinder.Infrastructure.Persistence;
using GasFinder.Infrastructure.Versioning;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Npgsql;

namespace GasFinder.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration config)
    {
        var conn = config.GetConnectionString("Default")
                   ?? throw new InvalidOperationException("ConnectionStrings:Default not configured");

        conn = NormalizeNpgsqlConnectionString(conn);

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

    // Render/Neon hand out connection strings in URI form (postgresql://user:pass@host/db?sslmode=...),
    // which Npgsql's connection-string builder cannot parse. Convert to key-value form here so the same
    // setting works whether it's the URI Render injects or a hand-written Npgsql string.
    private static string NormalizeNpgsqlConnectionString(string conn)
    {
        if (!conn.StartsWith("postgres://", StringComparison.OrdinalIgnoreCase) &&
            !conn.StartsWith("postgresql://", StringComparison.OrdinalIgnoreCase))
        {
            return conn;
        }

        var uri = new Uri(conn);
        var userInfo = uri.UserInfo.Split(':', 2);
        var builder = new NpgsqlConnectionStringBuilder
        {
            Host = uri.Host,
            Port = uri.IsDefaultPort ? 5432 : uri.Port,
            Username = Uri.UnescapeDataString(userInfo[0]),
            Password = userInfo.Length > 1 ? Uri.UnescapeDataString(userInfo[1]) : "",
            Database = uri.AbsolutePath.TrimStart('/'),
        };

        foreach (var pair in uri.Query.TrimStart('?').Split('&', StringSplitOptions.RemoveEmptyEntries))
        {
            var kv = pair.Split('=', 2);
            if (kv.Length != 2) continue;
            var key = Uri.UnescapeDataString(kv[0]);
            var value = Uri.UnescapeDataString(kv[1]);
            if (key.Equals("sslmode", StringComparison.OrdinalIgnoreCase) &&
                Enum.TryParse<SslMode>(value, ignoreCase: true, out var mode))
            {
                builder.SslMode = mode;
            }
        }

        return builder.ConnectionString;
    }
}
