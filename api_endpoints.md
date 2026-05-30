Endpoints:
- GET /api/models/device - List all devices
- GET /api/models/device/{device_id} - Search device by device_id
- POST /api/models/device - Create a device (device_id, full_name)
- GET /api/models/channel - List all channels
- POST /api/models/channel - Create a channel (channel_id 1-5, device_id)
- GET /api/models/session - List all sessions
- POST /api/models/session - Log a session (device_id, ip)
- GET /api/health - Health check