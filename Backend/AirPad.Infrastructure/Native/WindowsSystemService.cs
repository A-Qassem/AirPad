using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
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

        private const byte VK_LWIN = 0x5B;
        private const byte VK_SNAPSHOT = 0x2C;
        private const byte VK_VOLUME_UP = 0xAF;
        private const byte VK_VOLUME_MUTE = 0xAD;
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

        public void VolumeUp()
        {
            keybd_event(VK_VOLUME_UP, 0, 0, 0);
            keybd_event(VK_VOLUME_UP, 0, KEYEVENTF_KEYUP, 0);
        }

        public void VolumeMute()
        {
            keybd_event(VK_VOLUME_MUTE, 0, 0, 0);
            keybd_event(VK_VOLUME_MUTE, 0, KEYEVENTF_KEYUP, 0);
        }
    }
}
