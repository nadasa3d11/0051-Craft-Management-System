using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CraftManagementAPI.Migrations
{
    /// <inheritdoc />
    public partial class UpdateOrderConfirmationCodeRelation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Conform_Code",
                table: "Orders");

            migrationBuilder.CreateTable(
                name: "ConfirmationCodes",
                columns: table => new
                {
                    Code_ID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Order_ID = table.Column<int>(type: "int", nullable: false),
                    Code = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ConfirmationCodes", x => x.Code_ID);
                    table.ForeignKey(
                        name: "FK_ConfirmationCodes_Orders_Order_ID",
                        column: x => x.Order_ID,
                        principalTable: "Orders",
                        principalColumn: "Order_ID",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ConfirmationCodes_Order_ID",
                table: "ConfirmationCodes",
                column: "Order_ID",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ConfirmationCodes");

            migrationBuilder.AddColumn<string>(
                name: "Conform_Code",
                table: "Orders",
                type: "nvarchar(10)",
                maxLength: 10,
                nullable: false,
                defaultValue: "");
        }
    }
}
