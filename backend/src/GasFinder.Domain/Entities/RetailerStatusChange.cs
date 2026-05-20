using GasFinder.Domain.Enums;

namespace GasFinder.Domain.Entities;

public class RetailerStatusChange
{
    public Guid Id { get; set; }
    public Guid RetailerId { get; set; }
    public RetailerStatus FromStatus { get; set; }
    public RetailerStatus ToStatus { get; set; }
    public Guid ChangedByUserId { get; set; }
    public string? Reason { get; set; }
    public DateTimeOffset ChangedAt { get; set; }
}
