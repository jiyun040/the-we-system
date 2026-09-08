import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/common/components/rejected_approval_alert.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_step.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/features/approval/presentation/pages/approval/approval_detail_panels.dart';
import 'package:the_we_system/features/approval/presentation/pages/approval/approval_draft_sheet.dart';

const _employee = EmployeeAccount(
  id: 'employee',
  password: '',
  name: '김직원',
  department: '기술부',
  position: '사원',
);

const _technologyManager = EmployeeAccount(
  id: 'technology-manager',
  password: '',
  name: '이기술',
  department: '기술부',
  position: '팀장',
);

const _financeManager = EmployeeAccount(
  id: 'finance-manager',
  password: '',
  name: '박경리',
  department: '경리부',
  position: '부장',
);

const _submittedDocument = ApprovalDocument(
  id: 'APP-SUBMITTED',
  title: '상신한 문서',
  drafter: '김직원',
  department: '기술부',
  form: '업무기안',
  status: '결재대기',
  draftedAt: '2026-09-08',
  dueDate: '2026-09-09',
  progress: 50,
  steps: [
    ApprovalStep(name: '김직원', department: '기술부', role: '사원', status: '완료'),
    ApprovalStep(name: '이기술', department: '기술부', role: '팀장', status: '진행중'),
  ],
);

void main() {
  testWidgets('상신 후 오른쪽 패널에서 결재선 탭을 숨긴다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 700,
            child: ApprovalRightPanel(
              document: _submittedDocument,
              showApprovalLine: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('결재선'), findsNothing);
    expect(find.text('문서정보'), findsOneWidget);
    expect(find.text('변경이력'), findsOneWidget);
    expect(find.text('열람'), findsOneWidget);
  });

  testWidgets('기안 첨부 영역에서 파일 드래그를 받는다', (tester) async {
    final title = TextEditingController(text: '첨부 테스트');
    final content = TextEditingController(text: '내용');
    addTearDown(title.dispose);
    addTearDown(content.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ApprovalEditableDraftSheet(
              document: _submittedDocument.copyWith(status: '작성중'),
              titleController: title,
              contentController: content,
              onAddAttachment: () {},
              onDropAttachments: (_) async {},
              onAddLinkedDocument: () {},
              onRemoveLinkedDocument: (_) {},
              onRemoveAttachment: (_) {},
              departmentVisible: true,
              onDepartmentVisibilityChanged: (_) {},
              onFormFieldChanged: (_, _) {},
              onLineItemChanged: (_, _, _) {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('approval-attachment-drop-target')),
      findsOneWidget,
    );
    expect(find.byType(DropTarget), findsOneWidget);
    expect(find.textContaining('드래그'), findsOneWidget);
  });

  test('일반 계정에는 자기 부서의 휴가 결재자만 제공한다', () {
    final state = signedOutApprovalState.copyWith(
      currentUser: _employee,
      accounts: const [_employee, _technologyManager, _financeManager],
      leaveApprovalLines: const {
        '기술부': ['technology-manager'],
        '경리부': ['finance-manager'],
      },
    );

    expect(state.currentUserLeaveApprovers.map((account) => account.id), [
      'technology-manager',
    ]);
  });

  testWidgets('반려 문서를 작은 상단 알림으로 표시한다', (tester) async {
    var opened = false;
    var dismissed = false;
    final rejected = _submittedDocument.copyWith(status: '반려');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: RejectedApprovalAlert(
              document: rejected,
              pendingCount: 1,
              onOpen: () => opened = true,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('결재 문서가 반려됐습니다'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('rejected-approval-open')));
    await tester.tap(find.byKey(const ValueKey('rejected-approval-dismiss')));
    expect(opened, isTrue);
    expect(dismissed, isTrue);
  });

  test('기안자의 반려 문서만 알림 대상으로 선별한다', () {
    final state = signedOutApprovalState.copyWith(
      currentUser: _employee,
      documents: [
        _submittedDocument.copyWith(status: '반려'),
        _submittedDocument.copyWith(
          id: 'APP-OTHER',
          drafter: '다른 직원',
          status: '반려',
        ),
        _submittedDocument.copyWith(id: 'APP-DONE', status: '완료'),
      ],
    );

    expect(state.rejectedAuthoredDocuments.map((document) => document.id), [
      'APP-SUBMITTED',
    ]);
  });
}
