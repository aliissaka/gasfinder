using GasFinder.Domain.Entities;
using GasFinder.Domain.Enums;
using GasFinder.Infrastructure.Auth;
using GasFinder.Infrastructure.Persistence;
using GasFinder.Shared.Contracts.Auth;
using GasFinder.Shared.Contracts.Common;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using NetTopologySuite.Geometries;

namespace GasFinder.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController(
    AppDbContext db,
    IPinHasher hasher,
    IJwtTokenIssuer tokens,
    ILogger<AuthController> log) : ControllerBase
{
    [HttpPost("register-retailer")]
    [EnableRateLimiting("auth")]
    public async Task<IActionResult> RegisterRetailer([FromBody] RegisterRetailerRequest req, CancellationToken ct)
    {
        if (!TryValidate(req, out var problem)) return problem;

        var phone = NormalizePhone(req.OwnerPhone);

        var phoneTaken = await db.Users.AnyAsync(u => u.Phone == phone, ct);
        if (phoneTaken)
            return Conflict(new { code = ProblemCodes.PhoneAlreadyRegistered });

        var now = DateTimeOffset.UtcNow;

        var user = new User
        {
            Id = Guid.NewGuid(),
            Phone = phone,
            PinHash = hasher.Hash(req.Pin),
            Role = UserRole.Retailer,
            DisplayName = req.OwnerName,
            CreatedAt = now,
            UpdatedAt = now
        };

        var retailer = new Retailer
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            ShopName = req.ShopName.Trim(),
            Phone = NormalizePhone(req.ShopPhone),
            Address = req.ShopAddress?.Trim(),
            Location = new Point(req.ShopLongitude, req.ShopLatitude) { SRID = 4326 },
            OpeningHours = "{}",
            Status = RetailerStatus.Pending,
            CreatedAt = now,
            UpdatedAt = now
        };

        db.Users.Add(user);
        db.Retailers.Add(retailer);
        await db.SaveChangesAsync(ct);

        var (token, expires) = tokens.Issue(user, retailer.Id);
        log.LogInformation("Registered retailer {RetailerId} for user {UserId}", retailer.Id, user.Id);

        return Ok(new AuthResponse(token, expires, user.Id, user.Role.ToString(), retailer.Id, retailer.Status.ToString()));
    }

    [HttpPost("login")]
    [EnableRateLimiting("auth")]
    public async Task<IActionResult> Login([FromBody] LoginRequest req, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(req.Phone) || string.IsNullOrWhiteSpace(req.Pin))
            return Unauthorized(new { code = ProblemCodes.InvalidCredentials });

        var phone = NormalizePhone(req.Phone);

        var user = await db.Users.FirstOrDefaultAsync(u => u.Phone == phone, ct);
        if (user is null || !hasher.Verify(req.Pin, user.PinHash))
            return Unauthorized(new { code = ProblemCodes.InvalidCredentials });

        Guid? retailerId = null;
        string? retailerStatus = null;
        if (user.Role == UserRole.Retailer)
        {
            var r = await db.Retailers
                .Where(r => r.UserId == user.Id)
                .Select(r => new { r.Id, r.Status })
                .FirstOrDefaultAsync(ct);
            if (r is not null)
            {
                retailerId = r.Id;
                retailerStatus = r.Status.ToString();
            }
        }

        var (token, expires) = tokens.Issue(user, retailerId);
        return Ok(new AuthResponse(token, expires, user.Id, user.Role.ToString(), retailerId, retailerStatus));
    }

    private static string NormalizePhone(string phone)
        => new string(phone.Where(c => char.IsDigit(c) || c == '+').ToArray()).Trim();

    private bool TryValidate(RegisterRetailerRequest r, out IActionResult problem)
    {
        var errors = new List<string>();

        if (string.IsNullOrWhiteSpace(r.OwnerPhone)) errors.Add("ownerPhone is required");
        if (string.IsNullOrWhiteSpace(r.Pin) || r.Pin.Length is < 4 or > 8 || !r.Pin.All(char.IsDigit))
            errors.Add("pin must be 4-8 digits");
        if (string.IsNullOrWhiteSpace(r.ShopName)) errors.Add("shopName is required");
        if (string.IsNullOrWhiteSpace(r.ShopPhone)) errors.Add("shopPhone is required");
        if (r.ShopLatitude is < -90 or > 90) errors.Add("shopLatitude out of range");
        if (r.ShopLongitude is < -180 or > 180) errors.Add("shopLongitude out of range");

        if (errors.Count == 0)
        {
            problem = null!;
            return true;
        }

        problem = BadRequest(new { code = ProblemCodes.ValidationFailed, errors });
        return false;
    }
}
