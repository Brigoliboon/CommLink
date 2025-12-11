c# Peer Discovery Service Fixes

## Tasks
- [x] Add retry logic for socket binding in _bindSockets()
- [x] Improve error handling in _bindSockets()
- [x] Update network watcher to rebind sockets when packet reception stops
- [x] Add better logging for binding success/failure and network events
- [x] Test the changes and verify logs
- [x] Fix PTT audio streaming - integrate UDPService into BackendStateController
- [x] Initialize UDPService in BackendStateController
- [x] Connect PTT state changes to RTVoiceStream start/stop
- [x] Initialize AudioEngine (recorder/player) in BackendStateController
- [x] Add audio buffering to handle network jitter and reduce buffer underruns
- [x] Fix audio loopback - filter out packets from local device
- [x] Fix peer discovery not working - remove manual start() calls from screens, let BackendStateController manage service lifecycle
- [x] Add audio receiving indicator - show visual feedback when receiving audio from peers
