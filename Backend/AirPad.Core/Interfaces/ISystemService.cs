namespace AirPad.Core.Interfaces
{
    public interface ISystemService
    {
        void ToggleMic();
        void Sleep();
        void LockScreen();
        void TakeScreenshot();
        void MediaPlayPause();
        void MediaNextTrack();
        void MediaPrevTrack();
        void VolumeUp();
        void VolumeDown();
        void VolumeMute();
        void AppSwitcher();
        void LanguageSwap();
        void BrightnessUp();
        void BrightnessDown();
    }
}
