using System.Net.Http.Headers;
using System.Text;
using CraftManagementAPI.Data;
using CraftManagementAPI.Models;
using Microsoft.EntityFrameworkCore;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace CraftManagementAPI.Services
{
    public class PayPalService
    {
        private readonly IConfiguration _config;
        private readonly HttpClient _client;
        private readonly ApplicationDbContext _context;

        public PayPalService(IConfiguration config, ApplicationDbContext context, IHttpClientFactory clientFactory)
        {
            _config = config;
            _context = context;
            _client = clientFactory.CreateClient();
            _client.BaseAddress = new Uri(_config["PayPal:BaseUrl"] ?? throw new InvalidOperationException("PayPal BaseUrl is not configured."));
        }

        // ✅ جلب Access Token
        public async Task<string> GetAccessTokenAsync()
        {
            var clientId = _config["PayPal:ClientId"];
            var clientSecret = _config["PayPal:ClientSecret"];

            if (string.IsNullOrEmpty(clientId) || string.IsNullOrEmpty(clientSecret))
                throw new InvalidOperationException("PayPal credentials are missing.");

            var auth = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{clientId}:{clientSecret}"));

            _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", auth);

            var content = new StringContent("grant_type=client_credentials", Encoding.UTF8, "application/x-www-form-urlencoded");
            var response = await _client.PostAsync("/v1/oauth2/token", content);

            if (!response.IsSuccessStatusCode)
            {
                var error = await response.Content.ReadAsStringAsync();
                throw new Exception($"Failed to get PayPal access token. Status: {response.StatusCode}, Error: {error}");
            }

            var result = JsonConvert.DeserializeObject<JObject>(await response.Content.ReadAsStringAsync());
            var accessToken = result?["access_token"]?.ToString();

            if (string.IsNullOrEmpty(accessToken))
                throw new Exception("Access token not found in the response.");

            return accessToken;
        }

        // ✅ إنشاء طلب دفع
        public async Task<(string approvalUrl, string paypalOrderId)> CreatePaymentAsync(Order order, string paymentMethod, string currency = "USD")
        {
            var token = await GetAccessTokenAsync();
            _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

            var body = new
            {
                intent = "CAPTURE",
                purchase_units = new[]
                {
                    new
                    {
                        amount = new
                        {
                            currency_code = currency,
                            value = order.Total_Amount.ToString("F2")
                        },
                        description = $"Payment for Order #{order.Order_ID}"
                    }
                },
                application_context = new
                {
                    return_url = $"{_config["AppSettings:BaseUrl"]}/api/payment/confirm-payment?paymentReference={order.Payment_Reference}",
                    cancel_url = $"{_config["AppSettings:BaseUrl"]}/api/payment/cancel-payment?paymentReference={order.Payment_Reference}"
                }
            };

            var content = new StringContent(JsonConvert.SerializeObject(body), Encoding.UTF8, "application/json");
            var response = await _client.PostAsync("/v2/checkout/orders", content);

            if (!response.IsSuccessStatusCode)
            {
                var error = await response.Content.ReadAsStringAsync();
                throw new Exception($"Failed to create PayPal order. Status: {response.StatusCode}, Error: {error}");
            }

            var result = JsonConvert.DeserializeObject<JObject>(await response.Content.ReadAsStringAsync());
            var approvalLink = result?["links"]?.FirstOrDefault(link => link?["rel"]?.ToString() == "approve")?["href"]?.ToString();
            var paypalOrderId = result?["id"]?.ToString();

            if (string.IsNullOrEmpty(approvalLink) || string.IsNullOrEmpty(paypalOrderId))
                throw new Exception("Failed to get PayPal approval link or order ID.");

            order.Payment_Reference = paypalOrderId;
            await _context.SaveChangesAsync();

            return (approvalLink, paypalOrderId);
        }
    }
}
