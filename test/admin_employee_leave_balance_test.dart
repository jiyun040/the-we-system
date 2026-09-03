import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
  hireDate: '2020-01-01',
  annualLeaveDays: 20,
  monthlyLeaveDays: 6,
  leaveBalanceAdjustment: 2,
);

EmployeeAccount _directoryAccount({
  required String id,
  required String name,
  required String department,
  required String position,
}) => EmployeeAccount(
  id: id,
  password: '',
  name: name,
  department: department,
  position: position,
);

void main() {
  test('근속연수 설정 연차와 보정값에서 승인·대기 휴가를 차감한다', () {
    final state = signedOutApprovalState.copyWith(
      accounts: const [_account],
      annualLeaveByYear: const {1: 15, 5: 18},
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

    expect(state.annualLeaveDaysFor(_account), 18);
    expect(state.monthlyLeaveDaysFor(_account), 6);
    expect(state.remainingAnnualLeaveFor(_account), 15);
  });

  testWidgets('직원 수정 화면에서 아이디와 입사일·휴가 개수를 편집한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = signedOutApprovalState.copyWith(
      accounts: const [_account],
      annualLeaveByYear: const {1: 15, 5: 18},
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 1320,
                child: SingleChildScrollView(
                  child: AdminEmployeeManagement(state: state),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final editButton = find.byTooltip('계정 수정');
    expect(tester.getRect(editButton).right, lessThanOrEqualTo(1440));
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    final idField = tester.widget<TextField>(
      find.byKey(const ValueKey('employee-id-edit-field')),
    );
    expect(idField.controller?.text, 'employee-test');
    expect(find.text('이메일'), findsNothing);
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
    expect(annualField.controller?.text, '18');
    expect(annualField.readOnly, isTrue);
    expect(monthlyField.controller?.text, '6');
    expect(remainingField.controller?.text, '20');

    final now = DateTime.now();
    final fiveYearsAgo = DateTime(now.year - 5, now.month, now.day);
    final numericHireDate =
        '${fiveYearsAgo.year}'
        '${fiveYearsAgo.month.toString().padLeft(2, '0')}'
        '${fiveYearsAgo.day.toString().padLeft(2, '0')}';
    final formattedHireDate =
        '${fiveYearsAgo.year}-'
        '${fiveYearsAgo.month.toString().padLeft(2, '0')}-'
        '${fiveYearsAgo.day.toString().padLeft(2, '0')}';
    final hireDateField = tester.widget<TextField>(
      find.byKey(const ValueKey('employee-hire-date-field')),
    );
    expect(hireDateField.readOnly, isFalse);
    expect(hireDateField.keyboardType, TextInputType.number);
    await tester.enterText(
      find.byKey(const ValueKey('employee-hire-date-field')),
      numericHireDate,
    );
    await tester.pump();

    expect(hireDateField.controller?.text, formattedHireDate);
    expect(annualField.controller?.text, '18');
    expect(monthlyField.controller?.text, '0');
    expect(remainingField.controller?.text, '18');
    expect(find.textContaining('근속 5년'), findsOneWidget);
  });

  testWidgets('사원관리 필터는 전체 직급순·부서별·이름순으로 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = signedOutApprovalState.copyWith(
      organizationDepartments: const ['대표이사', '관리부', '경리부'],
      accounts: [
        _directoryAccount(
          id: 'staff',
          name: '가사원',
          department: '대표이사',
          position: '사원',
        ),
        _directoryAccount(
          id: 'director',
          name: '나이사',
          department: '경리부',
          position: '이사',
        ),
        _directoryAccount(
          id: 'manager',
          name: '다부장',
          department: '관리부',
          position: '부장',
        ),
      ],
    );

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

    double rowTop(String id) =>
        tester.getTopLeft(find.byKey(ValueKey('employee-row-$id'))).dy;
    expect(rowTop('director'), lessThan(rowTop('manager')));
    expect(rowTop('manager'), lessThan(rowTop('staff')));

    await tester.tap(find.byKey(const ValueKey('employee-filter-department')));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownMenu<String>), findsOneWidget);
    expect(find.byKey(const ValueKey('employee-row-staff')), findsOneWidget);
    expect(find.byKey(const ValueKey('employee-row-director')), findsNothing);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('employee-filter-count')))
          .data,
      '1명',
    );

    await tester.tap(find.byKey(const ValueKey('employee-department-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('경리부').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('employee-row-director')), findsOneWidget);
    expect(find.byKey(const ValueKey('employee-row-staff')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('employee-filter-name')));
    await tester.pumpAndSettle();
    expect(rowTop('staff'), lessThan(rowTop('director')));
    expect(rowTop('director'), lessThan(rowTop('manager')));

    await tester.enterText(
      find.byKey(const ValueKey('employee-name-filter')),
      '다',
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('employee-row-manager')), findsOneWidget);
    expect(find.byKey(const ValueKey('employee-row-staff')), findsNothing);
    expect(find.byKey(const ValueKey('employee-row-director')), findsNothing);
  });

  testWidgets('전체 직원 표 위에서 마우스 휠로 세로 스크롤한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final accounts = [
      for (var index = 0; index < 20; index++)
        _directoryAccount(
          id: 'scroll-staff-$index',
          name: '직원 $index',
          department: '관리부',
          position: '사원',
        ),
    ];
    final state = signedOutApprovalState.copyWith(
      organizationDepartments: const ['관리부'],
      accounts: accounts,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: controller,
              child: AdminEmployeeManagement(
                state: state,
                scrollController: controller,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.position.maxScrollExtent, greaterThan(0));

    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(
          find.byKey(const ValueKey('employee-row-scroll-staff-0')),
        ),
        scrollDelta: const Offset(0, 280),
      ),
    );
    await tester.pump();

    expect(controller.offset, greaterThan(0));
  });
}
