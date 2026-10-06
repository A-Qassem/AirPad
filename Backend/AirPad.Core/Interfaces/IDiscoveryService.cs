using System.Threading;
using System.Threading.Tasks;

namespace AirPad.Core.Interfaces
{
    public interface IDiscoveryService
    {
        Task StartListeningAsync(int port, CancellationToken cancellationToken);
    }
}
