using GasFinder.Domain.Enums;

namespace GasFinder.Domain.Entities;

public class StockItem
{
    public Guid RetailerId { get; set; }
    public Retailer Retailer { get; set; } = default!;

    public Guid BrandId { get; set; }
    public Brand Brand { get; set; } = default!;

    public StockStatus Status { get; set; }
    public int? Quantity { get; set; }
    public DateTimeOffset LastUpdatedAt { get; set; }
}
