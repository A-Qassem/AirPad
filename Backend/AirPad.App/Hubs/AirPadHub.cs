using Microsoft.AspNetCore.SignalR;
using AirPad.Core.Interfaces;

namespace AirPad.App.Hubs
{
    public class AirPadHub : Hub
    {
        private readonly IMouseService _mouseService;

        public AirPadHub(IMouseService mouseService)
        {
            _mouseService = mouseService;
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
