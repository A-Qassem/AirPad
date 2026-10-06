namespace AirPad.Core.Interfaces
{
    public interface IMouseService
    {
        void Move(int deltaX, int deltaY);
        void LeftClick();
        void RightClick();
        void LeftDown();
        void LeftUp();
        void Scroll(int scrollAmount);
    }
}
