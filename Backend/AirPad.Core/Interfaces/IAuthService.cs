namespace AirPad.Core.Interfaces
{
    public interface IAuthService
    {
        string GetCurrentPin();
        void GenerateNewPin();
        bool ValidatePin(string ipAddress, string pin);
    }
}
