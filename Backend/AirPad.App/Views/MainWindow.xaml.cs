using System;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media.Animation;
using Microsoft.AspNetCore.SignalR;
using AirPad.Core.Interfaces;
using AirPad.App.Hubs;

namespace AirPad.App
{
    public partial class MainWindow : Window
    {
        private readonly IAuthService _authService;
        private readonly IUiNotifier _uiNotifier;
        private readonly IHubContext<AirPadHub> _hubContext;
        private System.Windows.Forms.NotifyIcon _notifyIcon;
        private Storyboard _pulseStoryboard;

        public MainWindow(IAuthService authService, IUiNotifier uiNotifier, IHubContext<AirPadHub> hubContext)
        {
            InitializeComponent();
            _authService = authService;
            _uiNotifier = uiNotifier;
            _hubContext = hubContext;
            
            Loaded += MainWindow_Loaded;
            Closed += MainWindow_Closed;
            StateChanged += MainWindow_StateChanged;
            
            _uiNotifier.OnClientConnected += UiNotifier_OnClientConnected;
            _uiNotifier.OnClientDisconnected += UiNotifier_OnClientDisconnected;

            // Load the icon for the system tray from the PNG resource
            var uri = new Uri("pack://application:,,,/icon.png");
            var stream = System.Windows.Application.GetResourceStream(uri).Stream;
            var bitmap = new System.Drawing.Bitmap(stream);

            _notifyIcon = new System.Windows.Forms.NotifyIcon
            {
                Icon = System.Drawing.Icon.FromHandle(bitmap.GetHicon()),
                Visible = true,
                Text = "AirPad"
            };
            _notifyIcon.DoubleClick += (s, e) => RestoreWindow();
            
            var menu = new System.Windows.Forms.ContextMenuStrip();
            menu.Items.Add("Open AirPad", null, (s, e) => RestoreWindow());
            menu.Items.Add("Exit", null, (s, e) => System.Windows.Application.Current.Shutdown());
            _notifyIcon.ContextMenuStrip = menu;
        }

        private void RestoreWindow()
        {
            Show();
            WindowState = WindowState.Normal;
            Activate();
        }

        private void MainWindow_Closed(object sender, EventArgs e)
        {
            if (_notifyIcon != null)
            {
                _notifyIcon.Visible = false;
                _notifyIcon.Dispose();
            }
        }

        private void MainWindow_StateChanged(object sender, EventArgs e)
        {
            if (WindowState == WindowState.Minimized)
            {
                Hide();
            }
        }

        private void MainWindow_Loaded(object sender, RoutedEventArgs e)
        {
            PinTextBlock.Text = _authService.GetCurrentPin();
            
            _pulseStoryboard = (Storyboard)FindResource("PulseAnimation");
            _pulseStoryboard.Begin();
        }

        private void UiNotifier_OnClientConnected(string deviceName, string deviceType)
        {
            Dispatcher.Invoke(() =>
            {
                DeviceNameText.Text = deviceName;
                DeviceTypeText.Text = deviceType;
                
                WaitingGrid.Visibility = Visibility.Collapsed;
                _pulseStoryboard.Stop();

                ConnectedGrid.Visibility = Visibility.Visible;
                ConnectedGrid.Opacity = 0;

                var fadeIn = new DoubleAnimation(0, 1, TimeSpan.FromSeconds(0.5));
                ConnectedGrid.BeginAnimation(UIElement.OpacityProperty, fadeIn);
            });
        }

        private void UiNotifier_OnClientDisconnected()
        {
            Dispatcher.Invoke(() =>
            {
                ConnectedGrid.Visibility = Visibility.Collapsed;
                WaitingGrid.Visibility = Visibility.Visible;
                
                WaitingGrid.Opacity = 0;
                var fadeIn = new DoubleAnimation(0, 1, TimeSpan.FromSeconds(0.5));
                WaitingGrid.BeginAnimation(UIElement.OpacityProperty, fadeIn);

                _pulseStoryboard.Begin();
            });
        }

        private async void DisconnectButton_Click(object sender, RoutedEventArgs e)
        {
            // Generate a new PIN when forcefully disconnected so they can't auto-reconnect
            _authService.GenerateNewPin();
            PinTextBlock.Text = _authService.GetCurrentPin();

            // Send force disconnect command to all clients (the connected mobile app)
            await _hubContext.Clients.All.SendAsync("ForceDisconnect");
        }

        private void TitleBar_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
        {
            if (e.ButtonState == MouseButtonState.Pressed)
            {
                DragMove();
            }
        }

        private void CloseButton_Click(object sender, RoutedEventArgs e)
        {
            Hide();
        }
    }
}