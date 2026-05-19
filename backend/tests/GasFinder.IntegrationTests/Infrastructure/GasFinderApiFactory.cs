using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;

namespace GasFinder.IntegrationTests.Infrastructure;

public class GasFinderApiFactory(string connectionString) : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.UseSetting("ConnectionStrings:Default", connectionString);
        builder.UseSetting("Jwt:Issuer", "gasfinder-test");
        builder.UseSetting("Jwt:Audience", "gasfinder-test-clients");
        builder.UseSetting("Jwt:SigningKey", "integration-test-signing-key-must-be-at-least-32-bytes-long");
        builder.UseSetting("Jwt:AccessTokenLifetimeDays", "1");
    }
}
