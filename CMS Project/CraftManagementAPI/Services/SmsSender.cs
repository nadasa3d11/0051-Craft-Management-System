using System.Net.Http.Headers;
using System.Text;
using System.Text.RegularExpressions;

namespace CraftManagementAPI.Services
{
    public class SmsSender
    {
        private readonly string accountSid = "ACfb43a7b70f7377c0f5ef4b493598d3ca";
        private readonly string authToken = "174d210e3beec82a301624d5ee8ec35d";
        private readonly string fromNumber = "+19704232584"; // رقم Twilio الذي تحصل عليه
        private readonly HttpClient httpClient;

        public SmsSender()
        {
            httpClient = new HttpClient();
            var byteArray = Encoding.ASCII.GetBytes($"{accountSid}:{authToken}");
            httpClient.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue("Basic", Convert.ToBase64String(byteArray));
        }

        public async Task SendSmsAsync(string toPhone, string message)
        {
            // إذا كان الرقم لا يحتوي على كود الدولة، أضف كود الدولة الافتراضي (هنا كود الدولة لمصر "+20")
            if (!toPhone.StartsWith("+"))
            {
                toPhone = "+2" + toPhone;  // تغيير "+20" إلى كود الدولة الصحيح عند الحاجة
            }

            // تنظيف الرقم من أي مسافات أو رموز غير مرغوب فيها
            toPhone = Regex.Replace(toPhone, @"\s+", "");

            var url = $"https://api.twilio.com/2010-04-01/Accounts/{accountSid}/Messages.json";

            var content = new FormUrlEncodedContent(new[]
            {
                new KeyValuePair<string, string>("To", toPhone),
                new KeyValuePair<string, string>("From", fromNumber),
                new KeyValuePair<string, string>("Body", message)
            });

            var response = await httpClient.PostAsync(url, content);
            var responseBody = await response.Content.ReadAsStringAsync();

            Console.WriteLine($"Status Code: {response.StatusCode}");
            Console.WriteLine($"Response Body: {responseBody}");
        }
    }
}
