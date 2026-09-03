import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/features/approval/presentation/pages/admin/approval_admin_annual_leave_policy.dart';
import 'package:the_we_system/features/approval/presentation/pages/admin/approval_admin_leave_approval_lines.dart';
import 'package:the_we_system/features/approval/presentation/pages/admin/approval_admin_leave_management.dart';
import 'package:the_we_system/features/approval/presentation/pages/admin/approval_admin_settings.dart';

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

    expect(
      find.byKey(const ValueKey('leave-approval-line-대표이사')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('leave-approval-line-관리부')),
      findsOneWidget,
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

  testWidgets('APP 설정의 휴가 항목에서 결재라인 관리 화면을 연다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminIntegratedSettings(state: state),
            ),
          ),
        ),
      ),
    );

    expect(find.text('부서별 휴가 결재라인'), findsNothing);
    final manageButton = find.byKey(
      const ValueKey('integrated-leave-approval-line-management'),
    );
    await tester.ensureVisible(manageButton);
    await tester.tap(manageButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('leave-approval-line-management-dialog')),
      findsOneWidget,
    );
    expect(find.text('부서별 휴가 결재라인 관리'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('leave-approval-line-대표이사')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('leave-approval-line-관리부')),
      findsOneWidget,
    );
  });

  testWidgets('휴가 결재라인의 부서와 직원은 조직도 순서로 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const director = EmployeeAccount(
      id: 'director',
      password: '',
      name: '정이사',
      department: '기술부',
      position: '이사',
    );
    const staff = EmployeeAccount(
      id: 'staff',
      password: '',
      name: '김사원',
      department: '기술부',
      position: '사원',
    );
    final state = signedOutApprovalState.copyWith(
      currentUser: _manager,
      accounts: const [staff, _manager, director, _ceo],
      organizationDepartments: const ['대표이사', '관리부', '기술부'],
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

    final ceoDepartmentTop = tester
        .getTopLeft(find.byKey(const ValueKey('leave-approval-line-대표이사')))
        .dy;
    final managementDepartmentTop = tester
        .getTopLeft(find.byKey(const ValueKey('leave-approval-line-관리부')))
        .dy;
    final technologyDepartmentTop = tester
        .getTopLeft(find.byKey(const ValueKey('leave-approval-line-기술부')))
        .dy;
    expect(ceoDepartmentTop, lessThan(managementDepartmentTop));
    expect(managementDepartmentTop, lessThan(technologyDepartmentTop));

    await tester.tap(
      find.byKey(const ValueKey('leave-approval-line-edit-관리부')),
    );
    await tester.pumpAndSettle();

    final ceoTop = tester
        .getTopLeft(find.byKey(const ValueKey('leave-approver-ceo')))
        .dy;
    final managerTop = tester
        .getTopLeft(find.byKey(const ValueKey('leave-approver-manager')))
        .dy;
    final directorTop = tester
        .getTopLeft(find.byKey(const ValueKey('leave-approver-director')))
        .dy;
    final staffTop = tester
        .getTopLeft(find.byKey(const ValueKey('leave-approver-staff')))
        .dy;
    expect(ceoTop, lessThan(managerTop));
    expect(managerTop, lessThan(directorTop));
    expect(directorTop, lessThan(staffTop));
  });

  testWidgets('전체 직원 연차 현황 모달의 데스크톱 표를 세로 스크롤한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final accounts = List.generate(
      20,
      (index) => EmployeeAccount(
        id: 'staff-$index',
        password: '',
        name: '직원-$index',
        department: '관리부',
        position: '사원',
      ),
    );
    final state = signedOutApprovalState.copyWith(
      currentUser: _manager,
      accounts: accounts,
      organizationDepartments: const ['관리부'],
      adminMode: true,
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showAdminEmployeeLeaveDirectory(context, state),
              child: const Text('연차 현황 열기'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('연차 현황 열기'));
    await tester.pumpAndSettle();

    final scroll = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey('employee-leave-directory-scroll')),
    );
    expect(scroll.scrollDirection, Axis.vertical);
    expect(scroll.controller!.position.maxScrollExtent, greaterThan(0));
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(find.text('직원-0')),
        scrollDelta: const Offset(0, 450),
      ),
    );
    await tester.pump();
    expect(scroll.controller!.offset, greaterThan(0));
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
