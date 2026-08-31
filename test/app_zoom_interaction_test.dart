import 'package:flutter/gestures.dart';
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
  testWidgets('Ctrl을 누른 채 마우스 휠을 올리면 화면이 확대된다', (tester) async {
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
  });
}
