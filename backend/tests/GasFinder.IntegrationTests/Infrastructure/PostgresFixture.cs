using GasFinder.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Testcontainers.PostgreSql;

namespace GasFinder.IntegrationTests.Infrastructure;

public class PostgresFixture : IAsyncLifetime
{
#pragma warning disable CS0618 // parameterless PostgreSqlBuilder ctor scheduled for removal; .WithImage still required to pick PostGIS image
    private readonly PostgreSqlContainer _container = new PostgreSqlBuilder()
        .WithImage("postgis/postgis:16-3.4")
        .WithDatabase("gasfinder_test")
        .WithUsername("gasfinder")
        .WithPassword("gasfinder_test_password")
        .Build();
#pragma warning restore CS0618

    public string ConnectionString => _container.GetConnectionString();

    public async Task InitializeAsync()
    {
        await _container.StartAsync();

        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql(ConnectionString, npg => npg.UseNetTopologySuite())
            .Options;

        await using var db = new AppDbContext(options);
        await db.Database.MigrateAsync();
    }

    public Task DisposeAsync() => _container.DisposeAsync().AsTask();
}

[CollectionDefinition("postgres")]
public class PostgresCollection : ICollectionFixture<PostgresFixture>;
