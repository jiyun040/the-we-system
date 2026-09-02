import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/features/approval/presentation/pages/admin/approval_admin_document_access.dart';

EmployeeAccount _account({
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
  testWidgets('일부 사용자 조직도는 지정 부서 및 직급 순서로 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const template = ApprovalFormTemplate(
      id: 'test-form',
      category: '테스트 구분',
      name: '테스트 양식',
      description: '',
      defaultTitle: '',
      defaultContent: '',
      receivers: [],
      references: [],
      viewers: [],
      publicReceivers: [],
      cooperationDepartment: '',
      agreement: '',
    );
    final state = signedOutApprovalState.copyWith(
      accounts: [
        _account(
          id: 'accounting',
          name: '경리 담당',
          department: '경리부',
          position: '대리',
        ),
        _account(
          id: 'management-head',
          name: '관리 부장',
          department: '관리부',
          position: '부장',
        ),
        _account(
          id: 'technology',
          name: '기술 담당',
          department: '기술부',
          position: '전무',
        ),
        _account(
          id: 'management-director',
          name: '관리 이사',
          department: '관리부',
          position: '이사',
        ),
        _account(
          id: 'representative',
          name: '대표 담당',
          department: '대표이사',
          position: '대표',
        ),
        _account(
          id: 'construction',
          name: '공무 담당',
          department: '공무',
          position: '대리',
        ),
        _account(
          id: 'research',
          name: '연구 담당',
          department: '연구소',
          position: '부장',
        ),
      ],
      organizationDepartments: const ['대표이사', '기술부', '연구소', '관리부', '공무', '경리부'],
      formTemplates: const [template],
      organizationWideDocumentCategories: const {},
      documentCategoryViewerIds: const {'테스트 구분': <String>{}},
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminDocumentAccessManagement(state: state),
            ),
          ),
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey('document-access-selector-테스트 구분')),
    );
    await tester.pumpAndSettle();

    const departmentOrder = ['대표이사', '기술부', '연구소', '관리부', '공무', '경리부'];
    final dialog = find.byKey(
      const ValueKey('document-access-organization-dialog'),
    );
    final departmentList = find.descendant(
      of: dialog,
      matching: find.byType(Scrollable),
    );
    for (final department in departmentOrder) {
      final departmentTile = find.byKey(
        ValueKey('document-access-department-$department'),
      );
      await tester.scrollUntilVisible(
        departmentTile,
        90,
        scrollable: departmentList.first,
      );
      expect(departmentTile, findsOneWidget);

      if (department == '관리부') {
        await tester.tap(departmentTile);
        await tester.pumpAndSettle();

        final directorOffset = tester.getTopLeft(
          find.byKey(
            const ValueKey('document-access-user-management-director'),
          ),
        );
        final headOffset = tester.getTopLeft(
          find.byKey(const ValueKey('document-access-user-management-head')),
        );
        expect(directorOffset.dy, lessThan(headOffset.dy));
      }
    }
  });
}
