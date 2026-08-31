import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/features/approval/presentation/pages/attendance/approval_absence_page.dart';

class _AttendanceTestController extends ApprovalDashboardController {
  _AttendanceTestController(this.initialState);

  final ApprovalDashboardState initialState;

  @override
  Future<ApprovalDashboardState> build() async => initialState;
}

void main() {
  testWidgets('김효민 대리 관리자 모드에서도 근태 현황을 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
      adminMode: true,
    );
    final router = GoRouter(
      initialLocation: '/attendance?section=company-status',
      routes: [
        GoRoute(
          name: AppRouteName.absence,
          path: '/attendance',
          builder: (context, state) => const ApprovalAbsencePage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approvalDashboardControllerProvider.overrideWith(
            () => _AttendanceTestController(state),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('근태 데이터가 연결되지 않았습니다.'), findsNothing);
    expect(find.text('전사 근태현황'), findsWidgets);
    expect(find.text('김효민'), findsWidgets);
  });
}
