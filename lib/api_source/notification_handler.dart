import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage? message) async {
  if (message?.data != null) {
    log("Firebase---background: ${message?.data.toString()}");
  }
}

class LocalNotification {
  static final LocalNotification _singleton = LocalNotification._();
  static final _notificationsPlugin = FlutterLocalNotificationsPlugin();

  factory LocalNotification() => _singleton;

  LocalNotification._();

  Future<void> initFirebaseMessage(BuildContext context) async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Thông báo',
      description: 'Tất cả thông báo',
      importance: Importance.max,
    );
    await FirebaseMessaging.instance.getToken().then((dynamic token) {
      log('token ${token.toString()}');
    });
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iOS = IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const initSettings = InitializationSettings(
      android: android,
      iOS: iOS,
      macOS: MacOSInitializationSettings(),
    );
    _notificationsPlugin.initialize(
      initSettings,
      onSelectNotification: selectNotification,
    );
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage?.data != null) {
      log("FirebaseMessaging init---- ${json.encode(initialMessage!.data)}");
    }

    // Stream listener
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true);
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? message) {
      if (message?.data != null) {
        debugPrint("FirebaseMessaging onMessageOpenedApp---- ${message?.data}");
      }
    });
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message.data);
    });
  }

  static Future<void> _showNotification(Map<String, dynamic> message) async {
    try {
      final pushTitle = message['title'] as String?;
      final pushText = message['body'] as String?;
      final image = message['image'] as String?;
      debugPrint("---onMessage ${json.encode(message)}");

      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'default_channel',
        'event notificaiton',
        channelDescription: 'Thông báo khuyến mãi',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        styleInformation: image.isNullOrEmpty
            ? null
            : BigPictureStyleInformation(
                await getBitmapFromUrl(image!),
                hideExpandedLargeIcon: true,
                htmlFormatContentTitle: true,
                htmlFormatSummaryText: true,
              ),
        largeIcon: image.isNullOrEmpty ? null : await getBitmapFromUrl(image!),
      );
      final platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );
      await _notificationsPlugin.show(
        int.parse(message['id']),
        pushTitle,
        pushText,
        platformChannelSpecifics,
        payload: json.encode(message),
      );
    } catch (e) {
      debugPrint('Lỗi thông báo ${e.toString()}');
    }
  }

  static Future selectNotification(String? payload) async {
    if (payload != null) log('Hello World');
  }

  static Future<AndroidBitmap<Object>> getBitmapFromUrl(String imageUrl) async {
    final bytes = (await NetworkAssetBundle(Uri.parse(imageUrl)).load(imageUrl))
        .buffer
        .asUint8List();

    return ByteArrayAndroidBitmap.fromBase64String(base64.encode(bytes));
  }
}

extension NullableStringIsNullOrEmptyExtension on String? {
  bool get isNullOrEmpty => this?.isEmpty ?? true;
}
