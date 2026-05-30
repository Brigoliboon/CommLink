# CommLink — Issues & Diagnosis

## 1. Peer Count Not Working

### Symptom
The "Active Peers" count on `PTTHomeScreen` shows 0 or an incorrect number, even when peers should be discoverable.

### Root Causes

**a) Each screen creates its own `BackendStateController`**
- `PTTHomeScreen`, `ChannelSelectionScreen`, `DeviceDiscoveryScreen`, and `DebugScreen` each instantiate their own `PeerDiscoveryService` and `BackendStateController`
- This means each screen has its own independent UDP sockets, its own peer map, and its own announce stream
- Peers discovered by one screen are completely invisible to others

**b) `PTTHomeScreen` calls `_peerDiscoveryService.start()` manually**
- Line 50: `_peerDiscoveryService.start();` is called in `initState`
- But `BackendStateController._initializeServices()` also calls `discoveryService.start()` in its constructor
- This double-start can cause race conditions with timer creation (multiple announce/cleanup timers running simultaneously)

**c) All devices announce as `"Me"`**
- `PeerDiscoveryService(selfName: 'Me')` — every device uses the same name
- The peer map is keyed by IP, so different devices will appear, but they're indistinguishable
- The condition `json["name"] != selfName` works, but there's no way to identify which peer is which

### Diagnosis
```
PTTHomeScreen creates:    PeerDiscoveryService(selfName: 'Me') → bound to port 30001
ChannelSelectionScreen:   PeerDiscoveryService(selfName: 'Me') → tries to bind port 30001 again
DeviceDiscoveryScreen:    PeerDiscoveryService(selfName: 'Me') → tries to bind port 30001 again
DebugScreen:              PeerDiscoveryService(selfName: 'Me') → tries to bind port 30001 again
```

Multiple bindings to the same multicast port on the same machine can fail silently or cause unpredictable behavior depending on the OS.

### Fix Required
- Create a **singleton** or use `Provider` to share a single `BackendStateController` across all screens
- Remove manual `start()` calls from individual screens
- Use device-specific names (e.g., `Platform.localHostname`)

---

## 2. Channel Switching Issues

### Symptom
Switching channels in `ChannelSelectionScreen` updates the UI but has no real effect on communication.

### Root Causes

**a) Channels are purely cosmetic**
- All channels use the same multicast IP (`224.0.1.1`) and port (`30001`)
- `NetworkConfig` has no channel-specific configuration
- Changing the channel only updates `_currentChannel` in the local `BackendStateController`

**b) Each screen has its own channel state**
- `PTTHomeScreen` creates its own controller with `_currentChannel = 1`
- `ChannelSelectionScreen` creates its own controller — changing the channel there does NOT update `PTTHomeScreen`
- The channel is never synchronized between devices

**c) Displayed "users" count is always 0**
- In `channel_selection_screen.dart`, line 124: `'${channel['users']}'` — the `users` key is never set in the channel map
- It will always display `null` → renders as `null` in the UI

### Diagnosis
```dart
// channel_selection_screen.dart — lines 17-26
final List<Map<String, dynamic>> _channels = [
  {'id': 1, 'freq': '462.5625 MHz'},  // No 'users' key!
  {'id': 2, 'freq': '462.5875 MHz'},
  // ...
];
// Later: channel['users'] → null
```

### Fix Required
- Map channels to different multicast ports or add a channel filter in the discovery/audio pipeline
- Share a single `BackendStateController` across screens
- Add a `users` field to channel maps, populated from peer data
- Broadcast channel changes to peers so they know which channel you're on

---

## 3. Debug Screen Problems

### Symptom
The debug screen has multiple non-functional or broken sections.

### Root Causes

**a) Creates its own `BackendStateController`**
- Same issue as #1 — the debug screen's controller is isolated from all other screens
- It won't see peers discovered by `PTTHomeScreen` or `DeviceDiscoveryScreen`

**b) No audio packet tracking**
- `_audioPacketsReceived` is declared (line 22) but never incremented
- The UDP service has an `audioLogStream` but the debug screen never subscribes to it

**c) Fake peer and loopback test toggles do nothing**
- `_toggleFakePeer()` and `_toggleLoopbackTest()` only log messages — no actual implementation
- No mechanism to inject fake peers or enable loopback

**d) `_backendController.eventLogStream` is never written to**
- `BackendStateController` has `_eventLogController` but never calls `_eventLogController.add()`
- The only event logs come from `DebugScreen` itself (`_addEventLog()` calls)

**e) Audio receiving stream is never monitored**
- `AudioEngine` has `audioReceivingStream` but the debug screen never subscribes to it
- No way to verify if audio is actually being received

**f) Missing audio log subscription**
- The debug screen subscribes to `_peerDiscoveryService.packetLogStream` for discovery packets
- But never subscribes to `_udpService.audioLogStream` for audio packet logs

### Diagnosis
```dart
// Missing subscription — audio logs are never captured:
// _audioLogSub = _udpService.audioLogStream.listen((log) { _addPacketLog(log); });

// _audioPacketsReceived is never used:
int _audioPacketsReceived = 0;  // ← declared, never incremented
```

### Fix Required
- Share `BackendStateController` across screens (Provider/singleton)
- Subscribe to `UDPService.audioLogStream` and `AudioEngine.audioReceivingStream`
- Implement fake peer injection and loopback test functionality
- Wire up `_eventLogController` in `BackendStateController` to emit meaningful events
- Track audio packet counts in the UDP service and expose them

---

## 4. Device Discovery Scan Issues

### Symptom
The "Start Scan" button in `DeviceDiscoveryScreen` runs a fake 3-second animation but doesn't actually trigger any discovery logic beyond what's already running.

### Root Causes

**a) `_startScan()` is purely cosmetic**
```dart
void _startScan() {
  setState(() => _isScanning = true);
  _scanController.repeat();
  Future.delayed(const Duration(seconds: 3), () {
    setState(() => _isScanning = false);
    _scanController.stop();
  });
}
```
- This does NOT call any discovery method — it just animates for 3 seconds
- Peer discovery is already running continuously via `_peerDiscoveryService.start()` in the controller
- The scan button gives the illusion of doing something but doesn't trigger any actual scan

**b) Creates its own `BackendStateController`**
- Same isolation issue — devices discovered here won't appear in `PTTHomeScreen`

**c) No way to manually trigger an immediate announce**
- `PeerDiscoveryService` has no `announceNow()` method — announcements only happen every 2 seconds via timer
- A "scan" should ideally broadcast an immediate announcement and listen for rapid responses

### Diagnosis
```
User presses "Start Scan" → animation plays for 3s → stops
Meanwhile: PeerDiscoveryService is already announcing every 2s and listening continuously
Result: The scan button is a placebo — it does nothing that isn't already happening
```

### Fix Required
- Add an `announceNow()` method to `PeerDiscoveryService` for immediate announcements
- Make the scan button actually trigger rapid announce bursts (e.g., 3 announcements in 1 second)
- Share `BackendStateController` so discovered devices are visible across the app

---

## 5. Additional Issues Found During Analysis

### 5.1 `_audioReceivingStream` Subscribed But Never Assigned

In `PTTHomeScreen`:
```dart
late Stream<bool> _audioReceivingStream;  // declared
// ...
_audioReceivingSub.cancel();  // used in dispose
// But _audioReceivingStream and _audioReceivingSub are NEVER assigned in initState
```
This will cause a `LateInitializationError` when `dispose()` is called.

### 5.2 Debug String in PTT Home

In `ptt_home_screen.dart`, line ~160:
```dart
'My IP:  a0 a0 a0 a0 a0 a0 a0${_localIp ?? ''}',
```
Contains a garbage string `a0 a0 a0 a0 a0 a0 a0` that should be removed.

### 5.3 `AppColors.debugMode` Is Always `false`

In `app_colors.dart`:
```dart
static bool debugMode = false;
```
This is never updated, even when "Debug Mode" is toggled in settings. The settings toggle is also not persisted.

### 5.4 `Provider` Dependency Unused

The `provider` package (`^6.1.2`) is in `pubspec.yaml` but never imported or used anywhere. This is the ideal solution for sharing `BackendStateController`.

### 5.5 Dead Code

- `lib/features/ptt/ptt_controller.dart` — unused, duplicates logic in `RTVoiceStream`
- `lib/features/ptt/ptt_button_widget.dart` — unused
- `lib/ui/screens/` — 5 files (broadcast_page, channel_page, home_screen, settings_page, test_screen) — never imported
- `lib/widgets/radio_wave_painter.dart` — never used

### 5.6 Settings Don't Do Anything

`SettingsScreen` has toggles and dropdowns, but:
- Audio quality selection has no effect (no bitrate change in `AudioEngine`)
- Dark mode toggle doesn't change the theme
- Debug mode doesn't update `AppColors.debugMode`
- Vibration on PTT is not implemented
- Permission statuses are hardcoded to "Granted"
- No `shared_preferences` or persistence layer

### 5.7 No Error Recovery for Audio Engine

If `FlutterSoundRecorder` or `FlutterSoundPlayer` fails to initialize, the app has no fallback or user notification.

---

## Priority Summary

| Priority | Issue | Impact |
|----------|-------|--------|
| **P0** | Shared `BackendStateController` | Peers don't sync between screens; core functionality broken |
| **P0** | Fix `LateInitializationError` in `PTTHomeScreen` | App crashes on dispose |
| **P1** | Channel-to-port mapping | Channel switching is meaningless |
| **P1** | Device scan triggers actual discovery | Scan button is placebo |
| **P1** | Debug screen audio monitoring | Can't diagnose audio issues |
| **P2** | Remove garbage IP string | UI looks unprofessional |
| **P2** | Wire up debug mode toggle | `AppColors.debugMode` never changes |
| **P2** | Settings persistence | Settings reset on restart |
| **P3** | Clean up dead code | Maintenance burden |
| **P3** | Device-specific naming | All peers show as "Me" |
