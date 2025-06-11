using Microsoft.EntityFrameworkCore;
using CraftManagementAPI.Models;

namespace CraftManagementAPI.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

        // الجداول
        public DbSet<User> Users { get; set; }
        public DbSet<Category> Categories { get; set; }
        public DbSet<Product> Products { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderItem> OrderItems { get; set; }
        public DbSet<ProductImage> ProductImages { get; set; }
        public DbSet<UserRate> UserRates { get; set; }
        public DbSet<ProductRate> ProductRates { get; set; }
        public DbSet<DeleteProduct> DeleteProducts { get; set; }
        public DbSet<Cart>  Carts { get; set; }
        public DbSet<Favourite> Favourites { get; set; }
        public DbSet<Complaint> Complaints { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<AppRating> AppRatings { get; set; }
        public DbSet<ConfirmationCode> ConfirmationCodes { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            

            // علاقات User مع التقييمات
            modelBuilder.Entity<UserRate>()
                .HasKey(ur => new { ur.SSN_Client, ur.SSN_Artisan });

            modelBuilder.Entity<UserRate>()
                .HasOne(ur => ur.Client)
                .WithMany(u => u.ClientRates)
                .HasForeignKey(ur => ur.SSN_Client)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<UserRate>()
                .HasOne(ur => ur.Artisan)
                .WithMany(u => u.ArtisanRates)
                .HasForeignKey(ur => ur.SSN_Artisan)
                .OnDelete(DeleteBehavior.Restrict);

            // علاقات ProductRate
            modelBuilder.Entity<ProductRate>()
                .HasKey(pr => new { pr.SSN_Client, pr.Product_ID });

            modelBuilder.Entity<ProductRate>()
                .HasOne(pr => pr.Client)
                .WithMany(u => u.ProductRates)
                .HasForeignKey(pr => pr.SSN_Client)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<ProductRate>()
                .HasOne(pr => pr.Product)
                .WithMany(p => p.ProductRates)
                .HasForeignKey(pr => pr.Product_ID)
                .OnDelete(DeleteBehavior.Restrict);

            // علاقات OrderItem
            modelBuilder.Entity<OrderItem>()
                .HasKey(oi => new { oi.Product_ID, oi.Order_ID });

            modelBuilder.Entity<OrderItem>()
                .HasOne(oi => oi.Order)
                .WithMany(o => o.OrderItems)
                .HasForeignKey(oi => oi.Order_ID)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<OrderItem>()
                .HasOne(oi => oi.Product)
                .WithMany(p => p.OrderItems)
                .HasForeignKey(oi => oi.Product_ID)
                .OnDelete(DeleteBehavior.Restrict);

            // علاقات ProductImage
            modelBuilder.Entity<ProductImage>()
                .HasKey(pi => new { pi.Product_ID, pi.Images });

            modelBuilder.Entity<ProductImage>()
                .HasOne(pi => pi.Product)
                .WithMany(p => p.ProductImages)
                .HasForeignKey(pi => pi.Product_ID)
                .OnDelete(DeleteBehavior.Cascade);

            // علاقات DeleteProduct
            modelBuilder.Entity<DeleteProduct>()
                .HasKey(dp => new { dp.SSN, dp.Product_ID });

            modelBuilder.Entity<DeleteProduct>()
                .HasOne(dp => dp.User)
                .WithMany(u => u.DeletedProducts)
                .HasForeignKey(dp => dp.SSN)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<DeleteProduct>()
                .HasOne(dp => dp.Product)
                .WithMany(p => p.DeletedProducts)
                .HasForeignKey(dp => dp.Product_ID)
                .OnDelete(DeleteBehavior.Restrict);

            // علاقات Product مع Category
            modelBuilder.Entity<Product>()
                .HasOne(p => p.Category)
                .WithMany(c => c.Products)
                .HasForeignKey(p => p.Cat_ID)
                .OnDelete(DeleteBehavior.SetNull);

            // علاقات Product مع User
            modelBuilder.Entity<Product>()
                .HasOne(p => p.User)
                .WithMany(u => u.Products)
                .HasForeignKey(p => p.User_SSN)
                .OnDelete(DeleteBehavior.Restrict);

            // علاقات Order مع User
            modelBuilder.Entity<Order>()
                .HasOne(o => o.User)
                .WithMany(u => u.Orders)
                .HasForeignKey(o => o.User_SSN)
                .OnDelete(DeleteBehavior.Restrict);
            // علاقة Cart مع User
            modelBuilder.Entity<Cart>()
                .HasOne(c => c.User)
                .WithMany(u => u.Carts) // التعديل هنا
                .HasForeignKey(c => c.User_SSN)
                .OnDelete(DeleteBehavior.Cascade);

            // علاقة Cart مع Product
            modelBuilder.Entity<Cart>()
                .HasOne(c => c.Product)
                .WithMany(p => p.Carts) // التعديل هنا
                .HasForeignKey(c => c.Product_ID)
                .OnDelete(DeleteBehavior.Cascade);
            // علاقات User
            modelBuilder.Entity<User>()
                .HasMany(u => u.Favourites)
                .WithOne(f => f.User)
                .HasForeignKey(f => f.SSN);
              
            modelBuilder.Entity<User>()
                .HasMany(u => u.Carts)
                .WithOne(c => c.User)
                .HasForeignKey(c => c.User_SSN);
               
            modelBuilder.Entity<User>()
                .HasMany(u => u.Complaints)
                .WithOne(c => c.User)
                .HasForeignKey(c => c.SSN);
              
            modelBuilder.Entity<User>()
                .HasMany(u => u.Notifications)
                .WithOne(n => n.User)
                .HasForeignKey(n => n.SSN);
               

            modelBuilder.Entity<User>()
                .HasMany(u => u.AppRatings)
                .WithOne(a => a.User)
                .HasForeignKey(a => a.SSN);
               

            // علاقات Product
            modelBuilder.Entity<Product>()
                .HasMany(p => p.Favourites)
                .WithOne(f => f.Product)
                .HasForeignKey(f => f.Product_ID);

            modelBuilder.Entity<Product>()
                .HasMany(p => p.Carts)
                .WithOne(c => c.Product)
                .HasForeignKey(c => c.Product_ID);

            modelBuilder.Entity<Order>()
                .HasOne(o => o.ConfirmationCode)
                .WithOne(c => c.Order)
                .HasForeignKey<ConfirmationCode>(c => c.Order_ID)
                .OnDelete(DeleteBehavior.Cascade); // لو الأوردر اتلغى، يتم حذف الكود

            base.OnModelCreating(modelBuilder);
        }
    }
}
