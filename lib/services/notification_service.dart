// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class NotificationService {
//   static final FlutterLocalNotificationsPlugin _notifications =
//       FlutterLocalNotificationsPlugin();

//   static Future<void> init() async {
//     // Initialize Android settings
//     const androidSettings = AndroidInitializationSettings(
//       '@mipmap/ic_launcher',
//     );

//     // Initialize iOS settings
//     const iosSettings = DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );

//     const initializationSettings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );

//     await _notifications.initialize(initializationSettings);
//   }

//   /// Show a simple notification
//   static Future<void> showNotification({
//     required int id,
//     required String title,
//     required String body,
//     String? payload,
//   }) async {
//     const androidDetails = AndroidNotificationDetails(
//       'credchain_channel',
//       'CredChain Notifications',
//       channelDescription: 'Notifications for certificate verification',
//       importance: Importance.high,
//       priority: Priority.high,
//       icon: '@mipmap/ic_launcher',
//     );

//     const iosDetails = DarwinNotificationDetails();

//     const notificationDetails = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );

//     await _notifications.show(
//       id,
//       title,
//       body,
//       notificationDetails,
//       payload: payload,
//     );
//   }

//   /// Show a notification with verification result
//   static Future<void> showVerificationResult({
//     required bool isValid,
//     required String studentName,
//     required String degree,
//   }) async {
//     final id = DateTime.now().millisecondsSinceEpoch % 100000;

//     if (isValid) {
//       await showNotification(
//         id: id,
//         title: '✅ Verification Successful',
//         body: '$studentName • $degree',
//         payload: 'verification_success',
//       );
//     } else {
//       await showNotification(
//         id: id,
//         title: '❌ Verification Failed',
//         body: 'Invalid certificate detected',
//         payload: 'verification_failed',
//       );
//     }
//   }

//   /// Show certificate issuance notification
//   static Future<void> showCertificateIssued({
//     required String studentName,
//     required String degree,
//   }) async {
//     final id = DateTime.now().millisecondsSinceEpoch % 100000;

//     await showNotification(
//       id: id,
//       title: '📜 Certificate Issued',
//       body: '$studentName • $degree',
//       payload: 'certificate_issued',
//     );
//   }

//   /// Show sync completion notification
//   static Future<void> showSyncComplete(int syncedCount) async {
//     final id = DateTime.now().millisecondsSinceEpoch % 100000;

//     await showNotification(
//       id: id,
//       title: '🔄 Offline Sync Complete',
//       body: '$syncedCount certificates synchronized',
//       payload: 'sync_complete',
//     );
//   }

//   /// Cancel a specific notification
//   static Future<void> cancelNotification(int id) async {
//     await _notifications.cancel(id);
//   }

//   /// Cancel all notifications
//   static Future<void> cancelAllNotifications() async {
//     await _notifications.cancelAll();
//   }

//   /// Check if notifications are enabled
//   static Future<bool> areNotificationsEnabled() async {
//     final settings = await _notifications.getNotificationAppLaunchDetails();
//     return settings?.didNotificationLaunchApp ?? false;
//   }
// }
