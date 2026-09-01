import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/features/approval/presentation/pages/admin/approval_admin_people_organization.dart';

const _account = EmployeeAccount(
  id: 'employee-test',
  password: '',
  name: '테스트 직원',
  department: '테스트부서',
  position: '사원',
  email: 'employee@example.com',
  hireDate: '2020-01-01',
  annualLeaveDays: 20,
  monthlyLeaveDays: 6,
  leaveBalanceAdjustment: 2,
);

void main() {
  test('관리자가 입력한 연차와 보정값에서 승인·대기 휴가를 차감한다', () {
    final state = signedOutApprovalState.copyWith(
      accounts: const [_account],
      leaveRequests: const [
        LeaveRequest(
          id: 'approved-leave',
          userId: 'employee-test',
          type: '연차',
          startDate: '2026-01-02',
          endDate: '2026-01-02',
          days: 3.5,
          reason: '테스트',
          status: '승인완료',
        ),
        LeaveRequest(
          id: 'pending-leave',
          userId: 'employee-test',
          type: '연차',
          startDate: '2026-02-02',
          endDate: '2026-02-02',
          days: 1.5,
          reason: '테스트',
        ),
      ],
    );

    expect(state.annualLeaveDaysFor(_account), 20);
    expect(state.monthlyLeaveDaysFor(_account), 6);
    expect(state.remainingAnnualLeaveFor(_account), 17);
  });

  testWidgets('직원 수정 화면에서 아이디와 입사일·휴가 개수를 편집한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = signedOutApprovalState.copyWith(accounts: const [_account]);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminEmployeeManagement(state: state),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('계정 수정'));
    await tester.pumpAndSettle();

    final idField = tester.widget<TextField>(
      find.byKey(const ValueKey('employee-id-edit-field')),
    );
    expect(idField.controller?.text, 'employee-test');
    expect(find.widgetWithText(TextField, '입사일'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('employee-leave-field-연차 개수')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('employee-leave-field-월차 개수')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('employee-leave-field-잔여 개수')),
      findsOneWidget,
    );

    final annualField = tester.widget<TextField>(
      find.byKey(const ValueKey('employee-leave-field-연차 개수')),
    );
    final monthlyField = tester.widget<TextField>(
      find.byKey(const ValueKey('employee-leave-field-월차 개수')),
    );
    final remainingField = tester.widget<TextField>(
      find.byKey(const ValueKey('employee-leave-field-잔여 개수')),
    );
    expect(annualField.controller?.text, '20');
    expect(monthlyField.controller?.text, '6');
    expect(remainingField.controller?.text, '22');
  });
}
