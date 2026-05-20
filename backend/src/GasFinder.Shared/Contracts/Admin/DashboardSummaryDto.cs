namespace GasFinder.Shared.Contracts.Admin;

public record DashboardSummaryDto(
    int PendingRetailers,
    int ApprovedRetailers,
    int SuspendedRetailers,
    int TotalBrands,
    int TotalStockItems,
    int OutOfStockItems,
    int LowStockItems,
    int ConsumerCount,
    int RetailerUserCount,
    int AdminCount,
    IReadOnlyList<RecentStatusChangeDto> RecentActivity
);

public record RecentStatusChangeDto(
    Guid RetailerId,
    string RetailerShopName,
    string FromStatus,
    string ToStatus,
    string? ChangedByDisplayName,
    string? Reason,
    DateTimeOffset ChangedAt
);
