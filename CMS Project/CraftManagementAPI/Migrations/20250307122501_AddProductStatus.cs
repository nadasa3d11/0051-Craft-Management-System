using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CraftManagementAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddProductStatus : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Shippings");

            migrationBuilder.DropTable(
                name: "Transactions");

            migrationBuilder.DropTable(
                name: "Payments");

            migrationBuilder.DropColumn(
                name: "Message",
                table: "Complaints");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "Complaints");

            migrationBuilder.DropColumn(
                name: "Subject",
                table: "Complaints");

            migrationBuilder.RenameColumn(
                name: "CreatedAt",
                table: "Complaints",
                newName: "ProblemDate");

            migrationBuilder.AlterColumn<int>(
                name: "Payment_Status",
                table: "Orders",
                type: "int",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(20)",
                oldMaxLength: 20);

            migrationBuilder.AlterColumn<int>(
                name: "Payment_Method",
                table: "Orders",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(string),
                oldType: "nvarchar(20)",
                oldMaxLength: 20,
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "Order_Status",
                table: "Orders",
                type: "int",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(20)",
                oldMaxLength: 20);

            migrationBuilder.AddColumn<string>(
                name: "Full_Name",
                table: "Orders",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Payment_Reference",
                table: "Orders",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Phone_Number",
                table: "Orders",
                type: "nvarchar(15)",
                maxLength: 15,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<decimal>(
                name: "Shipping_Cost",
                table: "Orders",
                type: "decimal(18,2)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<int>(
                name: "Shipping_Method",
                table: "Orders",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<decimal>(
                name: "Total_Amount",
                table: "Orders",
                type: "decimal(18,2)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<string>(
                name: "Zip_Code",
                table: "Orders",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Complainer",
                table: "Complaints",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "PhoneNumber",
                table: "Complaints",
                type: "nvarchar(15)",
                maxLength: 15,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Problem",
                table: "Complaints",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "ProblemStatus",
                table: "Complaints",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "Response",
                table: "Complaints",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ResponseDate",
                table: "Complaints",
                type: "datetime2",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Full_Name",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "Payment_Reference",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "Phone_Number",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "Shipping_Cost",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "Shipping_Method",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "Total_Amount",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "Zip_Code",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "Complainer",
                table: "Complaints");

            migrationBuilder.DropColumn(
                name: "PhoneNumber",
                table: "Complaints");

            migrationBuilder.DropColumn(
                name: "Problem",
                table: "Complaints");

            migrationBuilder.DropColumn(
                name: "ProblemStatus",
                table: "Complaints");

            migrationBuilder.DropColumn(
                name: "Response",
                table: "Complaints");

            migrationBuilder.DropColumn(
                name: "ResponseDate",
                table: "Complaints");

            migrationBuilder.RenameColumn(
                name: "ProblemDate",
                table: "Complaints",
                newName: "CreatedAt");

            migrationBuilder.AlterColumn<string>(
                name: "Payment_Status",
                table: "Orders",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<string>(
                name: "Payment_Method",
                table: "Orders",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<string>(
                name: "Order_Status",
                table: "Orders",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AddColumn<string>(
                name: "Message",
                table: "Complaints",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Status",
                table: "Complaints",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Subject",
                table: "Complaints",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "Payments",
                columns: table => new
                {
                    PaymentId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Order_ID = table.Column<int>(type: "int", nullable: false),
                    Amount = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    PaymentDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    PaymentMethod = table.Column<int>(type: "int", nullable: false),
                    PaymentReference = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    PaymentStatus = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Payments", x => x.PaymentId);
                    table.ForeignKey(
                        name: "FK_Payments_Orders_Order_ID",
                        column: x => x.Order_ID,
                        principalTable: "Orders",
                        principalColumn: "Order_ID",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Shippings",
                columns: table => new
                {
                    ShippingId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Order_ID = table.Column<int>(type: "int", nullable: false),
                    City = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    FullName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    PhoneNumber = table.Column<string>(type: "nvarchar(15)", maxLength: 15, nullable: false),
                    ShippingCost = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    ShippingMethod = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Street = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    ZipCode = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Shippings", x => x.ShippingId);
                    table.ForeignKey(
                        name: "FK_Shippings_Orders_Order_ID",
                        column: x => x.Order_ID,
                        principalTable: "Orders",
                        principalColumn: "Order_ID",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Transactions",
                columns: table => new
                {
                    TransactionId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PaymentId = table.Column<int>(type: "int", nullable: false),
                    Amount = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    TransactionDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    TransactionReference = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    TransactionStatus = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    TransactionType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Transactions", x => x.TransactionId);
                    table.ForeignKey(
                        name: "FK_Transactions_Payments_PaymentId",
                        column: x => x.PaymentId,
                        principalTable: "Payments",
                        principalColumn: "PaymentId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Payments_Order_ID",
                table: "Payments",
                column: "Order_ID",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Shippings_Order_ID",
                table: "Shippings",
                column: "Order_ID",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Transactions_PaymentId",
                table: "Transactions",
                column: "PaymentId");
        }
    }
}
