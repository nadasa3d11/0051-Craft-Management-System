using System.Collections.Concurrent;

namespace CraftManagementAPI.Services
{
    public class TokenStorage
    {
        private readonly ConcurrentDictionary<string, (string userSSN, DateTime expiry)> _refreshTokens = new();

        public void SaveRefreshToken(string token, string userSSN, DateTime expiry)
        {
            _refreshTokens[token] = (userSSN, expiry);
        }

        public (string userSSN, DateTime expiry)? GetRefreshToken(string token)
        {
            _refreshTokens.TryGetValue(token, out var tokenData);
            return tokenData;
        }

        public void RemoveRefreshToken(string token)
        {
            _refreshTokens.TryRemove(token, out _);
        }
    }
}
