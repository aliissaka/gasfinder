using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using GasFinder.Shared.Contracts.Admin;
using GasFinder.Shared.Contracts.Auth;
using GasFinder.Shared.Contracts.Brands;

namespace GasFinder.Admin.Services;

public enum LoginOutcome
{
    Success,
    InvalidCredentials,
    RateLimited,
    NetworkError
}

public sealed record LoginResult(LoginOutcome Outcome, AuthResponse? Auth);

public sealed class AdminApi(HttpClient http, AdminTokenStore tokens)
{
    public async Task<LoginResult> LoginAsync(string phone, string pin, CancellationToken ct = default)
    {
        HttpResponseMessage res;
        try
        {
            res = await http.PostAsJsonAsync("api/auth/login", new LoginRequest(phone, pin), ct);
        }
        catch (HttpRequestException)
        {
            return new LoginResult(LoginOutcome.NetworkError, null);
        }

        if (res.StatusCode == HttpStatusCode.TooManyRequests)
            return new LoginResult(LoginOutcome.RateLimited, null);

        if (!res.IsSuccessStatusCode)
            return new LoginResult(LoginOutcome.InvalidCredentials, null);

        var auth = await res.Content.ReadFromJsonAsync<AuthResponse>(cancellationToken: ct);
        return auth is null
            ? new LoginResult(LoginOutcome.InvalidCredentials, null)
            : new LoginResult(LoginOutcome.Success, auth);
    }

    public async Task<IReadOnlyList<PendingRetailerDto>> ListRetailersAsync(string? status, CancellationToken ct = default)
    {
        var url = string.IsNullOrEmpty(status) ? "api/admin/retailers" : $"api/admin/retailers?status={Uri.EscapeDataString(status)}";
        using var req = new HttpRequestMessage(HttpMethod.Get, url);
        AddAuth(req);
        using var res = await http.SendAsync(req, ct);
        res.EnsureSuccessStatusCode();
        var rows = await res.Content.ReadFromJsonAsync<List<PendingRetailerDto>>(cancellationToken: ct);
        return rows ?? new List<PendingRetailerDto>();
    }

    public async Task<bool> SetRetailerStatusAsync(Guid id, string status, string? reason = null, CancellationToken ct = default)
    {
        using var req = new HttpRequestMessage(HttpMethod.Patch, $"api/admin/retailers/{id}/status")
        {
            Content = JsonContent.Create(new RetailerStatusUpdateRequest(status, reason))
        };
        AddAuth(req);
        using var res = await http.SendAsync(req, ct);
        return res.IsSuccessStatusCode;
    }

    public async Task<IReadOnlyList<RetailerStatusChangeDto>> GetRetailerHistoryAsync(Guid id, CancellationToken ct = default)
    {
        using var req = new HttpRequestMessage(HttpMethod.Get, $"api/admin/retailers/{id}/history");
        AddAuth(req);
        using var res = await http.SendAsync(req, ct);
        res.EnsureSuccessStatusCode();
        var rows = await res.Content.ReadFromJsonAsync<List<RetailerStatusChangeDto>>(cancellationToken: ct);
        return rows ?? new List<RetailerStatusChangeDto>();
    }

    public async Task<IReadOnlyList<UserListItemDto>> ListUsersAsync(string? role, string? q, CancellationToken ct = default)
    {
        var qs = new List<string>();
        if (!string.IsNullOrEmpty(role)) qs.Add($"role={Uri.EscapeDataString(role)}");
        if (!string.IsNullOrEmpty(q)) qs.Add($"q={Uri.EscapeDataString(q)}");
        var url = qs.Count == 0 ? "api/admin/users" : "api/admin/users?" + string.Join("&", qs);

        using var req = new HttpRequestMessage(HttpMethod.Get, url);
        AddAuth(req);
        using var res = await http.SendAsync(req, ct);
        res.EnsureSuccessStatusCode();
        var rows = await res.Content.ReadFromJsonAsync<List<UserListItemDto>>(cancellationToken: ct);
        return rows ?? new List<UserListItemDto>();
    }

    public async Task<ApiResult> ResetUserPinAsync(Guid id, string newPin, CancellationToken ct = default)
    {
        using var req = new HttpRequestMessage(HttpMethod.Patch, $"api/admin/users/{id}/pin")
        {
            Content = JsonContent.Create(new ResetUserPinRequest(newPin))
        };
        AddAuth(req);
        using var res = await http.SendAsync(req, ct);
        return await ToApiResult(res, ct);
    }

    public async Task<ApiResult> ChangeUserRoleAsync(Guid id, string role, CancellationToken ct = default)
    {
        using var req = new HttpRequestMessage(HttpMethod.Patch, $"api/admin/users/{id}/role")
        {
            Content = JsonContent.Create(new UpdateUserRoleRequest(role))
        };
        AddAuth(req);
        using var res = await http.SendAsync(req, ct);
        return await ToApiResult(res, ct);
    }

    public async Task<IReadOnlyList<AdminStockItemDto>> ListStockAsync(Guid? brandId, string? status, string? retailerStatus, CancellationToken ct = default)
    {
        var qs = new List<string>();
        if (brandId is not null) qs.Add($"brandId={brandId}");
        if (!string.IsNullOrEmpty(status)) qs.Add($"status={Uri.EscapeDataString(status)}");
        if (!string.IsNullOrEmpty(retailerStatus)) qs.Add($"retailerStatus={Uri.EscapeDataString(retailerStatus)}");
        var url = qs.Count == 0 ? "api/admin/stock" : "api/admin/stock?" + string.Join("&", qs);

        using var req = new HttpRequestMessage(HttpMethod.Get, url);
        AddAuth(req);
        using var res = await http.SendAsync(req, ct);
        res.EnsureSuccessStatusCode();
        var rows = await res.Content.ReadFromJsonAsync<List<AdminStockItemDto>>(cancellationToken: ct);
        return rows ?? new List<AdminStockItemDto>();
    }

    public async Task<IReadOnlyList<AdminStockUpdateDto>> ListRecentStockUpdatesAsync(int take = 50, CancellationToken ct = default)
    {
        using var req = new HttpRequestMessage(HttpMethod.Get, $"api/admin/stock/recent?take={take}");
        AddAuth(req);
        using var res = await http.SendAsync(req, ct);
        res.EnsureSuccessStatusCode();
        var rows = await res.Content.ReadFromJsonAsync<List<AdminStockUpdateDto>>(cancellationToken: ct);
        return rows ?? new List<AdminStockUpdateDto>();
    }

    public async Task<DashboardSummaryDto?> GetDashboardAsync(CancellationToken ct = default)
    {
        using var req = new HttpRequestMessage(HttpMethod.Get, "api/admin/dashboard");
        AddAuth(req);
        using var res = await http.SendAsync(req, ct);
        res.EnsureSuccessStatusCode();
        return await res.Content.ReadFromJsonAsync<DashboardSummaryDto>(cancellationToken: ct);
    }

    public async Task<IReadOnlyList<BrandDto>> ListBrandsAsync(CancellationToken ct = default)
    {
        using var req = new HttpRequestMessage(HttpMethod.Get, "api/admin/brands");
        AddAuth(req);
        using var res = await http.SendAsync(req, ct);
        res.EnsureSuccessStatusCode();
        var rows = await res.Content.ReadFromJsonAsync<List<BrandDto>>(cancellationToken: ct);
        return rows ?? new List<BrandDto>();
    }

    public async Task<ApiResult> CreateBrandAsync(string name, string logoUrl, int displayOrder, CancellationToken ct = default)
    {
        using var req = new HttpRequestMessage(HttpMethod.Post, "api/admin/brands")
        {
            Content = JsonContent.Create(new BrandCreateRequest(name, logoUrl, displayOrder))
        };
        AddAuth(req);
        using var res = await http.SendAsync(req, ct);
        return await ToApiResult(res, ct);
    }

    public async Task<ApiResult> UpdateBrandAsync(Guid id, string name, string logoUrl, int displayOrder, CancellationToken ct = default)
    {
        using var req = new HttpRequestMessage(HttpMethod.Put, $"api/admin/brands/{id}")
        {
            Content = JsonContent.Create(new BrandUpdateRequest(name, logoUrl, displayOrder))
        };
        AddAuth(req);
        using var res = await http.SendAsync(req, ct);
        return await ToApiResult(res, ct);
    }

    public async Task<ApiResult> DeleteBrandAsync(Guid id, CancellationToken ct = default)
    {
        using var req = new HttpRequestMessage(HttpMethod.Delete, $"api/admin/brands/{id}");
        AddAuth(req);
        using var res = await http.SendAsync(req, ct);
        return await ToApiResult(res, ct);
    }

    private static async Task<ApiResult> ToApiResult(HttpResponseMessage res, CancellationToken ct)
    {
        if (res.IsSuccessStatusCode) return new ApiResult(true, null);

        string? message = null;
        try
        {
            var body = await res.Content.ReadFromJsonAsync<Dictionary<string, string>>(cancellationToken: ct);
            if (body is not null && body.TryGetValue("error", out var err)) message = err;
        }
        catch { /* non-JSON body */ }

        message ??= res.StatusCode switch
        {
            HttpStatusCode.Conflict => "Conflict.",
            HttpStatusCode.NotFound => "Not found.",
            HttpStatusCode.BadRequest => "Invalid input.",
            _ => $"Request failed ({(int)res.StatusCode})."
        };
        return new ApiResult(false, message);
    }

    private void AddAuth(HttpRequestMessage req)
    {
        if (!string.IsNullOrEmpty(tokens.Token))
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", tokens.Token);
    }
}

public sealed record ApiResult(bool Success, string? Error);
