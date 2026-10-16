import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/components/side_bar.dart';
import 'package:the_we_system/common/components/side_bar_sections.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';

class _MenuController extends ApprovalDashboardController {
  _MenuController(this.initialState);

  final ApprovalDashboardState initialState;

  @override
  Future<ApprovalDashboardState> build() async => initialState;
}

const _manager = EmployeeAccount(
  id: 'manager',
  password: '',
  name: '관리자',
  department: '공무부서',
  position: '관리자',
  isAdmin: true,
);

const _superAdmin = EmployeeAccount(
  id: 'admin',
  password: '',
  name: '슈퍼어드민',
  department: '관리부',
  position: '관리자',
  isAdmin: true,
);

Future<void> _pumpMenu(
  WidgetTester tester, {
  required EmployeeAccount account,
  required bool adminMode,
  String initialLocation = AppRoutePath.home,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 1100);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final state = signedOutApprovalState.copyWith(
    currentUser: account,
    accounts: [account],
    adminMode: adminMode,
  );
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        name: AppRouteName.home,
        path: AppRoutePath.home,
        builder: (context, _) => const Scaffold(
          body: SideBar(
            frequentForms: [],
            pendingDocument: 0,
            receiveDocument: 0,
            openPendingDocument: 0,
            scheduledDocument: 0,
          ),
        ),
      ),
      GoRoute(
        name: AppRouteName.absence,
        path: AppRoutePath.absence,
        builder: (context, _) => const Scaffold(
          body: SideBar(
            frequentForms: [],
            pendingDocument: 0,
            receiveDocument: 0,
            openPendingDocument: 0,
            scheduledDocument: 0,
          ),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        approvalDashboardControllerProvider.overrideWith(
          () => _MenuController(state),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('관리자 홈에서도 기존 매출 접근 권한을 적용한다', (tester) async {
    await _pumpMenu(tester, account: _manager, adminMode: true);
    expect(find.text('매출관리대장'), findsOneWidget);
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('근태관리'), findsOneWidget);
    expect(find.text('근태 현황'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('근태관리')).dy,
      lessThan(tester.getTopLeft(find.text('근태 현황')).dy),
    );
  });

  testWidgets('슈퍼어드민은 관리자 홈에서 매출관리대장을 본다', (tester) async {
    await _pumpMenu(tester, account: _superAdmin, adminMode: true);
    expect(find.text('매출관리대장'), findsOneWidget);
  });

  testWidgets('일반 화면의 기존 매출 권한은 유지한다', (tester) async {
    await _pumpMenu(tester, account: _manager, adminMode: false);
    expect(find.text('매출관리대장'), findsOneWidget);
  });

  testWidgets('근태 현황을 열어도 근태관리는 펼쳐지지 않는다', (tester) async {
    await _pumpMenu(tester, account: _manager, adminMode: true);
    await tester.tap(find.text('근태관리'));
    await tester.pumpAndSettle();
    expect(find.text('전사 근태현황'), findsOneWidget);
    await tester.ensureVisible(find.text('근태 현황'));
    await tester.tap(find.text('근태 현황'));
    await tester.pumpAndSettle();

    final management = tester.widget<SideBarCategorySection>(
      find.byWidgetPredicate(
        (widget) => widget is SideBarCategorySection && widget.title == '근태관리',
      ),
    );
    expect(management.initiallyExpanded, isFalse);
    expect(find.text('전사 근태현황'), findsNothing);
  });
}
