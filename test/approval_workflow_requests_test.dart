import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_we_system/common/components/rejected_approval_alert.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_step.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/features/approval/presentation/pages/approval/approval_detail_panels.dart';
import 'package:the_we_system/features/approval/presentation/pages/approval/approval_draft_sheet.dart';
import 'package:the_we_system/features/approval/presentation/pages/home/approval_home_overview.dart';

class _WorkflowRequestController extends ApprovalDashboardController {
  _WorkflowRequestController(this.initialState);

  final ApprovalDashboardState initialState;

  @override
  Future<ApprovalDashboardState> build() async => initialState;
}

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

  testWidgets('반려 문서를 확인하면 기안 진행 목록에서 숨긴다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final rejected = _submittedDocument.copyWith(status: '반려');
    final state = signedOutApprovalState.copyWith(
      currentUser: _employee,
      accounts: const [_employee, _technologyManager],
      documents: [rejected],
      enabledAppIds: const {'approval'},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approvalDashboardControllerProvider.overrideWith(
            () => _WorkflowRequestController(state),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ApprovalHomeOverview(state: state),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final confirmButton = find.byKey(
      const ValueKey('acknowledge-rejected-document-APP-SUBMITTED'),
    );
    expect(confirmButton, findsOneWidget);
    await tester.ensureVisible(confirmButton);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(confirmButton, findsNothing);
    expect(find.text('상신한 문서'), findsNothing);
  });

  test('상단 배너 X는 알림만 닫고 기안 진행 문서는 유지한다', () async {
    SharedPreferences.setMockInitialValues({});
    final rejected = _submittedDocument.copyWith(status: '반려');
    final dashboardState = signedOutApprovalState.copyWith(
      currentUser: _employee,
      accounts: const [_employee, _technologyManager],
      documents: [rejected],
    );
    final container = ProviderContainer(
      overrides: [
        approvalDashboardControllerProvider.overrideWith(
          () => _WorkflowRequestController(dashboardState),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(approvalDashboardControllerProvider.future);
    await container.read(dismissedRejectedApprovalAlertsProvider.future);
    await container.read(acknowledgedRejectedDocumentsProvider.future);

    final persistence = container
        .read(dismissedRejectedApprovalAlertsProvider.notifier)
        .acknowledge(rejected);

    // 로컬 저장 완료를 기다리지 않아도 X 클릭 즉시 알림 상태가 제거되어야 한다.
    expect(
      container.read(dismissedRejectedApprovalAlertsProvider).requireValue,
      contains(rejectedApprovalEventKey(rejected)),
    );
    expect(
      container.read(acknowledgedRejectedDocumentsProvider).requireValue,
      isEmpty,
    );
    await persistence;
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
