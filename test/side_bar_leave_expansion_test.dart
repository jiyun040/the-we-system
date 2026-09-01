import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/components/side_bar_sections.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/features/approval/presentation/pages/leave/approval_leave_page.dart';

class _LeaveTestController extends ApprovalDashboardController {
  _LeaveTestController(this.initialState);

  final ApprovalDashboardState initialState;

  @override
  Future<ApprovalDashboardState> build() async => initialState;
}

void main() {
  testWidgets('휴가 현황/신청 화면에서는 전자결재 메뉴를 닫는다', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const account = EmployeeAccount(
      id: 'we061046',
      password: '',
      name: '김효민',
      department: '경리부',
      position: '대리',
      email: '',
    );
    final state = signedOutApprovalState.copyWith(
      currentUser: account,
      accounts: const [account],
    );
    final router = GoRouter(
      initialLocation: AppRoutePath.leave,
      routes: [
        GoRoute(
          name: AppRouteName.leave,
          path: AppRoutePath.leave,
          builder: (context, state) => const ApprovalLeavePage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approvalDashboardControllerProvider.overrideWith(
            () => _LeaveTestController(state),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final approvalSection = tester.widget<SideBarCategorySection>(
      find.byType(SideBarCategorySection),
    );
    expect(approvalSection.title, '전자결재');
    expect(approvalSection.initiallyExpanded, isFalse);
    expect(find.byType(ExpansionTile), findsOneWidget);
    expect(find.text('자주 쓰는 양식'), findsNothing);
    expect(find.text('휴가 현황/신청'), findsOneWidget);
    final leaveScroll = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey('leave-content-scroll')),
    );
    expect(
      leaveScroll.padding,
      const EdgeInsets.fromLTRB(28, 24, 28, 28),
    );
  });
}
