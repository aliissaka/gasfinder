using Microsoft.AspNetCore.Components.Server.ProtectedBrowserStorage;

namespace GasFinder.Admin.Services;

// In-memory per-circuit token store, with helpers to mirror state into
// ProtectedSessionStorage so a browser refresh re-hydrates instead of
// bouncing the user back to /login. Storage I/O requires JS interop and
// must be invoked from an interactive render lifecycle hook.
public sealed class AdminTokenStore
{
    private const string StorageKey = "gasfinder.admin.auth";

    private record StoredAuth(string Token, Guid UserId, DateTimeOffset ExpiresAt);

    public string? Token { get; private set; }
    public Guid? UserId { get; private set; }
    public DateTimeOffset? ExpiresAt { get; private set; }

    public event Action? Changed;

    public bool IsAuthenticated => !string.IsNullOrEmpty(Token)
        && (ExpiresAt is null || ExpiresAt > DateTimeOffset.UtcNow);

    public void Set(string token, Guid userId, DateTimeOffset expiresAt)
    {
        Token = token;
        UserId = userId;
        ExpiresAt = expiresAt;
        Changed?.Invoke();
    }

    public void Clear()
    {
        Token = null;
        UserId = null;
        ExpiresAt = null;
        Changed?.Invoke();
    }

    public async Task HydrateFromAsync(ProtectedSessionStorage storage)
    {
        if (IsAuthenticated) return;
        try
        {
            var result = await storage.GetAsync<StoredAuth>(StorageKey);
            if (result.Success && result.Value is { } v
                && !string.IsNullOrEmpty(v.Token)
                && v.ExpiresAt > DateTimeOffset.UtcNow)
            {
                Set(v.Token, v.UserId, v.ExpiresAt);
            }
        }
        catch
        {
            // Corrupt or unreadable entry — ignore; user can sign in again.
        }
    }

    public async Task PersistToAsync(ProtectedSessionStorage storage)
    {
        if (Token is null || UserId is null || ExpiresAt is null) return;
        await storage.SetAsync(StorageKey, new StoredAuth(Token, UserId.Value, ExpiresAt.Value));
    }

    public async Task ClearStorageAsync(ProtectedSessionStorage storage)
    {
        try
        {
            await storage.DeleteAsync(StorageKey);
        }
        catch
        {
            // Best-effort; the in-memory clear is what actually matters.
        }
    }
}
