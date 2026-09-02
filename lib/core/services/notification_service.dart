import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// دالة الخلفية (خارج الكلاس تماماً)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("وصل إشعار والتطبيق مغلق تماماً: ${message.notification?.title}");
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {

    // 1. طلب إذن المستخدم
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✔️ وافق المستخدم على استقبال الإشعارات.');
      } else {
        print('❌ رفض المستخدم إعطاء إذن الإشعارات.');
      }
    } catch (e) {
      print("⚠️ خطأ أثناء طلب الصلاحية: $e");
    }

    // 2. جلب الـ FCM Token وطباعته (مغلف لتخطي خطأ الحساب المجاني)
    try {
      String? token = await _messaging.getToken();
      print("\n=================== FCM TOKEN ===================");
      print(token);
      print("=================================================\n");
    } catch (e) {
      print("\n⚠️ تم تجاهل خطأ الإشعارات (APNs بسبب الحساب المجاني):");
      print("$e\n");
    }

    // 3. إعدادات الأندرويد المحلية
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // 🌟 الإضافة الجديدة: إعدادات الـ iOS 🌟
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 4. تمرير إعدادات النظامين معاً للمكتبة
    await _localNotificationsPlugin.initialize(
      const InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS, // تمت إضافتها هنا
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("تم الضغط على الإشعار: ${response.payload}");
      },
    );

    // 5. تفعيل الاستماع في الخلفية
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 6. الاستماع للإشعارات والتطبيق مفتوح
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotificationsPlugin.show(
          notification.hashCode,
          notification.title ?? '',
          notification.body ?? '',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'royal_event_channel_id',
              'Royal Event Notifications',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            // إعدادات عرض الإشعار للـ iOS
            iOS: DarwinNotificationDetails(),
          ),
        );
      }
    });
  }
}