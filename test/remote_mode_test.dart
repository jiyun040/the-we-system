import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/core/config/app_env.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/main.dart';

class _SignedOutController extends ApprovalDashboardController {
  @override
  Future<ApprovalDashboardState> build() async => signedOutApprovalState;
}

void main() {
  test('기본 실행은 Django API 주소를 사용한다', () {
    expect(AppEnv.baseUrl, isNotEmpty);
    expect(AppEnv.baseUrl, endsWith('/api/v1'));
  });

  test('로그아웃 초기 상태에는 업무 데이터가 없다', () {
    expect(signedOutApprovalState.accounts, isEmpty);
    expect(signedOutApprovalState.formTemplates, isEmpty);
    expect(signedOutApprovalState.documents, isEmpty);
    expect(signedOutApprovalState.leaveRequests, isEmpty);
  });

  test('조직도에서 시스템 관리자와 빈 부서를 제외한다', () {
    final state = signedOutApprovalState.copyWith(
      accounts: const [
        EmployeeAccount(
          id: 'admin',
          password: '',
          name: '슈퍼어드민',
          department: '시스템관리',
          position: '시스템 관리자',
          email: '',
          isAdmin: true,
        ),
        EmployeeAccount(
          id: 'employee',
          password: '',
          name: '직원',
          department: '운영팀',
          position: '사원',
          email: '',
        ),
        EmployeeAccount(
          id: 'unassigned',
          password: '',
          name: '미배정',
          department: '',
          position: '사원',
          email: '',
        ),
      ],
      selectedOrgDepartment: '운영팀',
    );

    expect(state.departments, ['운영팀']);
    expect(state.selectedDepartmentMembers.map((account) => account.id), [
      'employee',
    ]);
  });

  testWidgets('로그인 화면은 계정 정보를 자동 입력하지 않는다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approvalDashboardControllerProvider.overrideWith(
            _SignedOutController.new,
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField));
    expect(fields, hasLength(2));
    for (final field in fields) {
      expect(field.controller?.text ?? '', isEmpty);
    }
  });
}
