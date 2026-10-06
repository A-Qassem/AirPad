using System;

namespace AirPad.Core.Interfaces
{
    public interface IUiNotifier
    {
        event Action<string, string> OnClientConnected;
        event Action OnClientDisconnected;
        void NotifyClientConnected(string deviceName, string deviceType);
        void NotifyClientDisconnected();
    }
}
