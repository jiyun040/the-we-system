import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/main.dart';

void main() {
  testWidgets(
    'mobile approval and attendance screens render without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      appRouter.go('/');
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'edu_teacher');
      await tester.enterText(find.byType(TextFormField).at(1), '1234');
      await tester.tap(find.text('로그인').last);
      await tester.pumpAndSettle();

      appRouter.go('/approval/new?form=purchase-request');
      await tester.pumpAndSettle();
      expect(find.text('비품/소모품 구입신청서'), findsWidgets);
      expect(
        find.byKey(const ValueKey('mobile-document-line-0-date')),
        findsOneWidget,
      );
      expect(find.text('합계'), findsOneWidget);
      expect(tester.takeException(), isNull);

      appRouter.go('/approval/APR-260629-001');
      await tester.pumpAndSettle();
      expect(find.text('업무용 PC 구매 예산 할당 요청'), findsWidgets);
      expect(tester.takeException(), isNull);

      appRouter.go('/approval/absence?view=monthly');
      await tester.pumpAndSettle();
      expect(find.text('월간'), findsOneWidget);
      expect(find.text('근무상태변경'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('신청서 작성'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('초과근로 신청서').last);
      await tester.pumpAndSettle();
      expect(find.text('초과근로 신청'), findsOneWidget);
      expect(find.text('18:00'), findsOneWidget);
      expect(find.text('21:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('18:00'));
      await tester.pumpAndSettle();
      expect(find.text('초과근로발생시작일 시간 선택'), findsOneWidget);
      await tester.tap(find.text('취소').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('신청서 작성'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('근무시간 수정 신청서').last);
      await tester.pumpAndSettle();
      expect(find.text('근무시간수정 신청'), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('11:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('추가'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      appRouter.go('/approval/absence?section=company-status');
      await tester.pumpAndSettle();
      expect(find.text('내 근태현황'), findsWidgets);
      expect(find.text('전사 근태현황'), findsNothing);
      expect(tester.takeException(), isNull);

      appRouter.go('/leave');
      await tester.pumpAndSettle();
      expect(find.text('휴가 현황'), findsOneWidget);
      expect(find.text('총 연차'), findsOneWidget);
      expect(find.text('잔여 연차'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
      expect(
        find.byKey(const ValueKey('mobile-leave-request-list')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('휴가 신청'));
      await tester.pumpAndSettle();
      expect(find.textContaining('시작일'), findsOneWidget);
      expect(find.textContaining('종료일'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('취소').last);
      await tester.pumpAndSettle();

      appRouter.go('/approval/settings');
      await tester.pumpAndSettle();
      await tester.tap(find.text('일반 작성'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('간편 작성').last);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -180));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.textContaining('파일명으로 표시'));
      await tester.tap(find.textContaining('파일명으로 표시'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(find.text('간편 작성'), findsOneWidget);
      expect(tester.takeException(), isNull);

      appRouter.go('/');
      await tester.pumpAndSettle();
      appRouter.go('/approval/settings');
      await tester.pumpAndSettle();
      expect(find.text('간편 작성'), findsOneWidget);
    },
  );
}
