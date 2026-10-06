using System;
using System.Runtime.InteropServices;
using AirPad.Core.Interfaces;

namespace AirPad.Infrastructure.Native
{
    public class WindowsKeyboardService : IKeyboardService
    {
        [DllImport("user32.dll", SetLastError = true)]
        private static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

        [StructLayout(LayoutKind.Sequential)]
        private struct INPUT
        {
            public uint type;
            public InputUnion u;
        }

        [StructLayout(LayoutKind.Explicit)]
        private struct InputUnion
        {
            [FieldOffset(0)]
            public MOUSEINPUT mi;
            [FieldOffset(0)]
            public KEYBDINPUT ki;
            [FieldOffset(0)]
            public HARDWAREINPUT hi;
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

        [StructLayout(LayoutKind.Sequential)]
        private struct KEYBDINPUT
        {
            public ushort wVk;
            public ushort wScan;
            public uint dwFlags;
            public uint time;
            public IntPtr dwExtraInfo;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct HARDWAREINPUT
        {
            public uint uMsg;
            public ushort wParamL;
            public ushort wParamH;
        }

        private const int INPUT_KEYBOARD = 1;
        private const uint KEYEVENTF_KEYUP = 0x0002;
        private const uint KEYEVENTF_UNICODE = 0x0004;

        public void TypeText(string text)
        {
            if (string.IsNullOrEmpty(text))
                return;

            var inputs = new INPUT[text.Length * 2];
            for (int i = 0; i < text.Length; i++)
            {
                inputs[i * 2] = CreateKeyboardInput(0, text[i], KEYEVENTF_UNICODE);
                inputs[i * 2 + 1] = CreateKeyboardInput(0, text[i], KEYEVENTF_UNICODE | KEYEVENTF_KEYUP);
            }
            SendInput((uint)inputs.Length, inputs, Marshal.SizeOf(typeof(INPUT)));
        }

        public void PressKey(ushort virtualKeyCode)
        {
            var inputs = new INPUT[2];
            inputs[0] = CreateKeyboardInput(virtualKeyCode, 0, 0);
            inputs[1] = CreateKeyboardInput(virtualKeyCode, 0, KEYEVENTF_KEYUP);
            SendInput(2, inputs, Marshal.SizeOf(typeof(INPUT)));
        }

        public void SendShortcut(ushort[] virtualKeyCodes)
        {
            if (virtualKeyCodes == null || virtualKeyCodes.Length == 0)
                return;

            var inputs = new INPUT[virtualKeyCodes.Length * 2];
            
            // Press all down in order
            for (int i = 0; i < virtualKeyCodes.Length; i++)
            {
                inputs[i] = CreateKeyboardInput(virtualKeyCodes[i], 0, 0);
            }
            
            // Release all in reverse order
            for (int i = 0; i < virtualKeyCodes.Length; i++)
            {
                inputs[virtualKeyCodes.Length + i] = CreateKeyboardInput(virtualKeyCodes[virtualKeyCodes.Length - 1 - i], 0, KEYEVENTF_KEYUP);
            }

            SendInput((uint)inputs.Length, inputs, Marshal.SizeOf(typeof(INPUT)));
        }

        private INPUT CreateKeyboardInput(ushort virtualKeyCode, ushort scanCode, uint flags)
        {
            return new INPUT
            {
                type = INPUT_KEYBOARD,
                u = new InputUnion
                {
                    ki = new KEYBDINPUT
                    {
                        wVk = virtualKeyCode,
                        wScan = scanCode,
                        dwFlags = flags,
                        time = 0,
                        dwExtraInfo = IntPtr.Zero
                    }
                }
            };
        }
    }
}
