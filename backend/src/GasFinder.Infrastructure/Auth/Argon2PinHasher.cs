using System.Security.Cryptography;
using System.Text;
using Konscious.Security.Cryptography;

namespace GasFinder.Infrastructure.Auth;

public sealed class Argon2PinHasher : IPinHasher
{
    private const int SaltLength = 16;
    private const int HashLength = 32;
    private const int DegreeOfParallelism = 2;
    private const int MemorySize = 32 * 1024; // 32 MB
    private const int Iterations = 3;

    public string Hash(string pin)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(pin);

        var salt = RandomNumberGenerator.GetBytes(SaltLength);
        var hash = Derive(pin, salt);

        // format: argon2id$v=19$m=<MB>,t=<iter>,p=<para>$<saltB64>$<hashB64>
        return $"argon2id$v=19$m={MemorySize},t={Iterations},p={DegreeOfParallelism}${Convert.ToBase64String(salt)}${Convert.ToBase64String(hash)}";
    }

    public bool Verify(string pin, string hash)
    {
        if (string.IsNullOrWhiteSpace(pin) || string.IsNullOrWhiteSpace(hash)) return false;

        var parts = hash.Split('$');
        if (parts.Length != 5 || parts[0] != "argon2id") return false;

        var salt = Convert.FromBase64String(parts[3]);
        var expected = Convert.FromBase64String(parts[4]);

        var actual = Derive(pin, salt);
        return CryptographicOperations.FixedTimeEquals(actual, expected);
    }

    private static byte[] Derive(string pin, byte[] salt)
    {
        using var argon2 = new Argon2id(Encoding.UTF8.GetBytes(pin))
        {
            Salt = salt,
            DegreeOfParallelism = DegreeOfParallelism,
            MemorySize = MemorySize,
            Iterations = Iterations
        };
        return argon2.GetBytes(HashLength);
    }
}
