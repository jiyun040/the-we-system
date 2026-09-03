import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/features/approval/presentation/pages/admin/approval_admin_annual_leave_policy.dart';
import 'package:the_we_system/features/approval/presentation/pages/admin/approval_admin_leave_approval_lines.dart';

class _LeaveConfigurationController extends ApprovalDashboardController {
  _LeaveConfigurationController(this.initialState);

  final ApprovalDashboardState initialState;

  @override
  Future<ApprovalDashboardState> build() async => initialState;
}

const _manager = EmployeeAccount(
  id: 'manager',
  password: '',
  name: '김부장',
  department: '관리부',
  position: '부장',
  isAdmin: true,
);

const _ceo = EmployeeAccount(
  id: 'ceo',
  password: '',
  name: '박대표',
  department: '대표이사',
  position: '대표',
);

void main() {
  test('완료 근속 5년을 6년차가 아닌 5년 기준으로 계산한다', () {
    final employee = EmployeeAccount(
      id: 'six-year-employee',
      password: '',
      name: '6년차 직원',
      department: '관리부',
      position: '사원',
      hireDate: '${DateTime.now().year - 5}-01-01',
    );
    final state = signedOutApprovalState.copyWith(
      annualLeaveByYear: const {1: 15, 5: 17, 6: 18, 10: 20},
    );

    expect(state.serviceYearFor(employee), 5);
    expect(state.annualLeaveDaysFor(employee), 17);
  });

  test('현재 순서의 부서별 휴가 결재자만 승인할 수 있다', () {
    final request = LeaveRequest(
      id: 'leave-1',
      userId: 'employee',
      type: '연차',
      startDate: '2026-09-10',
      endDate: '2026-09-10',
      days: 1,
      reason: '개인 일정',
      approvalLine: const [
        LeaveApprovalStep(
          userId: 'manager',
          name: '김부장',
          department: '관리부',
          position: '부장',
          status: '진행중',
        ),
        LeaveApprovalStep(
          userId: 'ceo',
          name: '박대표',
          department: '대표이사',
          position: '대표',
          status: '예정',
        ),
      ],
    );
    final managerState = signedOutApprovalState.copyWith(currentUser: _manager);
    final ceoState = signedOutApprovalState.copyWith(currentUser: _ceo);

    expect(managerState.canActOnLeave(request), isTrue);
    expect(ceoState.canActOnLeave(request), isFalse);
  });

  testWidgets('부서별 휴가 결재라인과 순서를 설정할 수 있다', (tester) async {
    final state = signedOutApprovalState.copyWith(
      currentUser: _manager,
      accounts: const [_manager, _ceo],
      organizationDepartments: const ['대표이사', '관리부'],
      leaveApprovalLines: const {
        '관리부': ['manager', 'ceo'],
      },
      adminMode: true,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approvalDashboardControllerProvider.overrideWith(
            () => _LeaveConfigurationController(state),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: AdminDepartmentLeaveApprovalLines(state: state)),
        ),
      ),
    );

    expect(find.text('김부장 부장  →  박대표 대표'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('leave-approval-line-edit-관리부')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('leave-approval-line-editor')),
      findsOneWidget,
    );
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.textContaining('최종 승인'), findsOneWidget);
  });

  testWidgets('연차 설정에서 빈 근속연수 구간을 추가한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AdminAnnualLeavePolicyEditor(
              policy: {1: 15, 2: 15, 3: 16, 4: 16, 5: 17, 10: 19},
              monthlyLeavePerMonth: 1,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('annual-leave-6')), findsNothing);
    expect(find.text('5년'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('annual-leave-add-year')));
    await tester.pump();
    expect(find.byKey(const ValueKey('annual-leave-6')), findsOneWidget);
  });
}
