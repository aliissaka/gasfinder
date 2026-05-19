using GasFinder.Domain.Enums;

namespace GasFinder.Domain.Entities;

public class StockUpdate
{
    public Guid Id { get; set; }
    public Guid RetailerId { get; set; }
    public Retailer Retailer { get; set; } = default!;

    public Guid BrandId { get; set; }
    public Brand Brand { get; set; } = default!;

    public StockStatus Status { get; set; }
    public int? Quantity { get; set; }

    public DateTimeOffset ReportedAt { get; set; }
    public DateTimeOffset ReceivedAt { get; set; }

    public Guid ClientOutboxId { get; set; }
}
