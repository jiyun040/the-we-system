import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/features/approval/presentation/pages/admin/approval_admin_settings.dart';

EmployeeAccount _adminAccount({
  required String id,
  required bool canChangeAdminOtp,
}) => EmployeeAccount(
  id: id,
  password: '',
  name: '테스트 관리자',
  department: '테스트부서',
  position: '관리자',
  email: '',
  isAdmin: true,
  canChangeAdminOtp: canChangeAdminOtp,
);

Widget _settings(ApprovalDashboardState state) => ProviderScope(
  child: MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: AdminIntegratedSettings(state: state)),
    ),
  ),
);

void main() {
  testWidgets('변경 권한이 있는 관리자에게 OTP 변경 화면을 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final account = _adminAccount(
      id: 'designated-admin',
      canChangeAdminOtp: true,
    );
    final state = signedOutApprovalState.copyWith(currentUser: account);

    await tester.pumpWidget(_settings(state));
    final changeButton = find.byKey(const ValueKey('admin-otp-change-button'));
    await tester.ensureVisible(changeButton);
    await tester.tap(changeButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('admin-otp-change-dialog')),
      findsOneWidget,
    );
    expect(find.text('현재 OTP'), findsOneWidget);
    expect(find.text('새 OTP'), findsOneWidget);
    expect(find.text('새 OTP 확인'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '현재 OTP'), '123');
    await tester.enterText(find.widgetWithText(TextField, '새 OTP'), '654321');
    await tester.enterText(
      find.widgetWithText(TextField, '새 OTP 확인'),
      '654321',
    );
    await tester.tap(find.byKey(const ValueKey('admin-otp-change-submit')));
    await tester.pump();
    expect(find.text('OTP는 숫자 6자리로 입력해 주세요.'), findsOneWidget);
  });

  testWidgets('슈퍼어드민 OTP는 123456 고정으로 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final account = _adminAccount(id: 'admin', canChangeAdminOtp: false);
    final state = signedOutApprovalState.copyWith(currentUser: account);

    await tester.pumpWidget(_settings(state));

    expect(find.text('슈퍼어드민 OTP는 123456으로 고정됩니다.'), findsOneWidget);
    expect(find.text('123456 고정'), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-otp-change-button')), findsNothing);
  });
}
