using System;
using System.Threading;
using System.Windows;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using AirPad.Core.Interfaces;
using AirPad.Infrastructure.Network;
using AirPad.App.Hubs;
using AirPad.Infrastructure.Native;
using AirPad.Infrastructure.Security;
using AirPad.App.Services;

namespace AirPad.App
{
    public partial class App : System.Windows.Application
    {
        private readonly IHost _host;
        private CancellationTokenSource _cancellationTokenSource;

        public App()
        {
            _host = Host.CreateDefaultBuilder()
                .ConfigureServices((context, services) =>
                {
                    services.AddSingleton<IDiscoveryService, UdpDiscoveryService>();
                    services.AddSingleton<IMouseService, WindowsMouseService>();
                    services.AddSingleton<IAuthService, AuthService>();
                    services.AddSingleton<IUiNotifier, UiNotifier>();
                    services.AddSingleton<IKeyboardService, WindowsKeyboardService>();
                    services.AddSingleton<ISystemService, WindowsSystemService>();
                    services.AddHostedService<SystemStateSyncService>();
                    // UdpMouseServer removed: mouse movement now uses SignalR send()
                    // over the existing WebSocket — no second port required.
                    services.AddTransient<MainWindow>();
                })
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.ConfigureKestrel(options =>
                    {
                        options.ListenAnyIP(5001);
                    });

                    webBuilder.ConfigureServices(services =>
                    {
                        services.AddSignalR(options =>
                        {
                            // Server sends pings to clients at this interval.
                            // Each ping causes a brief stall in the Flutter Dart isolate
                            // (single-threaded) when processed — keep it rare.
                            options.KeepAliveInterval = TimeSpan.FromSeconds(45);
                            options.ClientTimeoutInterval = TimeSpan.FromSeconds(120);
                        });
                    });

                    webBuilder.Configure(app =>
                    {
                        app.UseRouting();
                        app.UseEndpoints(endpoints =>
                        {
                            endpoints.MapHub<AirPadHub>("/airpadhub");
                        });
                    });
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

            var mainWindow = _host.Services.GetRequiredService<MainWindow>();
            mainWindow.Show();
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
