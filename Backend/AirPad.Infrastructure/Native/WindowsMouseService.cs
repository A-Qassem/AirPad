using System;
using System.Runtime.InteropServices;
using AirPad.Core.Interfaces;

namespace AirPad.Infrastructure.Native
{
    public class WindowsMouseService : IMouseService
    {
        [DllImport("user32.dll", SetLastError = true)]
        private static extern uint SendInput(uint nInputs, ref INPUT pInputs, int cbSize);

        [StructLayout(LayoutKind.Sequential)]
        private struct INPUT
        {
            public uint type;
            public MOUSEINPUT mi;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct MOUSEINPUT
        {
            public int dx;
            public int dy;
            public uint mouseData;
            public uint dwFlags;
            public uint time;
            public IntPtr dwExtraInfo;
        }

        private const int INPUT_MOUSE = 0;
        private const uint MOUSEEVENTF_MOVE = 0x0001;
        private const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
        private const uint MOUSEEVENTF_LEFTUP = 0x0004;
        private const uint MOUSEEVENTF_RIGHTDOWN = 0x0008;
        private const uint MOUSEEVENTF_RIGHTUP = 0x0010;
        private const uint MOUSEEVENTF_WHEEL = 0x0800;

        public void Move(int deltaX, int deltaY)
        {
            var input = CreateInput();
            input.mi.dx = deltaX;
            input.mi.dy = deltaY;
            input.mi.dwFlags = MOUSEEVENTF_MOVE;
            SendInput(1, ref input, Marshal.SizeOf(typeof(INPUT)));
        }

        public void LeftClick()
        {
            LeftDown();
            LeftUp();
        }

        public void RightClick()
        {
            var inputDown = CreateInput();
            inputDown.mi.dwFlags = MOUSEEVENTF_RIGHTDOWN;
            SendInput(1, ref inputDown, Marshal.SizeOf(typeof(INPUT)));

            var inputUp = CreateInput();
            inputUp.mi.dwFlags = MOUSEEVENTF_RIGHTUP;
            SendInput(1, ref inputUp, Marshal.SizeOf(typeof(INPUT)));
        }

        public void LeftDown()
        {
            var input = CreateInput();
            input.mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
            SendInput(1, ref input, Marshal.SizeOf(typeof(INPUT)));
        }

        public void LeftUp()
        {
            var input = CreateInput();
            input.mi.dwFlags = MOUSEEVENTF_LEFTUP;
            SendInput(1, ref input, Marshal.SizeOf(typeof(INPUT)));
        }

        public void Scroll(int scrollAmount)
        {
            var input = CreateInput();
            input.mi.dwFlags = MOUSEEVENTF_WHEEL;
            input.mi.mouseData = (uint)scrollAmount;
            SendInput(1, ref input, Marshal.SizeOf(typeof(INPUT)));
        }

        private INPUT CreateInput()
        {
            return new INPUT { type = INPUT_MOUSE };
        }
    }
}
