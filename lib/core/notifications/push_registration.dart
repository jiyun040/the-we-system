import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_we_system/core/network/dio_provider.dart';
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
  String? registeredUserId;
  bool registering = false;

  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (!supported) return;
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
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _openMessage(message);
    });
  }

  void _openMessage(RemoteMessage message) {
    final route = message.data['route'];
    if (route == '/leave' || route == '/') appRouter.go(route!);
    ref.read(approvalDashboardControllerProvider.notifier).reloadRemoteState();
  }

  Future<void> _sendToken(String token) async {
    try {
      await ref
          .read(dioProvider)
          .post<void>(
            '/notifications/devices',
            data: {
              'token': token,
              'platform': defaultTargetPlatform == TargetPlatform.iOS
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
      final token = await messaging.getToken();
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
    if (supported && userId != null && userId != registeredUserId) {
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
    super.dispose();
  }
}
