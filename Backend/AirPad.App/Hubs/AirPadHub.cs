using System;
using System.Diagnostics;
using System.Threading.Tasks;
using Microsoft.AspNetCore.SignalR;
using AirPad.Core.Interfaces;

namespace AirPad.App.Hubs
{
    public class AirPadHub : Hub
    {
        private readonly IMouseService _mouseService;
        private readonly IAuthService _authService;
        private readonly IKeyboardService _keyboardService;
        private readonly ISystemService _systemService;

        public AirPadHub(IMouseService mouseService, IAuthService authService, IKeyboardService keyboardService, ISystemService systemService)
        {
            _mouseService = mouseService;
            _authService = authService;
            _keyboardService = keyboardService;
            _systemService = systemService;
        }

        public override Task OnConnectedAsync()
        {
            var httpContext = Context.GetHttpContext();
            var ipAddress = httpContext?.Connection?.RemoteIpAddress?.ToString() ?? "unknown";
            var pin = httpContext?.Request.Query["pin"].ToString();

            if (!_authService.ValidatePin(ipAddress, pin))
            {
                Debug.WriteLine($"Failed connection attempt from {ipAddress}. Invalid PIN or locked out.");
                Context.Abort();
                throw new HubException("Unauthorized: Invalid PIN or IP locked out.");
            }

            Debug.WriteLine($"Client connected successfully from {ipAddress}.");
            return base.OnConnectedAsync();
        }

        public void MoveMouse(int deltaX, int deltaY)
        {
            _mouseService.Move(deltaX, deltaY);
        }

        public void LeftClick()
        {
            _mouseService.LeftClick();
        }

        public void RightClick()
        {
            _mouseService.RightClick();
        }

        public void LeftDown()
        {
            _mouseService.LeftDown();
        }

        public void LeftUp()
        {
            _mouseService.LeftUp();
        }

        public void Scroll(int scrollAmount)
        {
            _mouseService.Scroll(scrollAmount);
        }

        public void TypeText(string text)
        {
            _keyboardService.TypeText(text);
        }

        public void PressKey(ushort keyCode)
        {
            _keyboardService.PressKey(keyCode);
        }

        public void SendShortcut(ushort[] keyCodes)
        {
            _keyboardService.SendShortcut(keyCodes);
        }

        public void ToggleMic()
        {
            _systemService.ToggleMic();
        }

        public void Sleep()
        {
            _systemService.Sleep();
        }

        public void LockScreen()
        {
            _systemService.LockScreen();
        }

        public void TakeScreenshot()
        {
            _systemService.TakeScreenshot();
        }

        public void MediaPlayPause()
        {
            _systemService.MediaPlayPause();
        }

        public void MediaNextTrack()
        {
            _systemService.MediaNextTrack();
        }

        public void MediaPrevTrack()
        {
            _systemService.MediaPrevTrack();
        }

        public void VolumeUp()
        {
            _systemService.VolumeUp();
        }

        public void VolumeDown()
        {
            _systemService.VolumeDown();
        }

        public void VolumeMute()
        {
            _systemService.VolumeMute();
        }

        public void AppSwitcher()
        {
            _systemService.AppSwitcher();
        }

        public void LanguageSwap()
        {
            _systemService.LanguageSwap();
        }

        public void BrightnessUp()
        {
            _systemService.BrightnessUp();
        }

        public void BrightnessDown()
        {
            _systemService.BrightnessDown();
        }
    }
}
