using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GasFinder.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddBottleSizeToStock : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropPrimaryKey(
                name: "PK_stock_items",
                table: "stock_items");

            migrationBuilder.AddColumn<string>(
                name: "BottleSize",
                table: "stock_updates",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "BottleSize",
                table: "stock_items",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddPrimaryKey(
                name: "PK_stock_items",
                table: "stock_items",
                columns: new[] { "RetailerId", "BrandId", "BottleSize" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropPrimaryKey(
                name: "PK_stock_items",
                table: "stock_items");

            migrationBuilder.DropColumn(
                name: "BottleSize",
                table: "stock_updates");

            migrationBuilder.DropColumn(
                name: "BottleSize",
                table: "stock_items");

            migrationBuilder.AddPrimaryKey(
                name: "PK_stock_items",
                table: "stock_items",
                columns: new[] { "RetailerId", "BrandId" });
        }
    }
}
