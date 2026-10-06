using System;
using System.Runtime.InteropServices;
using AirPad.Core.Interfaces;

namespace AirPad.Infrastructure.Native
{
    public class WindowsSystemService : ISystemService
    {
        [DllImport("user32.dll", SetLastError = true)]
        private static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

        [DllImport("powrprof.dll", SetLastError = true)]
        private static extern bool SetSuspendState(bool hibernate, bool forceCritical, bool disableWakeEvent);

        [DllImport("user32.dll", SetLastError = true)]
        private static extern bool LockWorkStation();

        [DllImport("user32.dll")]
        private static extern IntPtr GetForegroundWindow();

        [DllImport("user32.dll")]
        private static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, int dwExtraInfo);

        private static readonly IntPtr HWND_BROADCAST = (IntPtr)0xffff;
        private const uint WM_APPCOMMAND = 0x0319;
        private const int APPCOMMAND_MICROPHONE_VOLUME_MUTE = 0x180000;

        private const byte VK_LWIN = 0x5B;
        private const byte VK_SNAPSHOT = 0x2C;
        private const byte VK_VOLUME_UP = 0xAF;
        private const byte VK_MEDIA_PLAY_PAUSE = 0xB3;
        private const uint KEYEVENTF_KEYUP = 0x0002;

        public void ToggleMic()
        {
            IntPtr handle = GetForegroundWindow();
            SendMessage(handle, WM_APPCOMMAND, handle, (IntPtr)APPCOMMAND_MICROPHONE_VOLUME_MUTE);
        }

        public void Sleep()
        {
            SetSuspendState(false, false, false);
        }

        public void LockScreen()
        {
            LockWorkStation();
        }

        public void TakeScreenshot()
        {
            keybd_event(VK_LWIN, 0, 0, 0); // Win Down
            keybd_event(VK_SNAPSHOT, 0, 0, 0); // PrintScreen Down
            keybd_event(VK_SNAPSHOT, 0, KEYEVENTF_KEYUP, 0); // PrintScreen Up
            keybd_event(VK_LWIN, 0, KEYEVENTF_KEYUP, 0); // Win Up
        }

        public void MediaPlayPause()
        {
            keybd_event(VK_MEDIA_PLAY_PAUSE, 0, 0, 0);
            keybd_event(VK_MEDIA_PLAY_PAUSE, 0, KEYEVENTF_KEYUP, 0);
        }

        public void VolumeUp()
        {
            keybd_event(VK_VOLUME_UP, 0, 0, 0);
            keybd_event(VK_VOLUME_UP, 0, KEYEVENTF_KEYUP, 0);
        }
    }
}
