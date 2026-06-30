import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/main.dart';

void main() {
  for (final size in <Size>[
    const Size(1440, 1000),
    const Size(900, 900),
    const Size(390, 844),
  ]) {
    testWidgets('Approval flow renders at ${size.width}x${size.height}', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();

      expect(find.text('로그인'), findsWidgets);
      expect(find.text('회원가입'), findsOneWidget);

      await tester.ensureVisible(find.text('로그인').last);
      await tester.tap(find.text('로그인').last);
      await tester.pumpAndSettle();

      expect(find.text('홈'), findsWidgets);
      expect(find.text('캘린더'), findsOneWidget);
      expect(find.text('공지사항'), findsOneWidget);
      expect(find.text('인력 현황'), findsOneWidget);
      expect(find.text('업무 포털'), findsOneWidget);
    });
  }
}
