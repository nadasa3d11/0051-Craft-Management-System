using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CraftManagementAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddConformCodeToOrders : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Conform_Code",
                table: "Orders",
                type: "nvarchar(10)",
                maxLength: 10,
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Conform_Code",
                table: "Orders");
        }
    }
}
