using System;
using System.Diagnostics;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using AirPad.Core.Interfaces;

namespace AirPad.Infrastructure.Network
{
    public class UdpDiscoveryService : IDiscoveryService
    {
        public async Task StartListeningAsync(int port, CancellationToken cancellationToken)
        {
            try
            {
                using (var udpClient = new UdpClient(port))
                {
                    // Register cancellation to close the client and unblock ReceiveAsync
                    using (cancellationToken.Register(() => udpClient.Close()))
                    {
                        while (!cancellationToken.IsCancellationRequested)
                        {
                            try
                            {
                                var result = await udpClient.ReceiveAsync();
                                var message = Encoding.UTF8.GetString(result.Buffer);
                                
                                Debug.WriteLine($"Sender Endpoint: {result.RemoteEndPoint}");
                                Debug.WriteLine($"Message: {message}");
                            }
                            catch (ObjectDisposedException)
                            {
                                // Thrown when udpClient.Close() is called by the cancellation token
                                break;
                            }
                            catch (SocketException)
                            {
                                // Thrown in some environments when the socket is closed during receive
                                break;
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"An error occurred in UdpDiscoveryService: {ex.Message}");
            }
        }
    }
}
