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
  test('조직도 부서는 지정 순서로 표시하고 추가 부서는 가나다순으로 정렬한다', () {
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
      '대표이사',
      '기술부',
      '연구소',
      '관리부',
      '공무',
      '경리부',
      '가나다부서',
      '추가부서',
    ]);
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

  testWidgets('조직도 및 부서 관리 화면은 가용 너비에 좌측 정렬된다', (tester) async {
    final account = _account(
      id: 'account',
      name: '김효민',
      department: '경리부',
      position: '대리',
    );
    final state = signedOutApprovalState.copyWith(
      accounts: [account],
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
    expect(
      find.byKey(const ValueKey('department-card-신규부서')),
      findsOneWidget,
    );
    expect(find.byTooltip('신규부서 구성원 추가'), findsOneWidget);
    expect(find.byTooltip('부서명 수정'), findsNWidgets(2));
    expect(find.byTooltip('부서 삭제'), findsNWidgets(2));
    expect(find.byTooltip('김효민 정보 수정'), findsOneWidget);
    expect(find.byTooltip('김효민 구성원 삭제'), findsOneWidget);
  });
}
