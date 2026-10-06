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

        public AirPadHub(IMouseService mouseService, IAuthService authService)
        {
            _mouseService = mouseService;
            _authService = authService;
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
    }
}
