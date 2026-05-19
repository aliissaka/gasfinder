using GasFinder.Domain.Enums;
using NetTopologySuite.Geometries;

namespace GasFinder.Domain.Entities;

public class Retailer
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public User User { get; set; } = default!;

    public string ShopName { get; set; } = default!;
    public Point Location { get; set; } = default!;
    public string? Address { get; set; }
    public string Phone { get; set; } = default!;
    public string? PhotoUrl { get; set; }

    public string OpeningHours { get; set; } = "{}";

    public RetailerStatus Status { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    public List<StockItem> StockItems { get; set; } = new();
}
