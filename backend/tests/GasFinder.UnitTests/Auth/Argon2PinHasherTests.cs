using GasFinder.Infrastructure.Auth;

namespace GasFinder.UnitTests.Auth;

public class Argon2PinHasherTests
{
    private readonly Argon2PinHasher _sut = new();

    [Fact]
    public void Hash_then_Verify_with_same_pin_returns_true()
    {
        var hash = _sut.Hash("1234");
        Assert.True(_sut.Verify("1234", hash));
    }

    [Fact]
    public void Verify_with_wrong_pin_returns_false()
    {
        var hash = _sut.Hash("1234");
        Assert.False(_sut.Verify("9999", hash));
    }

    [Fact]
    public void Hash_produces_different_output_each_time_due_to_salt()
    {
        var h1 = _sut.Hash("1234");
        var h2 = _sut.Hash("1234");
        Assert.NotEqual(h1, h2);
        Assert.True(_sut.Verify("1234", h1));
        Assert.True(_sut.Verify("1234", h2));
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    public void Hash_throws_on_empty_pin(string pin)
    {
        Assert.Throws<ArgumentException>(() => _sut.Hash(pin));
    }

    [Fact]
    public void Verify_returns_false_for_malformed_hash()
    {
        Assert.False(_sut.Verify("1234", "not-a-valid-hash"));
        Assert.False(_sut.Verify("1234", ""));
    }
}
