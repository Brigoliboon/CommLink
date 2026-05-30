# CommLink — System Overview

## What Is CommLink?

CommLink is a **Flutter-based Push-to-Talk (PTT) walkie-talkie application** designed for local network voice communication. It enables devices on the same Wi-Fi network to discover each other and communicate in real-time over multicast UDP, similar to a traditional radio walkie-talkie system.

---

## Architecture

```
lib/
├── main.dart                          ── App entry point
├── config/
│   └── network_config.dart            ── Multicast IP, port, audio constants
├── core/
│   ├── audio/
│   │   └── audio_engine.dart          ── Audio recording & playback (flutter_sound)
│   ├── backend/
│   │   ├── peer_discovery.dart        ── UDP multicast peer announce/discovery
│   │   ├── rt_voice_stream.dart       ── PTT voice streaming orchestration
│   │   └── state_controller.dart      ── Central state (PTT, channel, peers)
│   └── network/
│       └── udp_service.dart           ── UDP send/receive audio frames
├── features/
│   └── ptt/
│       ├── ptt_controller.dart        ── Legacy PTT controller (unused)
│       └── ptt_button_widget.dart     ── Legacy PTT button widget (unused)
├── screens/
│   ├── splash_screen.dart             ── Permissions request + splash
│   ├── main_screen.dart               ── Bottom nav container
│   ├── ptt_home_screen.dart           ── Main PTT button + peer list
│   ├── channel_selection_screen.dart  ── Channel grid (8 FRS channels)
│   ├── device_discovery_screen.dart   ── Device scanning UI
│   ├── settings_screen.dart           ── App settings (static, non-functional)
│   └── debug_screen.dart              ── Developer diagnostics
├── ui/screens/                        ── Unused legacy screens
├── utils/
│   └── app_colors.dart                ── Color palette constants
└── widgets/
    ├── app_drawer.dart                ── Side navigation drawer
    ├── waveform_painter.dart          ── PTT press animation
    └── radio_wave_painter.dart        ── Unused radio wave animation
```

---

## How It Works

### 1. Startup Flow

1. **`main.dart`** launches `CommLinkApp` → navigates to `SplashScreen`
2. **`SplashScreen`** requests microphone and location permissions
3. After ~3 seconds, navigates to `MainScreen`

### 2. Peer Discovery (`PeerDiscoveryService`)

Uses **UDP multicast** on `224.0.1.1:30001` to discover peers on the same network:

- **Announcement**: Every 2 seconds, broadcasts `{"type":"peer_announce","name":"Me"}` to the multicast group
- **Listening**: Listens for announcements from other devices; stores them in a `_peers` map keyed by IP
- **Cleanup**: Every 5 seconds, removes peers not seen in 10+ seconds
- **Network Watcher**: Every 4 seconds, checks Wi-Fi connectivity; rebinds sockets if no recent packets
- **Retry Logic**: Socket binding retries up to 3 times with 1-second delays on failure

### 3. Audio Pipeline (`AudioEngine` → `UDPService` → `AudioEngine`)

**Recording (PTT Press):**
1. User holds the PTT button on `PTTHomeScreen`
2. `BackendStateController.setPTTState(true)` → `RTVoiceStream.startPTT()`
3. `AudioEngine.startRecording()` captures PCM16 audio at 16kHz mono via `flutter_sound`
4. Audio frames stream through `_pcmController` → `RTVoiceStream` → `UDPService.sendFrame()`
5. Frames are sent via multicast UDP to all peers

**Playback (Receiving):**
1. `UDPService` receives multicast UDP audio frames
2. Filters out loopback (own device) by comparing sender IP to local IP
3. Passes frames to `AudioEngine.playAudio()`
4. Audio is buffered (up to 10 frames) and flushed every 20ms to the `FlutterSoundPlayer`
5. An "audio receiving" indicator fires via `audioReceivingStream` (500ms timeout after last packet)

### 4. Channel System (`BackendStateController`)

- 8 predefined FRS (Family Radio Service) channels with simulated frequencies
- Channel switching updates `_currentChannel` in `BackendStateController` and broadcasts via `channelStream`
- **Note**: Channels are currently UI-only; there is no channel-based filtering of audio/peers (all traffic goes to the same multicast address)

### 5. State Management (`BackendStateController`)

The central orchestrator that ties everything together:

| Stream | Purpose |
|--------|---------|
| `peerStream` | Emits `List<Peer>` when peers are discovered/removed |
| `pttStream` | Emits PTT state (pressed/released) |
| `channelStream` | Emits current channel number |
| `eventLogStream` | Emits debug event strings |

### 6. Screen Architecture

Each screen in the bottom navigation bar (`MainScreen`) manages its **own** instance of `BackendStateController` and `PeerDiscoveryService`:

- `PTTHomeScreen` → creates its own `BackendStateController`
- `ChannelSelectionScreen` → creates its own `BackendStateController`
- `DeviceDiscoveryScreen` → creates its own `BackendStateController`
- `DebugScreen` → creates its own `BackendStateController`

---

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_sound` | Audio recording and playback |
| `udp` (v5.0.3) | Raw UDP socket communication |
| `multicast_dns` | mDNS support (currently unused) |
| `provider` | State management (currently unused) |
| `permission_handler` | Runtime permissions |
| `wifi_iot` | Wi-Fi connectivity detection |

---

## Current Limitations

1. **No shared state**: Each screen creates its own `BackendStateController` — peers discovered in one screen are not visible in others
2. **Channel is cosmetic**: All audio/peers go to the same multicast group regardless of selected channel
3. **No Provider usage**: The `provider` package is a dependency but is not used anywhere
4. **Hardcoded identity**: All devices announce as `"Me"` — no device-specific naming
5. **Legacy code**: `lib/features/ptt/` and `lib/ui/screens/` contain unused duplicate code
6. **Settings are static**: No settings actually affect app behavior (no persistence, no wiring)
