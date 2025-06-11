using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CraftManagementAPI.Migrations
{
    /// <inheritdoc />
    public partial class UpdateModelWithNewAttribute : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Orders_Users_User_SSN",
                table: "Orders");

            migrationBuilder.DropForeignKey(
                name: "FK_Products_Users_User_SSN",
                table: "Products");

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "UserRates",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "ProductRates",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddForeignKey(
                name: "FK_Orders_Users_User_SSN",
                table: "Orders",
                column: "User_SSN",
                principalTable: "Users",
                principalColumn: "SSN",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Products_Users_User_SSN",
                table: "Products",
                column: "User_SSN",
                principalTable: "Users",
                principalColumn: "SSN",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Orders_Users_User_SSN",
                table: "Orders");

            migrationBuilder.DropForeignKey(
                name: "FK_Products_Users_User_SSN",
                table: "Products");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "UserRates");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "ProductRates");

            migrationBuilder.AddForeignKey(
                name: "FK_Orders_Users_User_SSN",
                table: "Orders",
                column: "User_SSN",
                principalTable: "Users",
                principalColumn: "SSN",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Products_Users_User_SSN",
                table: "Products",
                column: "User_SSN",
                principalTable: "Users",
                principalColumn: "SSN",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
