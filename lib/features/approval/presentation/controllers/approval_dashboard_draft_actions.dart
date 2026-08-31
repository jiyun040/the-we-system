import 'package:the_we_system/features/approval/presentation/controllers/approval_controller_models.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_provider_helpers.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';

extension ApprovalDashboardDraftActions on ApprovalDashboardController {
  ApprovalDocument buildDraftDocument(String formId) {
    final current = currentDashboardState;
    final user = current?.currentUser;
    final template = current?.formTemplates
        .where((item) => item.id == formId)
        .firstOrNull;
    if (current == null || user == null || template == null) {
      throw StateError('서버에서 기안 양식 또는 사용자 정보를 불러오지 못했습니다.');
    }

    final now = approvalToday();
    return ApprovalDocument(
      id: '',
      title: template.defaultTitle,
      drafter: user.name,
      department: user.department,
      form: template.name,
      status: '작성중',
      draftedAt: now,
      dueDate: now,
      progress: 0,
      documentNo: '',
      effectiveDate: now,
      cooperationDepartment: template.cooperationDepartment,
      agreement: template.agreement,
      content: template.defaultContent,
      receivers: template.receivers,
      references: template.references,
      viewers: template.viewers,
      publicReceivers: template.publicReceivers,
      documentLayout: template.documentLayout,
      lineItems: emptyApprovalLineItems(template),
      steps: buildApprovalStepsFor(user, current.accounts),
      histories: const [],
    );
  }

  Future<String?> saveDraft({
    required String formId,
    String? documentId,
    required String title,
    required String content,
    required List<String> linkedDocuments,
    List<ApprovalAttachment> attachments = const <ApprovalAttachment>[],
    required bool departmentVisible,
    required Map<String, String> formFields,
    required List<Map<String, String>> lineItems,
  }) async {
    final current = currentDashboardState;
    final user = current?.currentUser;
    final template = current?.formTemplates
        .where((item) => item.id == formId)
        .firstOrNull;
    if (current == null || user == null || template == null) {
      reportOperationError(
        StateError('draft_state_unavailable'),
        fallback: '기안 정보를 불러오지 못했습니다. 다시 시도해 주세요.',
      );
      return null;
    }

    final currentDocument = documentId == null
        ? null
        : current.documents.where((item) => item.id == documentId).firstOrNull;
    final request = ApprovalRequestDraft(
      formId: formId,
      title: title,
      content: content,
      urgent: currentDocument?.urgent ?? false,
      linkedDocuments: linkedDocuments,
      attachments: attachments,
      departmentVisible: departmentVisible,
      documentLayout: template.documentLayout,
      formFields: formFields,
      lineItems: lineItems,
    );
    final steps = _remoteSteps(
      buildApprovalStepsFor(user, current.accounts),
      current.accounts,
    );
    try {
      final saved = currentDocument?.status == '작성중'
          ? await api.updateDraft(
              currentDocument!.id,
              draft: request,
              steps: steps,
            )
          : await api.createDraft(draft: request, steps: steps);
      _replaceRemoteDocument(this, documentId, saved, departmentVisible);
      return saved.id;
    } catch (error) {
      reportOperationError(error, fallback: '임시 저장을 완료하지 못했습니다.');
      return null;
    }
  }

  Future<String?> requestApproval({
    String? documentId,
    required ApprovalRequestDraft draft,
  }) async {
    final current = currentDashboardState;
    final user = current?.currentUser;
    final template = current?.formTemplates
        .where((item) => item.id == draft.formId)
        .firstOrNull;
    if (current == null || user == null || template == null) {
      reportOperationError(
        StateError('approval_state_unavailable'),
        fallback: '결재 요청 정보를 불러오지 못했습니다. 다시 시도해 주세요.',
      );
      return null;
    }

    final sourceDocument = documentId == null
        ? null
        : current.documents.where((item) => item.id == documentId).firstOrNull;
    final steps = _remoteSteps(
      buildApprovalStepsFor(user, current.accounts),
      current.accounts,
    );
    try {
      final saved = sourceDocument?.status == '작성중'
          ? await api.updateDraft(
              sourceDocument!.id,
              draft: draft,
              steps: steps,
            )
          : await api.createDraft(draft: draft, steps: steps);
      final submitted = await api.submitDocument(saved.id);
      _replaceRemoteDocument(
        this,
        documentId ?? saved.id,
        submitted,
        draft.departmentVisible,
      );
      return submitted.id;
    } catch (error) {
      reportOperationError(error, fallback: '결재 요청을 완료하지 못했습니다.');
      return null;
    }
  }
}

List<Map<String, dynamic>> _remoteSteps(
  List<ApprovalStep> steps,
  List<EmployeeAccount> accounts,
) => steps.map((step) {
  final approver = accounts
      .where((account) => account.name == step.name)
      .firstOrNull;
  return <String, dynamic>{
    if (approver != null) 'approverId': approver.id,
    'name': step.name,
    'department': step.department,
    'type': step.type,
    'role': step.role,
    'status': step.status,
    'approvedAt': step.approvedAt,
    'delegatedBy': step.delegatedBy,
    'requiresOriginalApproval': step.requiresOriginalApproval,
  };
}).toList();

void _replaceRemoteDocument(
  ApprovalDashboardController controller,
  String? previousId,
  ApprovalDocument document,
  bool departmentVisible,
) {
  setApprovalDashboardState(controller, (current) {
    final documents = [
      ...current.documents.where(
        (item) => item.id != previousId && item.id != document.id,
      ),
      document,
    ]..sort((a, b) => b.draftedAt.compareTo(a.draftedAt));
    final restricted = {...current.restrictedDocumentIds}
      ..remove(previousId)
      ..remove(document.id);
    if (!departmentVisible) restricted.add(document.id);
    return current.copyWith(
      documents: documents,
      restrictedDocumentIds: restricted,
    );
  });
}
