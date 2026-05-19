using System.Text;
using System.Text.Json;

namespace GasFinder.Shared.Contracts.Sync;

public static class SyncCursor
{
    private const int CurrentVersion = 1;

    public static string Encode(DateTimeOffset since)
    {
        var json = JsonSerializer.Serialize(new CursorPayload(CurrentVersion, since.UtcDateTime.ToString("O")));
        return Convert.ToBase64String(Encoding.UTF8.GetBytes(json));
    }

    public static DateTimeOffset Parse(string? cursor)
    {
        if (string.IsNullOrWhiteSpace(cursor)) return DateTimeOffset.MinValue;

        try
        {
            var bytes = Convert.FromBase64String(cursor);
            var payload = JsonSerializer.Deserialize<CursorPayload>(Encoding.UTF8.GetString(bytes));
            if (payload is null || payload.V != CurrentVersion) return DateTimeOffset.MinValue;
            return DateTimeOffset.Parse(payload.T, null, System.Globalization.DateTimeStyles.RoundtripKind);
        }
        catch
        {
            return DateTimeOffset.MinValue;
        }
    }

    private sealed record CursorPayload(int V, string T);
}
