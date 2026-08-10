import 'package:the_we_system/features/approval/presentation/controllers/approval_controller_models.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';

void replaceApprovalDocument(
  ApprovalDashboardController controller,
  ApprovalDocument document,
) {
  setApprovalDashboardState(controller, (current) {
    final documents = [
      ...current.documents.where((item) => item.id != document.id),
      document,
    ]..sort((a, b) => b.draftedAt.compareTo(a.draftedAt));
    return current.copyWith(documents: documents);
  });
}

void setApprovalDashboardState(
  ApprovalDashboardController controller,
  ApprovalDashboardState Function(ApprovalDashboardState current) update,
) {
  final current = controller.currentDashboardState;
  if (current == null) {
    return;
  }

  controller.emitDashboardState(update(current));
}

List<ApprovalStep> buildApprovalStepsFor(
  EmployeeAccount drafter,
  List<EmployeeAccount> accounts,
) {
  final chain = approvalChainFor(drafter, accounts);
  return [
    ApprovalStep(
      name: drafter.name,
      department: drafter.department,
      type: '신청',
      role: drafter.position,
      status: '기안',
    ),
    ...chain.map(
      (account) => ApprovalStep(
        name: account.name,
        department: account.department,
        type: '승인',
        role: account.position,
        status: '결재 예정',
      ),
    ),
  ];
}

List<Map<String, String>> emptyApprovalLineItems(
  ApprovalFormTemplate template,
) {
  if (template.documentLayout == ApprovalDocumentLayout.basic ||
      template.documentLayout == ApprovalDocumentLayout.payroll) {
    return const [];
  }
  return List.generate(template.lineItemRows, (_) => <String, String>{});
}

List<ApprovalStep> submittedApprovalSteps(
  EmployeeAccount drafter,
  List<EmployeeAccount> accounts,
) {
  final draftSteps = buildApprovalStepsFor(drafter, accounts);
  if (draftSteps.isEmpty) {
    return draftSteps;
  }

  final steps = [...draftSteps];
  steps[0] = steps[0].copyWith(
    status: '완료',
    approvedAt: '${approvalToday()} 09:20',
  );
  if (steps.length > 1) {
    steps[1] = steps[1].copyWith(status: '진행중');
  }
  return steps;
}

List<EmployeeAccount> approvalChainFor(
  EmployeeAccount drafter,
  List<EmployeeAccount> accounts,
) {
  final managerMap = <String, List<String>>{
    '교육관리팀': ['lee_jaeo', 'kim_kyunyoung'],
    '마케팅팀': ['kim_kyunyoung'],
    '개발팀': ['kim_kyunyoung'],
    '인사팀': ['kim_kyunyoung'],
    '기획팀': ['kim_kyunyoung'],
    '운영팀': ['kim_kyunyoung'],
    '경영관리팀': ['kim_kyunyoung', 'ceo'],
  };
  final ids =
      managerMap[drafter.department] ??
      accounts
          .where((account) => account.isAdmin)
          .map((item) => item.id)
          .toList();
  final approvers = accounts
      .where((account) => ids.contains(account.id) && account.id != drafter.id)
      .toList();
  if (approvers.isNotEmpty) {
    return approvers;
  }

  return accounts.where((account) => account.id != drafter.id).take(1).toList();
}

int approvalProgressFor(List<ApprovalStep> steps) {
  if (steps.isEmpty) {
    return 0;
  }

  final completed = steps.where((step) => step.status == '완료').length;
  return ((completed / steps.length) * 100).round();
}

const fallbackApprovalDraft = ApprovalDocument(
  id: 'DRAFT-FALLBACK',
  title: '기안 문서',
  drafter: '사용자',
  department: '부서',
  form: '업무기안[기본양식]',
  status: '작성중',
  draftedAt: '2026-06-29',
  dueDate: '2026-06-29',
  progress: 0,
  documentNo: '임시저장 전',
  effectiveDate: '2026-06-29',
  content: '',
  steps: [],
);

String approvalToday() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}

String approvalDueDate({required int days}) {
  final date = DateTime.now().add(Duration(days: days));
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String nextApprovalId(List<ApprovalDocument> documents) {
  final approvals = documents
      .where((document) => document.id.startsWith('APR-'))
      .length;
  final suffix = (approvals + 1).toString().padLeft(3, '0');
  return 'APR-${approvalToday().replaceAll('-', '')}-$suffix';
}

String nextDraftId(List<ApprovalDocument> documents) {
  final drafts = documents
      .where((document) => document.id.startsWith('DRF-'))
      .length;
  final suffix = (drafts + 1).toString().padLeft(3, '0');
  return 'DRF-${approvalToday().replaceAll('-', '')}-$suffix';
}

extension ApprovalIterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
