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

    expect(find.text('근태 관리'), findsWidgets);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      TheWeColor.background,
    );
    expect(find.text('회사 운영 현황'), findsOneWidget);
    await tester.tap(find.text('전체 직원'));
    await tester.pumpAndSettle();
    expect(find.text('전체 직원 연차 현황'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '교육강사'));
    await tester.pumpAndSettle();
    expect(find.text('교육강사 휴가 현황'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('admin-direct-leave-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('admin-direct-leave-reason')),
      '관리자 직접 반영 테스트',
    );
    await tester.tap(find.byKey(const ValueKey('admin-direct-leave-submit')));
    await tester.pumpAndSettle();
    expect(find.text('관리자 등록'), findsOneWidget);
    expect(find.textContaining('관리자 직접 반영 테스트'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('employee-leave-back')));
    await tester.pumpAndSettle();
    expect(find.text('전체 직원 연차 현황'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '교육관리자'));
    await tester.pumpAndSettle();
    expect(find.text('교육관리자 휴가 현황'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();
    expect(find.text('전자결재 문서 관리'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('admin-document-filter-전체')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('admin-document-filter-결재대기')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey('admin-document-filter-전체')),
          )
          .checkmarkColor,
      TheWeColor.blue300,
    );
    expect(find.text('상세'), findsNWidgets(6));
    await tester.tap(find.text('상세').first);
    await tester.pumpAndSettle();
    expect(find.text('결재 정보'), findsOneWidget);
    appRouter.pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('사원 관리').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('직원 추가'));
    await tester.pumpAndSettle();
    expect(find.text('초기 비밀번호'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextField, '입사일'));
    await tester.pumpAndSettle();
    expect(find.text('입사일 선택'), findsOneWidget);
    expect(find.byKey(const ValueKey('hire-date-picker')), findsOneWidget);
    await tester.tap(find.text('취소').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('조직 관리').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('부서명 수정').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('department-name-field')),
      '교육운영팀',
    );
    await tester.tap(find.text('저장').last);
    await tester.pumpAndSettle();
    expect(find.text('교육운영팀'), findsWidgets);

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
    expect(find.text('포털 및 로고'), findsOneWidget);
    expect(find.text('로고 변경'), findsOneWidget);
    expect(find.text('임직원 포털 명'), findsOneWidget);
    expect(find.text('조직도 설정'), findsOneWidget);
    expect(find.text('APP 설정'), findsOneWidget);
    expect(find.text('관리자 권한 설정'), findsOneWidget);
    final organizationTile = tester.widget<ExpansionTile>(
      find.byType(ExpansionTile).first,
    );
    expect(organizationTile.shape, const Border());
    expect(organizationTile.collapsedShape, const Border());
    final departmentTiles = find.byType(ExpansionTile);
    expect(departmentTiles, findsNWidgets(4));
    final firstDepartment = departmentTiles.at(0);
    final secondDepartment = departmentTiles.at(1);
    final firstController = tester
        .widget<ExpansionTile>(firstDepartment)
        .controller!;
    final secondController = tester
        .widget<ExpansionTile>(secondDepartment)
        .controller!;
    final firstTitle = tester.widget<ExpansionTile>(firstDepartment).title;
    final secondTitle = tester.widget<ExpansionTile>(secondDepartment).title;
    await tester.ensureVisible(firstDepartment);
    await tester.tap(
      find.descendant(of: firstDepartment, matching: find.byWidget(firstTitle)),
    );
    await tester.pumpAndSettle();
    expect(firstController.isExpanded, isTrue);
    await tester.ensureVisible(secondDepartment);
    await tester.tap(
      find.descendant(
        of: secondDepartment,
        matching: find.byWidget(secondTitle),
      ),
    );
    await tester.pumpAndSettle();
    expect(firstController.isExpanded, isFalse);
    expect(secondController.isExpanded, isTrue);
    expect(
      find.byKey(const ValueKey('integrated-app-switch-approval')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('admin-permission-admin_master')),
      findsOneWidget,
    );
    const otpPolicyKey = ValueKey('security-admin-otp');
    expect(find.byKey(otpPolicyKey), findsOneWidget);
    final otpSwitch = find.descendant(
      of: find.byKey(otpPolicyKey),
      matching: find.byType(Switch),
    );
    expect(tester.widget<Switch>(otpSwitch).value, isTrue);
    await tester.ensureVisible(otpSwitch);
    await tester.pumpAndSettle();
    await tester.tap(otpSwitch);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(otpSwitch).value, isFalse);
    await tester.tap(otpSwitch);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('annual-leave-10')), findsOneWidget);
    expect(find.byKey(const ValueKey('annual-leave-11')), findsNothing);
    expect(
      tester.widget<Divider>(find.byType(Divider).first).color,
      TheWeColor.black300.withValues(alpha: .2),
    );

    await tester.ensureVisible(find.byKey(const ValueKey('annual-leave-1')));
    await tester.enterText(find.byKey(const ValueKey('annual-leave-1')), '16');
    await tester.pump();
    await tester.tap(find.text('연차 설정 저장'));
    await tester.pumpAndSettle();
    expect(find.text('연차 설정이 저장되었습니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('admin-logout-button')));
    await tester.pumpAndSettle();
    expect(find.text('로그아웃할까요?'), findsOneWidget);
    await tester.tap(find.text('로그아웃').last);
    await tester.pumpAndSettle();
    expect(find.text('로그인'), findsWidgets);
    expect(find.text('회사 운영 현황'), findsNothing);
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

    expect(find.text('근태 관리'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('전체 직원'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, '교육강사'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('employee-leave-type-LEAVE-SEED-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('employee-leave-date-LEAVE-SEED-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('employee-leave-reason-LEAVE-SEED-1')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('admin-direct-leave-button')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Widget>(
        find.byKey(const ValueKey('admin-direct-leave-date-layout')),
      ),
      isA<Column>(),
    );
    await tester.tap(find.text('취소').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('employee-leave-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('사원 관리').last);
    await tester.pumpAndSettle();
    expect(find.text('사원 관리'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('employee-card-edu_manager')),
      findsOneWidget,
    );
    await tester.tap(find.text('직원 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextField, '입사일'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hire-date-picker')), findsOneWidget);
    expect(find.byType(CalendarDatePicker), findsOneWidget);
    await tester.tap(find.text('취소').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소').last);
    await tester.pumpAndSettle();
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
    expect(find.byKey(const ValueKey('admin-logout-button')), findsOneWidget);
    await tester.tap(find.byTooltip('일반 화면'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('관리자 계정 전환'), findsOneWidget);
    await tester.tap(find.byTooltip('관리자 계정 전환'));
    await tester.pumpAndSettle();
    expect(find.text('관리자 인증이 필요합니다'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
