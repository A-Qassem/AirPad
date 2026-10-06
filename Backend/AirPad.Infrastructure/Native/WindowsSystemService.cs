using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;
using AirPad.Core.Interfaces;
using NAudio.CoreAudioApi;

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

        private const byte VK_SPACE = 0x20;
        private const byte VK_LWIN = 0x5B;
        private const byte VK_MENU = 0x12; // Alt
        private const byte VK_CONTROL = 0x11; // Ctrl
        private const byte VK_TAB = 0x09; // Tab
        private const byte VK_SNAPSHOT = 0x2C;
        private const byte VK_VOLUME_DOWN = 0xAE;
        private const byte VK_VOLUME_UP = 0xAF;
        private const byte VK_VOLUME_MUTE = 0xAD;
        private const byte VK_MEDIA_NEXT_TRACK = 0xB0;
        private const byte VK_MEDIA_PREV_TRACK = 0xB1;
        private const byte VK_MEDIA_PLAY_PAUSE = 0xB3;
        private const uint KEYEVENTF_KEYUP = 0x0002;

        public void ToggleMic()
        {
            try
            {
                using var enumerator = new MMDeviceEnumerator();
                
                // Toggle ALL active microphones (handles external USB mics)
                var captureDevices = enumerator.EnumerateAudioEndPoints(DataFlow.Capture, DeviceState.Active);
                
                foreach (var device in captureDevices)
                {
                    try
                    {
                        device.AudioEndpointVolume.Mute = !device.AudioEndpointVolume.Mute;
                    }
                    catch
                    {
                        // Some virtual or external devices might not support hardware mute via CoreAudio
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Failed to toggle mic: {ex.Message}");
            }
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

        public void MediaNextTrack()
        {
            keybd_event(VK_MEDIA_NEXT_TRACK, 0, 0, 0);
            keybd_event(VK_MEDIA_NEXT_TRACK, 0, KEYEVENTF_KEYUP, 0);
        }

        public void MediaPrevTrack()
        {
            keybd_event(VK_MEDIA_PREV_TRACK, 0, 0, 0);
            keybd_event(VK_MEDIA_PREV_TRACK, 0, KEYEVENTF_KEYUP, 0);
        }

        public void VolumeUp()
        {
            keybd_event(VK_VOLUME_UP, 0, 0, 0);
            keybd_event(VK_VOLUME_UP, 0, KEYEVENTF_KEYUP, 0);
        }

        public void VolumeDown()
        {
            keybd_event(VK_VOLUME_DOWN, 0, 0, 0);
            keybd_event(VK_VOLUME_DOWN, 0, KEYEVENTF_KEYUP, 0);
        }

        public void VolumeMute()
        {
            keybd_event(VK_VOLUME_MUTE, 0, 0, 0);
            keybd_event(VK_VOLUME_MUTE, 0, KEYEVENTF_KEYUP, 0);
        }

        private Timer _altTabTimer;
        private bool _isAltHeld = false;

        public void AppSwitcher()
        {
            if (!_isAltHeld)
            {
                keybd_event(VK_MENU, 0, 0, 0); // Alt Down
                _isAltHeld = true;
            }
            
            // Tap Tab
            keybd_event(VK_TAB, 0, 0, 0);
            keybd_event(VK_TAB, 0, KEYEVENTF_KEYUP, 0);

            // Reset 2 second timer
            _altTabTimer?.Dispose();
            _altTabTimer = new Timer(ReleaseAltTab, null, 2000, Timeout.Infinite);
        }

        private void ReleaseAltTab(object state)
        {
            if (_isAltHeld)
            {
                keybd_event(VK_MENU, 0, KEYEVENTF_KEYUP, 0); // Alt Up
                _isAltHeld = false;
            }
            _altTabTimer?.Dispose();
        }

        public void LanguageSwap()
        {
            // Win + Space swaps keyboard layout
            keybd_event(VK_LWIN, 0, 0, 0);
            keybd_event(VK_SPACE, 0, 0, 0);
            keybd_event(VK_SPACE, 0, KEYEVENTF_KEYUP, 0);
            keybd_event(VK_LWIN, 0, KEYEVENTF_KEYUP, 0);
        }

        public void BrightnessUp()
        {
            RunPowerShell("(Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods).WmiSetBrightness(1, [math]::Min(100, (Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightness).CurrentBrightness + 10))");
        }

        public void BrightnessDown()
        {
            RunPowerShell("(Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods).WmiSetBrightness(1, [math]::Max(0, (Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightness).CurrentBrightness - 10))");
        }

        private void RunPowerShell(string script)
        {
            try
            {
                Process.Start(new ProcessStartInfo
                {
                    FileName = "powershell",
                    Arguments = $"-NoProfile -Command \"{script}\"",
                    CreateNoWindow = true,
                    UseShellExecute = false
                });
            }
            catch { }
        }
    }
}
