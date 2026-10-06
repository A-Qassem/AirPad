using System;
using System.Threading;
using System.Windows;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using AirPad.Core.Interfaces;
using AirPad.Infrastructure.Network;

namespace AirPad.App
{
    public partial class App : Application
    {
        private readonly IHost _host;
        private CancellationTokenSource _cancellationTokenSource;

        public App()
        {
            _host = Host.CreateDefaultBuilder()
                .ConfigureServices((context, services) =>
                {
                    services.AddSingleton<IDiscoveryService, UdpDiscoveryService>();
                })
                .Build();
        }

        protected override async void OnStartup(StartupEventArgs e)
        {
            base.OnStartup(e);

            await _host.StartAsync();

            _cancellationTokenSource = new CancellationTokenSource();

            var discoveryService = _host.Services.GetRequiredService<IDiscoveryService>();

            // Fire-and-forget: run discovery service in the background
            _ = discoveryService.StartListeningAsync(5000, _cancellationTokenSource.Token);
        }

        protected override async void OnExit(ExitEventArgs e)
        {
            _cancellationTokenSource?.Cancel();

            if (_host != null)
            {
                await _host.StopAsync(TimeSpan.FromSeconds(5));
                _host.Dispose();
            }

            _cancellationTokenSource?.Dispose();

            base.OnExit(e);
        }
    }
}
