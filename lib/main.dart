import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:the_we_system/common/components/the_we_snack_bar.dart';
import 'package:the_we_system/common/components/rejected_approval_alert.dart';
import 'package:the_we_system/common/theme/the_we_theme.dart';
import 'package:the_we_system/core/platform/app_zoom_wheel_bridge.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/core/notifications/push_registration.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR');
  if (kIsWeb) {
    const apiKey = String.fromEnvironment(
      'FIREBASE_WEB_API_KEY',
      defaultValue: 'AIzaSyDi5zfl_Bt3r-2aDYYnVROuDkecLoVxuho',
    );
    const appId = String.fromEnvironment(
      'FIREBASE_WEB_APP_ID',
      defaultValue: '1:627473935635:web:c3e2c4f465bed0fd5e3ee6',
    );
    const messagingSenderId = String.fromEnvironment(
      'FIREBASE_WEB_MESSAGING_SENDER_ID',
      defaultValue: '627473935635',
    );
    const projectId = String.fromEnvironment(
      'FIREBASE_WEB_PROJECT_ID',
      defaultValue: 'the-we-system',
    );
    if (apiKey.isNotEmpty &&
        appId.isNotEmpty &&
        messagingSenderId.isNotEmpty &&
        projectId.isNotEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: messagingSenderId,
          projectId: projectId,
          authDomain: String.fromEnvironment(
            'FIREBASE_WEB_AUTH_DOMAIN',
            defaultValue: 'the-we-system.firebaseapp.com',
          ),
          storageBucket: String.fromEnvironment(
            'FIREBASE_WEB_STORAGE_BUCKET',
            defaultValue: 'the-we-system.firebasestorage.app',
          ),
          measurementId: String.fromEnvironment(
            'FIREBASE_WEB_MEASUREMENT_ID',
            defaultValue: 'G-HHEPHXRDQ4',
          ),
        ),
      );
    }
  } else if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    await Firebase.initializeApp();
  }
  runApp(const ProviderScope(child: PushRegistration(child: MyApp())));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoom =
        ref.watch(approvalDashboardControllerProvider).asData?.value.zoom ??
        1.0;

    return MaterialApp.router(
      title: '우리기술 전자결재',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return _AppInteractionLayer(
          zoom: zoom,
          mediaQuery: mediaQuery,
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: TheWeTheme.light,
    );
  }
}

class _AppInteractionLayer extends ConsumerStatefulWidget {
  const _AppInteractionLayer({
    required this.zoom,
    required this.mediaQuery,
    required this.child,
  });

  final double zoom;
  final MediaQueryData mediaQuery;
  final Widget child;

  @override
  ConsumerState<_AppInteractionLayer> createState() =>
      _AppInteractionLayerState();
}

class _AppInteractionLayerState extends ConsumerState<_AppInteractionLayer> {
  late final AppZoomWheelDisposer _removeWebZoomWheelHandler;
  late final Timer _backgroundRefreshTimer;

  @override
  void initState() {
    super.initState();
    _removeWebZoomWheelHandler = registerAppZoomWheelHandler((delta) {
      if (!mounted) return;
      ref.read(approvalDashboardControllerProvider.notifier).adjustZoom(delta);
    });
    _backgroundRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final dashboardState = ref
          .read(approvalDashboardControllerProvider)
          .asData
          ?.value;
      if (dashboardState?.isAuthenticated != true) return;
      ref
          .read(approvalDashboardControllerProvider.notifier)
          .refreshInBackground();
    });
  }

  @override
  void dispose() {
    _removeWebZoomWheelHandler();
    _backgroundRefreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(approvalOperationErrorProvider, (previous, next) {
      if (next == null || next.isEmpty) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        showTheWeSnackBar(
          context,
          message: next,
          type: TheWeSnackBarType.error,
        );
        ref.read(approvalOperationErrorProvider.notifier).clear();
      });
    });

    final dashboardState = ref
        .watch(approvalDashboardControllerProvider)
        .asData
        ?.value;
    final acknowledgementState = ref.watch(
      dismissedRejectedApprovalAlertsProvider,
    );
    final acknowledgedRejections = acknowledgementState.asData?.value;
    final rejectedDocuments =
        dashboardState != null && acknowledgedRejections != null
        ? dashboardState.rejectedAuthoredDocuments
              .where(
                (document) => !acknowledgedRejections.contains(
                  rejectedApprovalEventKey(document),
                ),
              )
              .toList()
        : const <ApprovalDocument>[];

    return Listener(
      onPointerSignal: (event) {
        final keyboard = HardwareKeyboard.instance;
        final hasZoomModifier =
            keyboard.isControlPressed || keyboard.isMetaPressed;
        if (event is PointerScrollEvent &&
            hasZoomModifier &&
            event.scrollDelta.dy != 0) {
          ref
              .read(approvalDashboardControllerProvider.notifier)
              .adjustZoom(event.scrollDelta.dy > 0 ? -0.05 : 0.05);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppZoomViewport(
            zoom: widget.zoom,
            mediaQuery: widget.mediaQuery,
            child: widget.child,
          ),
          if (rejectedDocuments.isNotEmpty)
            Align(
              alignment: Alignment.topRight,
              child: RejectedApprovalAlert(
                document: rejectedDocuments.first,
                pendingCount: rejectedDocuments.length,
                onOpen: () => appRouter.goNamed(
                  AppRouteName.detail,
                  pathParameters: {'id': rejectedDocuments.first.id},
                ),
                onDismiss: () => ref
                    .read(dismissedRejectedApprovalAlertsProvider.notifier)
                    .acknowledge(rejectedDocuments.first),
              ),
            ),
        ],
      ),
    );
  }
}

class AppZoomViewport extends StatelessWidget {
  const AppZoomViewport({
    required this.zoom,
    required this.mediaQuery,
    required this.child,
    super.key,
  });

  final double zoom;
  final MediaQueryData mediaQuery;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scale = zoom.clamp(0.85, 1.55);
    final viewportSize = mediaQuery.size;
    final logicalSize = Size(
      viewportSize.width / scale,
      viewportSize.height / scale,
    );

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: 0,
        maxWidth: double.infinity,
        minHeight: 0,
        maxHeight: double.infinity,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: logicalSize.width,
            height: logicalSize.height,
            child: MediaQuery(
              data: mediaQuery.copyWith(size: logicalSize),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
