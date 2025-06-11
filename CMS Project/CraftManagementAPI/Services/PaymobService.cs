using System.Net.Http.Headers;
using System.Text;
using CraftManagementAPI.Data;
using CraftManagementAPI.Models;
using Microsoft.EntityFrameworkCore;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace CraftManagementAPI.Services
{
    public class PaymobService
    {
        private readonly IConfiguration _config;
        private readonly HttpClient _client;
        private readonly ApplicationDbContext _context;

        public PaymobService(IConfiguration config, ApplicationDbContext context)
        {
            _config = config;
            _context = context;
            _client = new HttpClient { BaseAddress = new Uri("https://accept.paymob.com/api/") };
        }

        // ✅ الحصول على Payment Token
        public async Task<string> GetAuthTokenAsync()
        {
            var apiKey = _config["Paymob:ApiKey"];
            var response = await _client.PostAsync("auth/tokens", new StringContent(JsonConvert.SerializeObject(new { api_key = apiKey }), Encoding.UTF8, "application/json"));

            if (!response.IsSuccessStatusCode)
                throw new Exception("Failed to get Paymob auth token.");

            var result = JsonConvert.DeserializeObject<JObject>(await response.Content.ReadAsStringAsync());
            return result?["token"]?.ToString() ?? throw new Exception("Auth token not found.");
        }

        // ✅ إنشاء طلب دفع
        public async Task<(string checkoutUrl, string paymentReference)> GeneratePaymentUrl(Order order)
        {
            var token = await GetAuthTokenAsync();

            // ✅ طلب إنشاء الطلب
            var paymentRequest = new
            {
                auth_token = token,
                delivery_needed = "false",
                amount_cents = (order.Total_Amount * 100).ToString("F0"),
                currency = "EGP",
                items = new object[] { }
            };

            var response = await _client.PostAsync("ecommerce/orders", new StringContent(JsonConvert.SerializeObject(paymentRequest), Encoding.UTF8, "application/json"));

            if (!response.IsSuccessStatusCode)
                throw new Exception("Failed to create Paymob order.");

            var result = JsonConvert.DeserializeObject<JObject>(await response.Content.ReadAsStringAsync());
            var orderId = result?["id"]?.ToString() ?? throw new Exception("Order ID not found.");

            // ✅ طلب الحصول على Payment Key
            var paymentKeyRequest = new
            {
                auth_token = token,
                amount_cents = (order.Total_Amount * 100).ToString("F0"),
                expiration = 3600,
                order_id = orderId,
                billing_data = new
                {
                    first_name = order.Full_Name.Split(' ')[0],
                    last_name = order.Full_Name.Split(' ').Length > 1 ? order.Full_Name.Split(' ')[1] : "N/A",
                    email = "client@example.com",
                    phone_number = order.Phone_Number,
                    apartment = "NA",
                    floor = "NA",
                    street = order.Receive_Address,
                    building = "NA",
                    shipping_method = "NA",
                    city = "Cairo",
                    country = "EG",
                    postal_code = order.Zip_Code
                },
                currency = "EGP",
                integration_id = _config["Paymob:IntegrationId"]
            };

            response = await _client.PostAsync("acceptance/payment_keys", new StringContent(JsonConvert.SerializeObject(paymentKeyRequest), Encoding.UTF8, "application/json"));

            if (!response.IsSuccessStatusCode)
                throw new Exception("Failed to get Paymob payment key.");

            result = JsonConvert.DeserializeObject<JObject>(await response.Content.ReadAsStringAsync());
            var paymentKey = result?["token"]?.ToString() ?? throw new Exception("Payment key not found.");

            // ✅ روابط تأكيد وإلغاء الدفع
            var paymentReference = Guid.NewGuid().ToString();
            order.Payment_Reference = paymentReference;
            await _context.SaveChangesAsync();

            var checkoutUrl = $"https://accept.paymob.com/api/acceptance/iframes/{_config["Paymob:IframeId"]}?payment_token={paymentKey}&return_url=https://herfa-system-handmade.runasp.net/api/payment/confirm-payment?paymentReference={paymentReference}&cancel_url=https://herfa-system-handmade.runasp.net/api/payment/cancel-payment?paymentReference={paymentReference}";

            return (checkoutUrl, paymentReference);
        }
    }
}
