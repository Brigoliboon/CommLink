class NetworkConfig {
  static const String MULTICAST_IP_BASE = "224.0.1.";
  static const int PORT = 30001;
  static const int SAMPLE_RATE = 16000;
  static const int CHANNELS = 1;
  static const int FRAME_SIZE_MS = 20;
  static const int DEFAULT_CHANNEL = 1;
  static const int CHANNEL_COUNT = 8;

  /// Each channel maps to its own multicast IP for network-level isolation.
  /// Channel 1 → 224.0.1.1, Channel 2 → 224.0.1.2, ... Channel 8 → 224.0.1.8
  static String getMulticastIp(int channel) => '$MULTICAST_IP_BASE$channel';
}