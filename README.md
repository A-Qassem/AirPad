<div align="center">
  <img src="Backend/AirPad.App/icon.png" alt="AirPad Logo" width="120"/>
  <h1>AirPad</h1>
  <p><strong>Turn your Android phone into a wireless PC remote control.</strong></p>
  <p>
    <img alt="Platform" src="https://img.shields.io/badge/Platform-Windows-blue?style=flat-square&logo=windows"/>
    <img alt="Mobile" src="https://img.shields.io/badge/Mobile-Android%20%7C%20iOS-green?style=flat-square&logo=flutter"/>
    <img alt=".NET" src="https://img.shields.io/badge/.NET-10.0-purple?style=flat-square&logo=dotnet"/>
    <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-blue?style=flat-square&logo=flutter"/>
  </p>
</div>

---

## ✨ Overview

**AirPad** is a local-network remote control system. Run the **AirPad Server** on your Windows PC, then connect with the **AirPad mobile app** on your Android or iOS device and get full wireless control — no internet connection required.

With AirPad you can:
- 🖱️ Control your mouse with a precision touchpad
- ⌨️ Type with your phone's keyboard
- 🔊 Adjust system volume with a slider
- 💡 Control monitor brightness
- 📜 Scroll pages with a dedicated scroll strip
- ▶️ Control media playback (play, pause, next, previous)
- 🖥️ Trigger system actions (sleep, lock, screenshot, Alt+Tab, Bluetooth toggle, mute)
- 🔒 Secure pairing with a rotating 4-digit PIN
- 🔄 Auto-reconnect when you reopen the app
- 🎉 Animated splash screen and polished neon UI

---

## 🏗️ Architecture

AirPad is split into two main parts:

```
AirPad/
├── Backend/                    # Windows PC Server (.NET / WPF)
│   ├── AirPad.Core/            # Interfaces & domain models
│   ├── AirPad.Infrastructure/  # OS-level service implementations
│   └── AirPad.App/             # WPF UI + SignalR hub + Startup
│
├── Mobile/                     # Flutter Mobile App
│   └── airpad_mobile/
│       └── lib/
│           ├── core/           # Networking (SignalR + UDP discovery)
│           └── features/
│               ├── splash/     # Video splash screen
│               ├── discovery/  # Server scan & PIN entry
│               └── remote/     # Remote control UI
│
└── Release/                    # Pre-built installers
    ├── Server/                 # AirPad.exe for Windows
    └── Mobile/                 # AirPad.apk for Android
```

### How It Works

```
┌─────────────────────┐           Wi-Fi (LAN)          ┌────────────────────────┐
│                     │  ◄──── UDP Broadcast (5050) ───►│                        │
│  AirPad Server      │                                  │  AirPad Mobile App     │
│  (Windows PC)       │  ◄── SignalR WebSocket (5001) ──│  (Android / iOS)       │
│                     │                                  │                        │
└─────────────────────┘                                  └────────────────────────┘
```

1. **Discovery**: The mobile app broadcasts a UDP packet on port `5050`. The server hears it and replies with its IP address and hostname.
2. **Authentication**: The user enters the 4-digit PIN displayed on the server UI. The PIN is validated server-side on the SignalR handshake.
3. **Control**: All remote commands (mouse, keyboard, volume, etc.) are streamed over a persistent **SignalR WebSocket** connection on port `5001`.
4. **Auto-Reconnect**: On successful connection, the mobile app saves the server IP and PIN locally. Next time you open the app, it auto-connects immediately.

---

## 🛠️ Tech Stack

### Backend (Windows Server)

| Technology | Purpose |
|---|---|
| **.NET 10 / WPF** | Desktop UI application framework |
| **ASP.NET Core** | Hosts the SignalR WebSocket server |
| **SignalR** | Real-time bidirectional communication hub |
| **Windows Forms** | `NotifyIcon` for system tray integration |
| **Windows.Media.Control** | System media session info |
| **AudioEndpointVolume API** | System volume control |
| **InputSimulator / SendInput** | Mouse movement & keyboard injection |

### Mobile App (Flutter)

| Technology | Purpose |
|---|---|
| **Flutter 3 / Dart** | Cross-platform mobile UI framework |
| **GetX** | State management, routing, and dependency injection |
| **signalr_netcore** | SignalR WebSocket client |
| **udp** | UDP broadcast for server auto-discovery |
| **shared_preferences** | Saving connection credentials for auto-reconnect |
| **video_player** | Animated splash screen |
| **flutter_launcher_icons** | App icon generation for Android & iOS |

---

## 🚀 Getting Started

### Prerequisites

- **Server**: Windows 10/11, [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0)
- **Mobile**: [Flutter SDK 3.x](https://flutter.dev/docs/get-started/install), Android/iOS device on the **same Wi-Fi network** as your PC

---

### Running the Server

```powershell
cd Backend
dotnet run --project AirPad.App
```

The AirPad window will appear showing a **4-digit PIN**. The server icon appears in your **system tray** — minimize or close the window and it keeps running in the background.

> To **exit** completely, right-click the tray icon and choose **Exit**.

---

### Running the Mobile App

```bash
cd Mobile/airpad_mobile
flutter pub get
flutter run
```

Or install the pre-built APK from `Release/Mobile/`.

---

### Building for Release

**Server (Windows self-contained EXE):**
```powershell
cd Backend
dotnet publish AirPad.App -c Release -r win-x64 --self-contained true -o ../Release/Server
```

**Mobile (Android APK):**
```bash
cd Mobile/airpad_mobile
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk ../../Release/Mobile/AirPad.apk
```

---

## 📱 App Flow

```
Open App
    │
    ▼
[Splash Screen]  ──── Animated AirPad logo video plays
    │
    ├─── Saved credentials? ──YES──► [Auto-Connect] ──► [Remote View]
    │
    NO
    ▼
[Connection View]
 - Scanning for AirPad Server on the network (UDP)
 - Enter 4-digit PIN shown on the server
 - Connect
    │
    ▼
[Remote View]
 ┌──────────────────────────────────────────────┐
 │  Media Card      [Cover | Song | Artist]     │
 │  Volume Slider   [──────────●───────]        │
 │  Brightness Slider                           │
 │  Scroll Strip    [──────────────────]        │
 │  Touchpad Area   [       ~~~        ]        │
 │  Action Buttons  [Sleep][Lock][📸][Tab]      │
 │                  [BT]             [Mute]     │
 └──────────────────────────────────────────────┘
```

---

## 🔒 Security

- **PIN-based auth**: Every session requires a valid PIN entered on the phone. The PIN is verified by the server on the SignalR handshake.
- **PIN rotation**: When you click **Disconnect** on the server, the PIN changes immediately — the old device cannot auto-reconnect.
- **LAN only**: AirPad operates purely over your local Wi-Fi — no data ever leaves your network.

---

## 📂 Release Folder

Pre-built distributables are placed in the `Release/` folder after building:

| Folder | Contents |
|---|---|
| `Release/Server/` | `AirPad.exe` — standalone Windows server (self-contained, no .NET install needed) |
| `Release/Mobile/` | `AirPad.apk` — Android installer |

---
