using Microsoft.AspNetCore.SignalR;
using System.Threading.Tasks;

namespace CraftManagementAPI.Hubs
{
    public class NotificationHub : Hub
    {
        // إرسال إشعار لمستخدم محدد بناءً على SSN
        public async Task SendNotification(string userSSN, string message)
        {
            await Clients.User(userSSN).SendAsync("ReceiveNotification", message);
        }

        // تسجيل المستخدم عند الاتصال بالـ Hub
        public override async Task OnConnectedAsync()
        {
            var userSSN = Context.User?.FindFirst("SSN")?.Value;
            if (!string.IsNullOrEmpty(userSSN))
            {
                await Groups.AddToGroupAsync(Context.ConnectionId, userSSN);
            }
            await base.OnConnectedAsync();
        }

        // إزالة المستخدم عند قطع الاتصال
        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var userSSN = Context.User?.FindFirst("SSN")?.Value;
            if (!string.IsNullOrEmpty(userSSN))
            {
                await Groups.RemoveFromGroupAsync(Context.ConnectionId, userSSN);
            }
            await base.OnDisconnectedAsync(exception);
        }
    }
}
