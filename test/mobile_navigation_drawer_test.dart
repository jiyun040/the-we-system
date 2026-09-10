import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/components/mobile_navigation.dart';
import 'package:the_we_system/common/components/side_bar.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/features/approval/presentation/pages/home/approval_home_page.dart';

class _NavigationTestController extends ApprovalDashboardController {
  _NavigationTestController(this.initialState);

  final ApprovalDashboardState initialState;

  @override
  Future<ApprovalDashboardState> build() async => initialState;
}

const _account = EmployeeAccount(
  id: 'employee',
  password: '',
  name: '김직원',
  department: '기술부',
  position: '사원',
);

Future<void> _pumpHome(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final router = GoRouter(
    routes: [
      GoRoute(
        name: AppRouteName.home,
        path: AppRoutePath.home,
        builder: (context, state) => const ApprovalHomePage(),
      ),
    ],
  );
  addTearDown(router.dispose);
  final state = signedOutApprovalState.copyWith(
    currentUser: _account,
    accounts: const [_account],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        approvalDashboardControllerProvider.overrideWith(
          () => _NavigationTestController(state),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('모바일은 하단 바 대신 왼쪽 오버레이 메뉴를 사용한다', (tester) async {
    await _pumpHome(tester, const Size(390, 844));

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(MobileNavigationAppBar), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('mobile-navigation-menu-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('mobile-navigation-drawer')),
      findsOneWidget,
    );
    expect(find.byType(SideBar), findsOneWidget);
    expect(find.text('전자결재'), findsOneWidget);
    expect(find.text('휴가 현황/신청'), findsOneWidget);

    await tester.tap(find.text('홈').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('mobile-navigation-drawer')),
      findsNothing,
    );
  });

  testWidgets('데스크톱은 기존 왼쪽 사이드바를 유지한다', (tester) async {
    await _pumpHome(tester, const Size(1440, 900));

    expect(find.byType(MobileNavigationAppBar), findsNothing);
    expect(
      find.byKey(const ValueKey('mobile-navigation-menu-button')),
      findsNothing,
    );
    expect(find.byType(SideBar), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
