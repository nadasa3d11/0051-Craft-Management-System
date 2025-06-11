using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CraftManagementAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddSenderToNotification : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "SenderSSN",
                table: "Notifications",
                type: "nvarchar(450)",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_SenderSSN",
                table: "Notifications",
                column: "SenderSSN");

            migrationBuilder.AddForeignKey(
                name: "FK_Notifications_Users_SenderSSN",
                table: "Notifications",
                column: "SenderSSN",
                principalTable: "Users",
                principalColumn: "SSN");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Notifications_Users_SenderSSN",
                table: "Notifications");

            migrationBuilder.DropIndex(
                name: "IX_Notifications_SenderSSN",
                table: "Notifications");

            migrationBuilder.DropColumn(
                name: "SenderSSN",
                table: "Notifications");
        }
    }
}
