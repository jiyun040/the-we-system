import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/main.dart';

void main() {
  for (final size in <Size>[
    const Size(1440, 1000),
    const Size(900, 900),
    const Size(390, 844),
  ]) {
    testWidgets('Approval dashboard renders at ${size.width}x${size.height}', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('전자결재 홈'), findsOneWidget);
      expect(find.text('결재 대기 문서'), findsOneWidget);
      expect(find.text('업무용 PC 구매 예산 할당 요청'), findsOneWidget);
      expect(find.text('기안 진행 문서'), findsOneWidget);
    });
  }
}
