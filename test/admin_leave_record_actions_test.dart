import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/features/approval/presentation/pages/admin/approval_admin_leave_overview.dart';

void main() {
  testWidgets('관리자 직원별 휴가 내역에 수정과 삭제 버튼을 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const account = EmployeeAccount(
      id: 'employee',
      password: '',
      name: '홍길동',
      department: '기술부',
      position: '대리',
      hireDate: '2020-01-01',
    );
    const request = LeaveRequest(
      id: 'leave-1',
      userId: 'employee',
      type: '반차',
      startDate: '2026-09-07',
      endDate: '2026-09-07',
      days: .5,
      reason: '개인 일정',
      status: '승인완료',
    );
    final state = signedOutApprovalState.copyWith(
      accounts: const [account],
      currentUser: account,
      leaveRequests: const [request],
      annualLeaveByYear: const {1: 15},
      adminMode: true,
    );
    LeaveRequest? edited;
    LeaveRequest? deleted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminEmployeeLeaveOverviewDialog(
            state: state,
            account: account,
            onBack: () {},
            onDirectLeave: () {},
            onEditLeave: (value) => edited = value,
            onDeleteLeave: (value) => deleted = value,
          ),
        ),
      ),
    );

    final editButton = find.byKey(
      const ValueKey('employee-leave-edit-leave-1'),
    );
    final deleteButton = find.byKey(
      const ValueKey('employee-leave-delete-leave-1'),
    );
    expect(editButton, findsOneWidget);
    expect(deleteButton, findsOneWidget);

    await tester.tap(editButton);
    await tester.tap(deleteButton);

    expect(edited?.id, 'leave-1');
    expect(deleted?.id, 'leave-1');
  });
}
