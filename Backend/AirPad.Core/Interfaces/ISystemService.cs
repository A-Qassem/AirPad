namespace AirPad.Core.Interfaces
{
    public interface ISystemService
    {
        void ToggleMic();
        void Sleep();
        void LockScreen();
        void TakeScreenshot();
        void MediaPlayPause();
        void VolumeUp();
    }
}
