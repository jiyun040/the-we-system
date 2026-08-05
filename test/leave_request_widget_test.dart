import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/main.dart';

void main() {
  testWidgets('휴가 신청 종류와 신청 사유 입력이 표시된다', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
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

    expect(find.text('더우리기술 전자결재'), findsOneWidget);
    await tester.tap(find.text('휴가 현황/신청'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('휴가 신청'));
    await tester.pumpAndSettle();

    expect(find.text('휴가 종류'), findsWidgets);
    expect(find.text('신청 사유 (필수)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('leave-start-date-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('leave-date-picker')), findsOneWidget);
    expect(find.text('휴가 시작일 선택'), findsOneWidget);
    expect(find.byType(CalendarDatePicker), findsOneWidget);
    await tester.tap(find.text('취소').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('연차').last);
    await tester.pumpAndSettle();
    expect(find.text('반차'), findsOneWidget);
    expect(find.text('경조 휴가'), findsOneWidget);
    expect(find.text('휴가'), findsWidgets);
    expect(find.text('오전 반차'), findsNothing);
    expect(find.text('오후 반차'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('승인대기 휴가를 누르면 대표 결재 진행 팝업이 표시된다', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
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
    await tester.tap(find.text('휴가 현황/신청'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('휴가 신청'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '개인 일정');
    await tester.tap(find.text('신청').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('승인대기'));
    await tester.pumpAndSettle();
    expect(find.text('결재 진행중'), findsOneWidget);
    expect(find.text('이사 정효정'), findsNothing);
    expect(find.text('대표 조상훈'), findsOneWidget);
    expect(find.text('신청 즉시 대표 결재함으로 전달됩니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
