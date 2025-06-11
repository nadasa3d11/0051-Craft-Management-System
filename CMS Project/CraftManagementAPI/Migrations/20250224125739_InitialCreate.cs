using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CraftManagementAPI.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Categories",
                columns: table => new
                {
                    Cat_ID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Cat_Type = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Categories", x => x.Cat_ID);
                });

            migrationBuilder.CreateTable(
                name: "Users",
                columns: table => new
                {
                    SSN = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    Role = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    Phone = table.Column<string>(type: "nvarchar(15)", maxLength: 15, nullable: false),
                    SSN_Image = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Full_Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Birth_Date = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Gender = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: true),
                    Password = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Address = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    Image = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Active = table.Column<bool>(type: "bit", nullable: false),
                    Rating_Average = table.Column<double>(type: "float", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Users", x => x.SSN);
                });

            migrationBuilder.CreateTable(
                name: "Orders",
                columns: table => new
                {
                    Order_ID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Arrived_Date = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Order_Date = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Order_Status = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    Payment_Method = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: true),
                    Payment_Status = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    Order_Price = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    Receive_Address = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    User_SSN = table.Column<string>(type: "nvarchar(450)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Orders", x => x.Order_ID);
                    table.ForeignKey(
                        name: "FK_Orders_Users_User_SSN",
                        column: x => x.User_SSN,
                        principalTable: "Users",
                        principalColumn: "SSN",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Products",
                columns: table => new
                {
                    Product_ID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Add_Date = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Price = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    Rating_Average = table.Column<double>(type: "float", nullable: false),
                    Quantity = table.Column<int>(type: "int", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Cat_ID = table.Column<int>(type: "int", nullable: true),
                    User_SSN = table.Column<string>(type: "nvarchar(450)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Products", x => x.Product_ID);
                    table.ForeignKey(
                        name: "FK_Products_Categories_Cat_ID",
                        column: x => x.Cat_ID,
                        principalTable: "Categories",
                        principalColumn: "Cat_ID",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_Products_Users_User_SSN",
                        column: x => x.User_SSN,
                        principalTable: "Users",
                        principalColumn: "SSN",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "UserRates",
                columns: table => new
                {
                    SSN_Client = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    SSN_Artisan = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    Artisan_Rate = table.Column<int>(type: "int", nullable: false),
                    Comment = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserRates", x => new { x.SSN_Client, x.SSN_Artisan });
                    table.ForeignKey(
                        name: "FK_UserRates_Users_SSN_Artisan",
                        column: x => x.SSN_Artisan,
                        principalTable: "Users",
                        principalColumn: "SSN",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_UserRates_Users_SSN_Client",
                        column: x => x.SSN_Client,
                        principalTable: "Users",
                        principalColumn: "SSN",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "DeleteProducts",
                columns: table => new
                {
                    SSN = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    Product_ID = table.Column<int>(type: "int", nullable: false),
                    Delete_Date = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DeleteProducts", x => new { x.SSN, x.Product_ID });
                    table.ForeignKey(
                        name: "FK_DeleteProducts_Products_Product_ID",
                        column: x => x.Product_ID,
                        principalTable: "Products",
                        principalColumn: "Product_ID",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_DeleteProducts_Users_SSN",
                        column: x => x.SSN,
                        principalTable: "Users",
                        principalColumn: "SSN",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "OrderItems",
                columns: table => new
                {
                    Product_ID = table.Column<int>(type: "int", nullable: false),
                    Order_ID = table.Column<int>(type: "int", nullable: false),
                    Quantity = table.Column<int>(type: "int", nullable: false),
                    Total_Price = table.Column<decimal>(type: "decimal(18,2)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OrderItems", x => new { x.Product_ID, x.Order_ID });
                    table.ForeignKey(
                        name: "FK_OrderItems_Orders_Order_ID",
                        column: x => x.Order_ID,
                        principalTable: "Orders",
                        principalColumn: "Order_ID",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_OrderItems_Products_Product_ID",
                        column: x => x.Product_ID,
                        principalTable: "Products",
                        principalColumn: "Product_ID",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ProductImages",
                columns: table => new
                {
                    Product_ID = table.Column<int>(type: "int", nullable: false),
                    Images = table.Column<string>(type: "nvarchar(450)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProductImages", x => new { x.Product_ID, x.Images });
                    table.ForeignKey(
                        name: "FK_ProductImages_Products_Product_ID",
                        column: x => x.Product_ID,
                        principalTable: "Products",
                        principalColumn: "Product_ID",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ProductRates",
                columns: table => new
                {
                    SSN_Client = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    Product_ID = table.Column<int>(type: "int", nullable: false),
                    Product_Rate = table.Column<int>(type: "int", nullable: false),
                    Comment = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProductRates", x => new { x.SSN_Client, x.Product_ID });
                    table.ForeignKey(
                        name: "FK_ProductRates_Products_Product_ID",
                        column: x => x.Product_ID,
                        principalTable: "Products",
                        principalColumn: "Product_ID",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ProductRates_Users_SSN_Client",
                        column: x => x.SSN_Client,
                        principalTable: "Users",
                        principalColumn: "SSN",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_DeleteProducts_Product_ID",
                table: "DeleteProducts",
                column: "Product_ID");

            migrationBuilder.CreateIndex(
                name: "IX_OrderItems_Order_ID",
                table: "OrderItems",
                column: "Order_ID");

            migrationBuilder.CreateIndex(
                name: "IX_Orders_User_SSN",
                table: "Orders",
                column: "User_SSN");

            migrationBuilder.CreateIndex(
                name: "IX_ProductRates_Product_ID",
                table: "ProductRates",
                column: "Product_ID");

            migrationBuilder.CreateIndex(
                name: "IX_Products_Cat_ID",
                table: "Products",
                column: "Cat_ID");

            migrationBuilder.CreateIndex(
                name: "IX_Products_User_SSN",
                table: "Products",
                column: "User_SSN");

            migrationBuilder.CreateIndex(
                name: "IX_UserRates_SSN_Artisan",
                table: "UserRates",
                column: "SSN_Artisan");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DeleteProducts");

            migrationBuilder.DropTable(
                name: "OrderItems");

            migrationBuilder.DropTable(
                name: "ProductImages");

            migrationBuilder.DropTable(
                name: "ProductRates");

            migrationBuilder.DropTable(
                name: "UserRates");

            migrationBuilder.DropTable(
                name: "Orders");

            migrationBuilder.DropTable(
                name: "Products");

            migrationBuilder.DropTable(
                name: "Categories");

            migrationBuilder.DropTable(
                name: "Users");
        }
    }
}
