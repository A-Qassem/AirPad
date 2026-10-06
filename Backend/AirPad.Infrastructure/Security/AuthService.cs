using System;
using System.Collections.Concurrent;
using AirPad.Core.Interfaces;

namespace AirPad.Infrastructure.Security
{
    public class AuthService : IAuthService
    {
        private string _currentPin;
        private readonly ConcurrentDictionary<string, (int Attempts, DateTime LockoutEnd)> _failedAttempts;

        public AuthService()
        {
            _failedAttempts = new ConcurrentDictionary<string, (int, DateTime)>();
            GenerateNewPin();
        }

        public string GetCurrentPin()
        {
            return _currentPin;
        }

        public void GenerateNewPin()
        {
            var random = new Random();
            _currentPin = random.Next(0, 10000).ToString("D4");
        }

        public bool ValidatePin(string ipAddress, string pin)
        {
            if (string.IsNullOrEmpty(ipAddress))
                return false;

            if (_failedAttempts.TryGetValue(ipAddress, out var record))
            {
                if (record.LockoutEnd > DateTime.UtcNow)
                {
                    return false; // Locked out
                }
            }

            if (pin == _currentPin)
            {
                _failedAttempts.TryRemove(ipAddress, out _);
                return true;
            }

            // Failed attempt
            var attempts = record.LockoutEnd <= DateTime.UtcNow ? 1 : record.Attempts + 1;
            var lockoutEnd = attempts >= 3 ? DateTime.UtcNow.AddMinutes(5) : DateTime.MinValue;

            _failedAttempts[ipAddress] = (attempts, lockoutEnd);

            return false;
        }
    }
}
