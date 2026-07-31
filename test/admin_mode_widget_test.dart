import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/main.dart';

void main() {
  testWidgets('관리자 OTP 로그인과 통합설정 비밀번호 확인이 동작한다', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    appRouter.go('/');
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    expect(find.text('더우리기술 전자결재'), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(0), 'edu_manager');
    await tester.enterText(find.byType(TextFormField).at(1), '1234');
    await tester.tap(find.text('로그인').last);
    await tester.pumpAndSettle();
    expect(find.text('관리자 OTP 인증'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(find.text('인증'));
    await tester.pumpAndSettle();

    expect(find.text('관리 홈'), findsWidgets);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      TheWeColor.background,
    );
    expect(find.text('회사 운영 현황'), findsOneWidget);

    await tester.tap(find.text('사원 관리').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('직원 추가'));
    await tester.pumpAndSettle();
    expect(find.text('초기 비밀번호'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextField, '입사일'));
    await tester.pumpAndSettle();
    expect(find.text('입사일 선택'), findsOneWidget);
    await tester.tap(find.text('취소').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('APP 관리').first);
    await tester.pumpAndSettle();
    const approvalSwitchKey = ValueKey('app-switch-approval');
    expect(tester.widget<Switch>(find.byKey(approvalSwitchKey)).value, isTrue);
    await tester.tap(find.byKey(approvalSwitchKey));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byKey(approvalSwitchKey)).value, isFalse);
    await tester.tap(find.byKey(approvalSwitchKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('양식 관리'));
    await tester.pumpAndSettle();
    expect(find.text('전자결재 양식 관리'), findsOneWidget);
    expect(find.text('양식 추가'), findsOneWidget);
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('통합 설정').first);
    await tester.pumpAndSettle();
    expect(find.text('통합설정 보안 확인'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '1234');
    await tester.tap(find.text('통합설정 열기'));
    await tester.pumpAndSettle();
    expect(find.text('근속연수별 연차 설정'), findsOneWidget);
    expect(find.text('포털 및 로고'), findsNothing);
    expect(find.text('로고 변경'), findsNothing);
    expect(find.text('임직원 포털 명'), findsNothing);
    expect(find.text('사용 중'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('annual-leave-10')), findsOneWidget);
    expect(find.byKey(const ValueKey('annual-leave-11')), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('annual-leave-1')), '16');
    await tester.pump();
    await tester.tap(find.text('연차 설정 저장'));
    await tester.pumpAndSettle();
    expect(find.text('연차 설정이 저장되었습니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('모바일 일반 화면에서 관리자 전환 버튼이 표시된다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    appRouter.go('/');
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그인').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(find.text('인증'));
    await tester.pumpAndSettle();

    expect(find.text('관리 홈'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('사원 관리').last);
    await tester.pumpAndSettle();
    expect(find.text('사원 관리'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('employee-card-edu_manager')),
      findsOneWidget,
    );
    await tester.tap(find.text('APP 관리').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('양식 관리'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('mobile-form-management-sheet')),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('일반 화면'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('관리자 계정 전환'), findsOneWidget);
    await tester.tap(find.byTooltip('관리자 계정 전환'));
    await tester.pumpAndSettle();
    expect(find.text('관리자 인증이 필요합니다'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
