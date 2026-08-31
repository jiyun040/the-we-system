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
    final state = signedOutApprovalState.copyWith(accounts: [account]);

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
  });
}
