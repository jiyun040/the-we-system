import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/main.dart';

class _SignedOutController extends ApprovalDashboardController {
  @override
  Future<ApprovalDashboardState> build() async => signedOutApprovalState;
}

void main() {
  testWidgets('Ctrl과 마우스 휠로 화면을 확대하고 축소한다', (tester) async {
    final container = ProviderContainer(
      overrides: [
        approvalDashboardControllerProvider.overrideWith(
          _SignedOutController.new,
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    addTearDown(() => tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft));
    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(400, 300),
        scrollDelta: Offset(0, -100),
      ),
    );
    await tester.pump();

    expect(
      container.read(approvalDashboardControllerProvider).requireValue.zoom,
      1.05,
    );

    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(400, 300),
        scrollDelta: Offset(0, 100),
      ),
    );
    await tester.pump();

    expect(
      container.read(approvalDashboardControllerProvider).requireValue.zoom,
      1.0,
    );
  });

  testWidgets('확대율에 맞춰 글자뿐 아니라 전체 화면 크기를 조정한다', (tester) async {
    late MediaQueryData scaledMediaQuery;
    const viewport = Size(1200, 900);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: viewport),
        child: AppZoomViewport(
          zoom: 1.5,
          mediaQuery: const MediaQueryData(size: viewport),
          child: Builder(
            builder: (context) {
              scaledMediaQuery = MediaQuery.of(context);
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );

    expect(scaledMediaQuery.size, const Size(800, 600));
    expect(scaledMediaQuery.textScaler.scale(16), 16);
    final transform = tester.widget<Transform>(find.byType(Transform));
    expect(transform.transform.getMaxScaleOnAxis(), 1.5);
  });
}
