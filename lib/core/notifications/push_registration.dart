import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_we_system/core/network/dio_provider.dart';
import 'package:the_we_system/core/notifications/browser_notification.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';

class PushRegistration extends ConsumerStatefulWidget {
  const PushRegistration({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushRegistration> createState() => _PushRegistrationState();
}

class _PushRegistrationState extends ConsumerState<PushRegistration> {
  StreamSubscription<String>? tokenSubscription;
  StreamSubscription<RemoteMessage>? openedSubscription;
  StreamSubscription<RemoteMessage>? messageSubscription;
  String? registeredUserId;
  bool registering = false;

  bool get supported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  bool get webConfigured =>
      !kIsWeb ||
      (webVapidKey.isNotEmpty &&
          const String.fromEnvironment(
                'FIREBASE_WEB_API_KEY',
                defaultValue: 'AIzaSyDi5zfl_Bt3r-2aDYYnVROuDkecLoVxuho',
              ).isNotEmpty &&
          const String.fromEnvironment(
                'FIREBASE_WEB_APP_ID',
                defaultValue: '1:627473935635:web:c3e2c4f465bed0fd5e3ee6',
              ).isNotEmpty &&
          const String.fromEnvironment(
                'FIREBASE_WEB_PROJECT_ID',
                defaultValue: 'the-we-system',
              ).isNotEmpty &&
          const String.fromEnvironment(
                'FIREBASE_WEB_MESSAGING_SENDER_ID',
                defaultValue: '627473935635',
              ).isNotEmpty);

  @override
  void initState() {
    super.initState();
    if (!supported || !webConfigured) return;
    tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((
      token,
    ) {
      final userId = ref
          .read(approvalDashboardControllerProvider)
          .asData
          ?.value
          .currentUser
          ?.id;
      if (userId != null) _sendToken(token);
    });
    openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _openMessage,
    );
    messageSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundMessage,
    );
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _openMessage(message);
    });
  }

  void _openMessage(RemoteMessage message) {
    final route = message.data['route'];
    if (route == '/leave' || route == '/') appRouter.go(route!);
    ref.read(approvalDashboardControllerProvider.notifier).reloadRemoteState();
  }

  void _showForegroundMessage(RemoteMessage message) {
    if (!kIsWeb) return;
    final notification = message.notification;
    if (notification == null) return;
    showBrowserNotification(
      title: notification.title ?? '우리기술 전자결재',
      body: notification.body ?? '새로운 결재 알림이 있습니다.',
    );
  }

  Future<void> _sendToken(String token) async {
    try {
      await ref
          .read(dioProvider)
          .post<void>(
            '/notifications/devices',
            data: {
              'token': token,
              'platform': kIsWeb
                  ? 'web'
                  : defaultTargetPlatform == TargetPlatform.iOS
                  ? 'ios'
                  : 'android',
            },
          );
    } on DioException {
      // A later login or token refresh retries registration.
    }
  }

  Future<void> _register(String userId) async {
    if (registering) return;
    registering = true;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      final token = await messaging.getToken(
        vapidKey: kIsWeb ? webVapidKey : null,
      );
      if (token == null || !mounted) return;
      await _sendToken(token);
      registeredUserId = userId;
    } catch (_) {
      // The app remains usable if notification services are unavailable.
    } finally {
      registering = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(
      approvalDashboardControllerProvider.select(
        (value) => value.asData?.value.currentUser?.id,
      ),
    );
    if (supported &&
        webConfigured &&
        userId != null &&
        userId != registeredUserId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _register(userId);
      });
    }
    if (userId == null) registeredUserId = null;
    return widget.child;
  }

  @override
  void dispose() {
    tokenSubscription?.cancel();
    openedSubscription?.cancel();
    messageSubscription?.cancel();
    super.dispose();
  }
}

const webVapidKey = String.fromEnvironment(
  'FIREBASE_WEB_VAPID_KEY',
  defaultValue: 'BIZV7S_cMyHwDO_k-QB1UUAfms290qDhAyq1fSYcvxqVXGKkQ_fyFzWr5ZEcmZu52f-w59bkNCi9OIiLC2H0KQY',
);
