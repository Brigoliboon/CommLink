import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

Future<String> getDeviceName() async {
  try {
    return Platform.localHostname;
  } catch (_) {
    return 'CommLink-${DateTime.now().millisecondsSinceEpoch}';
  }
}

Future<String> getDeviceFingerprint() async {
  final deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id;
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    return iosInfo.identifierForVendor ?? await getDeviceName();
  } else if (Platform.isLinux) {
    final linuxInfo = await deviceInfo.linuxInfo;
    return linuxInfo.machineId ?? await getDeviceName();
  }
  return await getDeviceName();
}
