using System;
using AirPad.Core.Interfaces;

namespace AirPad.App.Services
{
    public class UiNotifier : IUiNotifier
    {
        public event Action<string, string> OnClientConnected;
        public event Action OnClientDisconnected;

        public void NotifyClientConnected(string deviceName, string deviceType)
        {
            OnClientConnected?.Invoke(deviceName, deviceType);
        }

        public void NotifyClientDisconnected()
        {
            OnClientDisconnected?.Invoke();
        }
    }
}
