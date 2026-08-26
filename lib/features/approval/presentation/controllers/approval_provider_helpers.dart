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

List<EmployeeAccount> approvalChainFor(
  EmployeeAccount drafter,
  List<EmployeeAccount> accounts,
) {
  final approvers = accounts
      .where((account) => account.isAdmin && account.id != drafter.id)
      .toList();
  if (approvers.isNotEmpty) {
    return approvers;
  }

  return accounts.where((account) => account.id != drafter.id).take(1).toList();
}

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

extension ApprovalIterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
