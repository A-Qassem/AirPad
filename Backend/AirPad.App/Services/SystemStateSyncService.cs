using System;
using System.Diagnostics;
using System.Management;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.Hosting;
using NAudio.CoreAudioApi;
using Windows.Media.Control;
using AirPad.App.Hubs;

namespace AirPad.App.Services
{
    public class SystemStateSyncService : BackgroundService
    {
        private readonly IHubContext<AirPadHub> _hubContext;
        private MMDevice _defaultDevice;
        private GlobalSystemMediaTransportControlsSessionManager _sessionManager;

        public SystemStateSyncService(IHubContext<AirPadHub> hubContext)
        {
            _hubContext = hubContext;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            try
            {
                var enumerator = new MMDeviceEnumerator();
                _defaultDevice = enumerator.GetDefaultAudioEndpoint(DataFlow.Render, Role.Multimedia);
                _defaultDevice.AudioEndpointVolume.OnVolumeNotification += AudioEndpointVolume_OnVolumeNotification;
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Failed to init audio enumerator: {ex.Message}");
            }

            try
            {
                _sessionManager = await GlobalSystemMediaTransportControlsSessionManager.RequestAsync();
                _sessionManager.CurrentSessionChanged += SessionManager_CurrentSessionChanged;
                if (_sessionManager.GetCurrentSession() != null)
                {
                    AttachSession(_sessionManager.GetCurrentSession());
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Failed to init media session manager: {ex.Message}");
            }

            // Polling loop for brightness (and as a fallback for others)
            while (!stoppingToken.IsCancellationRequested)
            {
                await BroadcastStateAsync();
                await Task.Delay(2000, stoppingToken);
            }
        }

        private void SessionManager_CurrentSessionChanged(GlobalSystemMediaTransportControlsSessionManager sender, CurrentSessionChangedEventArgs args)
        {
            var session = sender.GetCurrentSession();
            if (session != null)
            {
                AttachSession(session);
            }
            _ = BroadcastStateAsync();
        }

        private void AttachSession(GlobalSystemMediaTransportControlsSession session)
        {
            session.MediaPropertiesChanged -= Session_MediaPropertiesChanged;
            session.PlaybackInfoChanged -= Session_PlaybackInfoChanged;
            
            session.MediaPropertiesChanged += Session_MediaPropertiesChanged;
            session.PlaybackInfoChanged += Session_PlaybackInfoChanged;
        }

        private void Session_PlaybackInfoChanged(GlobalSystemMediaTransportControlsSession sender, PlaybackInfoChangedEventArgs args)
        {
            _ = BroadcastStateAsync();
        }

        private void Session_MediaPropertiesChanged(GlobalSystemMediaTransportControlsSession sender, MediaPropertiesChangedEventArgs args)
        {
            _ = BroadcastStateAsync();
        }

        private void AudioEndpointVolume_OnVolumeNotification(AudioVolumeNotificationData data)
        {
            _ = BroadcastStateAsync();
        }

        private int GetBrightness()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher("root\\WMI", "SELECT CurrentBrightness FROM WmiMonitorBrightness");
                using var instances = searcher.Get();
                foreach (var instance in instances)
                {
                    return Convert.ToInt32(instance["CurrentBrightness"]);
                }
            }
            catch { }
            return 50;
        }

        private async Task BroadcastStateAsync()
        {
            int volume = 50;
            if (_defaultDevice != null)
            {
                try
                {
                    volume = (int)(_defaultDevice.AudioEndpointVolume.MasterVolumeLevelScalar * 100);
                }
                catch { }
            }

            int brightness = GetBrightness();

            string title = "Unknown Title";
            string artist = "Unknown Artist";
            bool isPlaying = false;

            if (_sessionManager != null)
            {
                var session = _sessionManager.GetCurrentSession();
                if (session != null)
                {
                    try
                    {
                        var mediaProperties = await session.TryGetMediaPropertiesAsync();
                        if (mediaProperties != null)
                        {
                            title = string.IsNullOrEmpty(mediaProperties.Title) ? "Unknown Title" : mediaProperties.Title;
                            artist = string.IsNullOrEmpty(mediaProperties.Artist) ? "Unknown Artist" : mediaProperties.Artist;
                        }
                        
                        var playbackInfo = session.GetPlaybackInfo();
                        if (playbackInfo != null)
                        {
                            isPlaying = playbackInfo.PlaybackStatus == GlobalSystemMediaTransportControlsSessionPlaybackStatus.Playing;
                        }
                    }
                    catch { }
                }
            }

            try 
            {
                await _hubContext.Clients.All.SendAsync("UpdateSystemState", new
                {
                    volume = volume,
                    brightness = brightness,
                    mediaTitle = title,
                    mediaArtist = artist,
                    isPlaying = isPlaying
                });
            }
            catch { }
        }
    }
}
