import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/features/approval/presentation/pages/admin/approval_admin_people_organization.dart';

EmployeeAccount _account({
  required String id,
  required String name,
  required String department,
  required String position,
  bool isAdmin = true,
}) => EmployeeAccount(
  id: id,
  password: '',
  name: name,
  department: department,
  position: position,
  email: '',
  isAdmin: isAdmin,
);

void main() {
  test('조직도 부서는 서버에 저장된 순서를 유지하고 누락 부서는 뒤에 추가한다', () {
    final state = signedOutApprovalState.copyWith(
      organizationDepartments: const ['추가부서', '연구소', '대표이사', '기술부', '가나다부서'],
      accounts: [
        _account(
          id: 'accounting',
          name: '회계담당',
          department: '경리부',
          position: '대리',
          isAdmin: false,
        ),
        _account(
          id: 'construction',
          name: '공무담당',
          department: '공무',
          position: '대리',
          isAdmin: false,
        ),
        _account(
          id: 'management',
          name: '관리담당',
          department: '관리부',
          position: '부장',
          isAdmin: false,
        ),
      ],
    );

    expect(state.departments, [
      '추가부서',
      '연구소',
      '대표이사',
      '기술부',
      '가나다부서',
      '관리부',
      '공무',
      '경리부',
    ]);
  });

  test('관리자가 조직도 부서를 한 칸씩 이동할 수 있다', () {
    final state = signedOutApprovalState.copyWith(
      organizationDepartments: const ['대표이사', '기술부', '연구소', '관리부', '공무', '경리부'],
    );

    expect(state.reorderedDepartments('관리부', -1), [
      '대표이사',
      '기술부',
      '관리부',
      '연구소',
      '공무',
      '경리부',
    ]);
    expect(state.reorderedDepartments('대표이사', -1), state.departments);
    expect(state.reorderedDepartments('경리부', 1), state.departments);
  });

  test('슈퍼어드민과 김효민 대리만 관리자 모드에 접근한다', () {
    final systemAdmin = _account(
      id: 'admin',
      name: '슈퍼어드민',
      department: '시스템관리',
      position: '시스템 관리자',
    );
    final kimHyomin = _account(
      id: 'we061046',
      name: '김효민',
      department: '경리부',
      position: '대리',
      isAdmin: false,
    );
    final otherAdmin = _account(
      id: 'other-admin',
      name: '조상훈',
      department: '대표이사',
      position: '대표',
    );
    final wrongProfile = _account(
      id: 'another-account',
      name: '김효민',
      department: '경리부',
      position: '대리',
    );

    expect(systemAdmin.canAccessAdminMode, isTrue);
    expect(kimHyomin.canAccessAdminMode, isTrue);
    expect(otherAdmin.canAccessAdminMode, isFalse);
    expect(wrongProfile.canAccessAdminMode, isFalse);
  });

  test('조직도 구성원은 이름보다 직급이 높은 순서로 표시한다', () {
    final director = _account(
      id: 'jung_hyojung',
      name: '정효정',
      department: '관리부',
      position: '이사',
      isAdmin: false,
    );
    final departmentHead = _account(
      id: 'song_hyeongsuk',
      name: '송형숙',
      department: '관리부',
      position: '부장',
      isAdmin: false,
    );
    final state = signedOutApprovalState.copyWith(
      accounts: [departmentHead, director],
      selectedOrgDepartment: '관리부',
    );

    expect(state.selectedDepartmentMembers.map((member) => member.name), [
      '정효정',
      '송형숙',
    ]);
    expect(state.selectedOrgMember?.name, '정효정');
  });

  test('관리자 직원 목록은 부서 순서 다음 직급 순서로 표시한다', () {
    final state = signedOutApprovalState.copyWith(
      accounts: [
        _account(
          id: 'accounting',
          name: '김효민',
          department: '경리부',
          position: '대리',
          isAdmin: false,
        ),
        _account(
          id: 'manager',
          name: '송형숙',
          department: '관리부',
          position: '부장',
          isAdmin: false,
        ),
        _account(
          id: 'research',
          name: '조용덕',
          department: '연구소',
          position: '부장',
          isAdmin: false,
        ),
        _account(
          id: 'ceo',
          name: '조상훈',
          department: '대표이사',
          position: '대표',
          isAdmin: false,
        ),
        _account(
          id: 'director',
          name: '정효정',
          department: '관리부',
          position: '이사',
          isAdmin: false,
        ),
        _account(
          id: 'construction',
          name: '김현정',
          department: '공무',
          position: '대리',
          isAdmin: false,
        ),
        _account(
          id: 'technology',
          name: '조세훈',
          department: '기술부',
          position: '전무',
          isAdmin: false,
        ),
      ],
    );

    expect(state.organizationOrderedAccounts.map((account) => account.name), [
      '조상훈',
      '조세훈',
      '조용덕',
      '정효정',
      '송형숙',
      '김현정',
      '김효민',
    ]);
  });

  testWidgets('조직도 및 부서 관리 화면은 가용 너비에 좌측 정렬된다', (tester) async {
    final account = _account(
      id: 'account',
      name: '김효민',
      department: '경리부',
      position: '대리',
    );
    final representative = _account(
      id: 'ceo',
      name: '조상훈',
      department: '대표이사',
      position: '대표',
      isAdmin: false,
    );
    final state = signedOutApprovalState.copyWith(
      accounts: [account, representative],
      organizationDepartments: const ['신규부서'],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 700,
                child: AdminOrganizationManagement(state: state),
              ),
            ),
          ),
        ),
      ),
    );

    final page = tester.getSize(
      find.byKey(const ValueKey('admin-organization-page')),
    );
    expect(page.width, 700);
    expect(find.byKey(const ValueKey('add-department-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('department-card-신규부서')), findsOneWidget);
    expect(find.byTooltip('신규부서 구성원 추가'), findsOneWidget);
    expect(find.byTooltip('대표이사 구성원 추가'), findsNothing);
    expect(find.byTooltip('신규부서 위로 이동'), findsOneWidget);
    expect(find.byTooltip('신규부서 아래로 이동'), findsOneWidget);
    expect(find.byTooltip('부서명 수정'), findsNWidgets(3));
    expect(find.byTooltip('부서 삭제'), findsNWidgets(3));
    expect(find.byTooltip('김효민 정보 수정'), findsOneWidget);
    expect(find.byTooltip('김효민 구성원 삭제'), findsOneWidget);
    expect(find.byTooltip('조상훈 정보 수정'), findsOneWidget);
    expect(find.byTooltip('조상훈 구성원 삭제'), findsNothing);
  });
}
