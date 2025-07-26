import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/order.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Initialize local notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permission for push notifications
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle incoming messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  Future<void> _onNotificationTap(NotificationResponse response) async {
    // Handle notification tap
    // Navigate to appropriate screen based on payload
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Show local notification when app is in foreground
    await showLocalNotification(
      title: message.notification?.title ?? 'New Update',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Handle background message
    // Navigate to appropriate screen based on payload
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'order_updates',
      'Order Updates',
      channelDescription: 'Notifications for order status updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> sendOrderStatusNotification({
    required String orderId,
    required OrderStatus status,
    String? estimatedDeliveryTime,
  }) async {
    String title;
    String body;

    switch (status) {
      case OrderStatus.confirmed:
        title = 'Order Confirmed';
        body = 'Your order #$orderId has been confirmed and is being prepared.';
        break;
      case OrderStatus.preparing:
        title = 'Order Being Prepared';
        body = 'Your order #$orderId is being prepared in the kitchen.';
        break;
      case OrderStatus.ready:
        title = 'Order Ready';
        body = 'Your order #$orderId is ready for pickup.';
        break;
      case OrderStatus.delivering:
        title = 'Order Out for Delivery';
        body = estimatedDeliveryTime != null
            ? 'Your order #$orderId is out for delivery. Estimated arrival: $estimatedDeliveryTime'
            : 'Your order #$orderId is out for delivery.';
        break;
      case OrderStatus.delivered:
        title = 'Order Delivered';
        body = 'Your order #$orderId has been delivered. Enjoy your meal!';
        break;
      case OrderStatus.cancelled:
        title = 'Order Cancelled';
        body = 'Your order #$orderId has been cancelled.';
        break;
      default:
        title = 'Order Update';
        body = 'Your order #$orderId status has been updated.';
    }

    await showLocalNotification(
      title: title,
      body: body,
      payload: orderId,
    );
  }

  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
} 