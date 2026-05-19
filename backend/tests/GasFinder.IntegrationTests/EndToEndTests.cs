using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using GasFinder.IntegrationTests.Infrastructure;
using GasFinder.Shared.Contracts.Admin;
using GasFinder.Shared.Contracts.Auth;
using GasFinder.Shared.Contracts.Brands;
using GasFinder.Shared.Contracts.Retailers;
using GasFinder.Shared.Contracts.Stock;
using GasFinder.Shared.Contracts.Sync;

namespace GasFinder.IntegrationTests;

[Collection("postgres")]
public class EndToEndTests(PostgresFixture pg)
{
    [Fact]
    public async Task Register_approve_post_stock_then_consumer_sees_it()
    {
        var (_, shellId, totalId) = await TestDataSeeder.SeedAsync(pg.ConnectionString);

        using var factory = new GasFinderApiFactory(pg.ConnectionString);
        var client = factory.CreateClient();

        // 1. Anonymous brand list
        var brands = await client.GetFromJsonAsync<List<BrandDto>>("/api/brands");
        Assert.NotNull(brands);
        Assert.Equal(2, brands!.Count);

        // 2. Register a retailer
        var register = new RegisterRetailerRequest(
            OwnerPhone: "+221770000001",
            Pin: "1234",
            OwnerName: "Aliou",
            ShopName: "Aliou Gas",
            ShopPhone: "+221770000001",
            ShopLatitude: 14.7167,
            ShopLongitude: -17.4677,
            ShopAddress: "Plateau, Dakar");

        var regResp = await client.PostAsJsonAsync("/api/auth/register-retailer", register);
        Assert.Equal(HttpStatusCode.OK, regResp.StatusCode);
        var regAuth = await regResp.Content.ReadFromJsonAsync<AuthResponse>();
        Assert.NotNull(regAuth);
        Assert.Equal("Retailer", regAuth!.Role);
        Assert.Equal("Pending", regAuth.RetailerStatus);

        // 3. Anonymous /api/retailers must NOT see the pending retailer
        var nearbyBefore = await client.GetFromJsonAsync<List<RetailerListItem>>(
            "/api/retailers?lat=14.7167&lon=-17.4677&radiusMeters=10000");
        Assert.NotNull(nearbyBefore);
        Assert.Empty(nearbyBefore!);

        // 4. Login as admin and approve
        var adminLogin = await client.PostAsJsonAsync("/api/auth/login",
            new LoginRequest("+221000000000", "9999"));
        adminLogin.EnsureSuccessStatusCode();
        var adminAuth = (await adminLogin.Content.ReadFromJsonAsync<AuthResponse>())!;
        Assert.Equal("Admin", adminAuth.Role);

        var adminClient = factory.CreateClient();
        adminClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", adminAuth.AccessToken);

        var approve = await adminClient.PatchAsJsonAsync(
            $"/api/admin/retailers/{regAuth.RetailerId}/status",
            new RetailerStatusUpdateRequest("Approved"));
        Assert.Equal(HttpStatusCode.NoContent, approve.StatusCode);

        // 5. Retailer posts a stock update (Shell available, Total out)
        var retailerClient = factory.CreateClient();
        retailerClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", regAuth.AccessToken);

        var now = DateTimeOffset.UtcNow;
        var batch = new StockUpdateBatchRequest(new[]
        {
            new StockUpdateRequest(Guid.NewGuid(), shellId, "Available", 12, now),
            new StockUpdateRequest(Guid.NewGuid(), totalId, "Out", 0, now)
        });
        var post = await retailerClient.PostAsJsonAsync("/api/stock/updates", batch);
        post.EnsureSuccessStatusCode();
        var postResp = (await post.Content.ReadFromJsonAsync<StockUpdateBatchResponse>())!;
        Assert.All(postResp.Results, r => Assert.Equal(StockUpdateOutcomes.Accepted, r.Outcome));

        // 6. Idempotency: posting the same batch again returns "duplicate" for every row
        var dup = await retailerClient.PostAsJsonAsync("/api/stock/updates", batch);
        dup.EnsureSuccessStatusCode();
        var dupResp = (await dup.Content.ReadFromJsonAsync<StockUpdateBatchResponse>())!;
        Assert.All(dupResp.Results, r => Assert.Equal(StockUpdateOutcomes.Duplicate, r.Outcome));

        // 7. Anonymous /api/retailers now sees the retailer with shell available
        var nearbyAfter = await client.GetFromJsonAsync<List<RetailerListItem>>(
            "/api/retailers?lat=14.7167&lon=-17.4677&radiusMeters=10000");
        Assert.NotNull(nearbyAfter);
        var nearby = Assert.Single(nearbyAfter!);
        Assert.Equal("Aliou Gas", nearby.ShopName);
        Assert.Contains(shellId, nearby.AvailableBrandIds);
        Assert.DoesNotContain(totalId, nearby.AvailableBrandIds);

        // 8. Filtering by brand=Total returns 0 (Total is out at this retailer)
        var totalOnly = await client.GetFromJsonAsync<List<RetailerListItem>>(
            $"/api/retailers?lat=14.7167&lon=-17.4677&radiusMeters=10000&brandIds={totalId}");
        Assert.Empty(totalOnly!);

        // 9. Filter by Shell returns the retailer
        var shellOnly = await client.GetFromJsonAsync<List<RetailerListItem>>(
            $"/api/retailers?lat=14.7167&lon=-17.4677&radiusMeters=10000&brandIds={shellId}");
        Assert.Single(shellOnly!);

        // 10. Sync with empty cursor returns the retailer
        var sync1 = await client.GetFromJsonAsync<RetailerSyncResponse>(
            "/api/sync/retailers?lat=14.7167&lon=-17.4677&radiusMeters=10000");
        Assert.NotNull(sync1);
        Assert.Single(sync1!.Changes);
        Assert.Empty(sync1.Deletes);

        // 11. Sync with the returned cursor returns no further changes
        var sync2 = await client.GetFromJsonAsync<RetailerSyncResponse>(
            $"/api/sync/retailers?lat=14.7167&lon=-17.4677&radiusMeters=10000&cursor={Uri.EscapeDataString(sync1.Cursor)}");
        Assert.NotNull(sync2);
        Assert.Empty(sync2!.Changes);

        // 12. Retailer detail returns full stock
        var detail = await client.GetFromJsonAsync<RetailerDetail>($"/api/retailers/{nearby.Id}");
        Assert.NotNull(detail);
        Assert.Equal(2, detail!.Stock.Count);
        Assert.Contains(detail.Stock, s => s.BrandName == "Shell" && s.Status == "Available");
        Assert.Contains(detail.Stock, s => s.BrandName == "Total" && s.Status == "Out");
    }
}
