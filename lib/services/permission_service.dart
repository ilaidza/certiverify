import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestStoragePermission() async {
    if (await Permission.storage.isDenied) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  static Future<bool> requestAllPermissions() async {
    final cameraGranted = await requestCameraPermission();
    final storageGranted = await requestStoragePermission();
    return cameraGranted && storageGranted;
  }

  static Future<void> checkAndRequestPermissions() async {
    final permissions = [Permission.camera, Permission.storage];

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    statuses.forEach((permission, status) {
      if (status.isPermanentlyDenied) {
        // Open app settings
        openAppSettings();
      }
    });
  }
}
