import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:the_we_system/common/components/the_we_snack_bar.dart';
import 'package:the_we_system/common/components/rejected_approval_alert.dart';
import 'package:the_we_system/common/theme/the_we_theme.dart';
import 'package:the_we_system/core/platform/app_zoom_wheel_bridge.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR');
  runApp(const ProviderScope(child: MyApp()));
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
  String? _loadedRejectedAlertsForUserId;
  String? _loadingRejectedAlertsForUserId;
  Set<String> _dismissedRejectedAlerts = const {};

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
    final userId = dashboardState?.currentUser?.id;
    _ensureRejectedAlertsLoaded(userId);
    final rejectedDocuments =
        userId != null && _loadedRejectedAlertsForUserId == userId
        ? dashboardState!.rejectedAuthoredDocuments
              .where(
                (document) => !_dismissedRejectedAlerts.contains(
                  _rejectedApprovalEventKey(document),
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
                onDismiss: () =>
                    _dismissRejectedAlert(userId!, rejectedDocuments.first),
              ),
            ),
        ],
      ),
    );
  }

  void _ensureRejectedAlertsLoaded(String? userId) {
    if (userId == null ||
        userId == _loadedRejectedAlertsForUserId ||
        userId == _loadingRejectedAlertsForUserId) {
      return;
    }
    _loadingRejectedAlertsForUserId = userId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final preferences = await SharedPreferences.getInstance();
      final dismissed = preferences.getStringList(
        _rejectedAlertPreferenceKey(userId),
      );
      if (!mounted ||
          ref
                  .read(approvalDashboardControllerProvider)
                  .asData
                  ?.value
                  .currentUser
                  ?.id !=
              userId) {
        return;
      }
      setState(() {
        _loadedRejectedAlertsForUserId = userId;
        _loadingRejectedAlertsForUserId = null;
        _dismissedRejectedAlerts = {...?dismissed};
      });
    });
  }

  Future<void> _dismissRejectedAlert(
    String userId,
    ApprovalDocument document,
  ) async {
    final updated = {
      ..._dismissedRejectedAlerts,
      _rejectedApprovalEventKey(document),
    };
    setState(() => _dismissedRejectedAlerts = updated);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _rejectedAlertPreferenceKey(userId),
      updated.toList(),
    );
  }
}

String _rejectedAlertPreferenceKey(String userId) =>
    'dismissed_rejected_approval_alerts_$userId';

String _rejectedApprovalEventKey(ApprovalDocument document) {
  final rejectedStep = document.steps
      .where((step) => step.status == '반려')
      .lastOrNull;
  final rejectionHistory = document.histories
      .where(
        (history) =>
            history.category.contains('반려') ||
            history.description.contains('반려'),
      )
      .lastOrNull;
  final eventId =
      rejectedStep?.approvedAt ?? rejectionHistory?.id ?? document.draftedAt;
  return '${document.id}:$eventId';
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
