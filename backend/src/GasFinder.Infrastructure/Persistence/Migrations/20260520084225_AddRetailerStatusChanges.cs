using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GasFinder.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddRetailerStatusChanges : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "retailer_status_changes",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    RetailerId = table.Column<Guid>(type: "uuid", nullable: false),
                    FromStatus = table.Column<string>(type: "text", nullable: false),
                    ToStatus = table.Column<string>(type: "text", nullable: false),
                    ChangedByUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Reason = table.Column<string>(type: "character varying(1024)", maxLength: 1024, nullable: true),
                    ChangedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_retailer_status_changes", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_retailer_status_changes_RetailerId_ChangedAt",
                table: "retailer_status_changes",
                columns: new[] { "RetailerId", "ChangedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "retailer_status_changes");
        }
    }
}
