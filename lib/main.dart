import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:the_we_system/common/components/the_we_snack_bar.dart';
import 'package:the_we_system/common/theme/the_we_theme.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';

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

class _AppInteractionLayer extends ConsumerWidget {
  const _AppInteractionLayer({
    required this.zoom,
    required this.mediaQuery,
    required this.child,
  });

  final double zoom;
  final MediaQueryData mediaQuery;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Listener(
      onPointerSignal: (event) {
        final keyboard = HardwareKeyboard.instance;
        final hasZoomModifier =
            keyboard.isControlPressed || keyboard.isMetaPressed;
        if (event is PointerScrollEvent && hasZoomModifier) {
          ref
              .read(approvalDashboardControllerProvider.notifier)
              .adjustZoom(event.scrollDelta.dy > 0 ? -0.05 : 0.05);
        }
      },
      child: MediaQuery(
        data: mediaQuery.copyWith(textScaler: TextScaler.linear(zoom)),
        child: child,
      ),
    );
  }
}
