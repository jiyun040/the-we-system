import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/features/approval/presentation/pages/admin/approval_admin_page.dart';
import 'package:the_we_system/features/approval/presentation/pages/home/approval_home_page.dart';

class _RestoreTestController extends ApprovalDashboardController {
  _RestoreTestController(this.initialState);

  final ApprovalDashboardState initialState;

  @override
  Future<ApprovalDashboardState> build() async => initialState;
}

void main() {
  testWidgets('관리자 홈 새로고침 후 기존 관리자 인증 화면을 표시한다', (tester) async {
    SharedPreferences.setMockInitialValues({
      'admin_mode_restore_user_id': 'admin',
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    const account = EmployeeAccount(
      id: 'admin',
      password: '',
      name: '슈퍼어드민',
      department: '관리부',
      position: '관리자',
      isAdmin: true,
    );
    final state = signedOutApprovalState.copyWith(
      currentUser: account,
      accounts: const [account],
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          name: AppRouteName.home,
          path: AppRoutePath.home,
          builder: (context, _) => const ApprovalHomePage(),
        ),
        GoRoute(
          name: AppRouteName.admin,
          path: AppRoutePath.admin,
          builder: (context, _) => const ApprovalAdminPage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approvalDashboardControllerProvider.overrideWith(
            () => _RestoreTestController(state),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('관리자 인증이 필요합니다'), findsOneWidget);
    expect(find.text('OTP 인증'), findsOneWidget);
    expect(find.text('일반 화면으로 돌아가기'), findsOneWidget);
    await tester.tap(find.text('일반 화면으로 돌아가기'));
    await tester.pumpAndSettle();

    expect(find.text('관리자 인증이 필요합니다'), findsNothing);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('admin_mode_restore_user_id'), isNull);
  });
}
