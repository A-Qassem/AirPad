namespace AirPad.Core.Interfaces
{
    public interface IKeyboardService
    {
        void TypeText(string text);
        void PressKey(ushort virtualKeyCode);
        void SendShortcut(ushort[] virtualKeyCodes);
    }
}
