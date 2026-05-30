import 'dart:convert';
import 'package:http/http.dart' as http;

class DatabaseService {
  static DatabaseService? _instance;
  String _serverUrl = 'http://localhost:3000';
  bool _isConnected = false;

  factory DatabaseService() {
    _instance ??= DatabaseService._internal();
    return _instance!;
  }

  DatabaseService._internal();

  void setServerUrl(String url) {
    _serverUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  String get serverUrl => _serverUrl;
  bool get isConnected => _isConnected;

  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/api/health'),
      ).timeout(const Duration(seconds: 5));
      _isConnected = response.statusCode == 200;
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  Future<bool> isDeviceRegistered(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/api/models/device/$deviceId/'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> registerDeviceFull(String deviceId, String fullName) async {
    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/api/models/device/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_id': deviceId,
          'full_name': fullName,
        }),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> registerDevice({
    required String deviceName,
    required String fingerprint,
    required String ipAddress,
    int channel = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/api/devices'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': deviceName,
          'fingerprint': fingerprint,
          'ip_address': ipAddress,
          'channel': channel,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getDevices({int? channel}) async {
    try {
      var url = '$_serverUrl/api/devices';
      if (channel != null) {
        url += '?channel=$channel';
      }
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateDeviceStatus({
    required String fingerprint,
    required bool isOnline,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_serverUrl/api/devices/$fingerprint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'is_online': isOnline}),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> recordTransmission({
    required String fromFingerprint,
    required String fromName,
    required int channel,
    required int duration,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/api/transmissions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'from_fingerprint': fromFingerprint,
          'from_name': fromName,
          'channel': channel,
          'duration_ms': duration,
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> getTransmissionHistory({
    int? channel,
    int limit = 50,
  }) async {
    try {
      var url = '$_serverUrl/api/transmissions?limit=$limit';
      if (channel != null) {
        url += '&channel=$channel';
      }
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteDevice(String fingerprint) async {
    try {
      final response = await http.delete(
        Uri.parse('$_serverUrl/api/devices/$fingerprint'),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}