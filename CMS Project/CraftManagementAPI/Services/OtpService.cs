using System;
using System.Collections.Concurrent;
using System.Threading.Tasks;

namespace CraftManagementAPI.Services
{
    public class OtpService
    {
        private readonly SmsSender _smsSender;
        private readonly ConcurrentDictionary<string, string> _otpStorage = new();

        public OtpService(SmsSender smsSender)
        {
            _smsSender = smsSender;
        }

        public async Task<bool> SendOtpAsync(string phone)
        {
            try
            {
                var otp = GenerateOtp();
                _otpStorage[phone] = otp;
                await _smsSender.SendSmsAsync(phone, $"Your OTP is: {otp}");
                return true;
            }
            catch
            {
                return false;
            }
        }


        public bool VerifyOtp(string phone, string inputOtp)
        {
            return _otpStorage.TryGetValue(phone, out var correctOtp) && inputOtp == correctOtp;
        }

        private string GenerateOtp()
        {
            return new Random().Next(100000, 999999).ToString();
        }
    }
}
