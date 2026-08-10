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
      return fallbackApprovalDraft;
    }

    final now = approvalToday();
    return ApprovalDocument(
      id: 'DRAFT-$formId',
      title: template.defaultTitle,
      drafter: user.name,
      department: user.department,
      form: template.name,
      status: '작성중',
      draftedAt: now,
      dueDate: now,
      progress: 0,
      documentNo: '임시저장 전',
      effectiveDate: now,
      cooperationDepartment: template.cooperationDepartment,
      agreement: template.agreement,
      content: template.defaultContent,
      urgent: false,
      receivers: template.receivers,
      references: template.references,
      viewers: template.viewers,
      publicReceivers: template.publicReceivers,
      linkedDocuments: const [],
      attachments: const [],
      documentLayout: template.documentLayout,
      lineItems: emptyApprovalLineItems(template),
      steps: buildApprovalStepsFor(user, current.accounts),
      histories: [
        ApprovalHistory(
          id: 'HIS-DRAFT-$formId',
          category: '결재문서 변경',
          date: '$now 09:00',
          user: '${user.name} ${user.position}',
          description: '새 기안 문서를 작성 시작',
          snapshot: template.defaultTitle,
        ),
      ],
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
      return null;
    }

    final currentDocument = documentId == null
        ? null
        : current.documents.where((item) => item.id == documentId).firstOrNull;
    final id = currentDocument?.status == '작성중'
        ? currentDocument!.id
        : nextDraftId(current.documents);
    final now = approvalToday();

    final draft = ApprovalDocument(
      id: id,
      title: title,
      drafter: user.name,
      department: user.department,
      form: template.name,
      status: '작성중',
      draftedAt: template.documentLayout == ApprovalDocumentLayout.hospitality
          ? (formFields['draftedAt']?.trim().isNotEmpty == true
                ? formFields['draftedAt']!.trim()
                : now)
          : currentDocument?.draftedAt ?? now,
      dueDate: now,
      progress: 0,
      documentNo: '임시저장',
      effectiveDate: now,
      cooperationDepartment: template.cooperationDepartment,
      agreement: template.agreement,
      content: content,
      urgent: currentDocument?.urgent ?? false,
      canReuse: true,
      canEdit: true,
      receivers: template.receivers,
      references: template.references,
      viewers: template.viewers,
      publicReceivers: template.publicReceivers,
      linkedDocuments: linkedDocuments,
      attachments: attachments,
      documentLayout: template.documentLayout,
      formFields: formFields,
      lineItems: lineItems,
      steps: buildApprovalStepsFor(user, current.accounts),
      histories: [
        ApprovalHistory(
          id: 'HIS-SAVE-$id',
          category: '결재문서 변경',
          date: '$now 09:10',
          user: '${user.name} ${user.position}',
          description: '임시 저장',
          snapshot: title,
        ),
      ],
    );

    setApprovalDashboardState(this, (value) {
      final documents = [
        ...value.documents.where((item) => item.id != id),
        draft,
      ]..sort((a, b) => b.draftedAt.compareTo(a.draftedAt));
      final restrictedIds = {...value.restrictedDocumentIds};
      if (departmentVisible) {
        restrictedIds.remove(id);
      } else {
        restrictedIds.add(id);
      }
      return value.copyWith(
        documents: documents,
        restrictedDocumentIds: restrictedIds,
      );
    });
    return id;
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
      return null;
    }

    final sourceDocument = documentId == null
        ? null
        : current.documents.where((item) => item.id == documentId).firstOrNull;
    final isEditableDraft = sourceDocument?.status == '작성중';
    final id = isEditableDraft == true
        ? sourceDocument!.id
        : nextApprovalId(current.documents);
    final today = approvalToday();
    final steps = submittedApprovalSteps(user, current.accounts);
    final document = ApprovalDocument(
      id: id,
      title: draft.title,
      drafter: user.name,
      department: user.department,
      form: template.name,
      status: '결재대기',
      draftedAt: draft.documentLayout == ApprovalDocumentLayout.hospitality
          ? (draft.formFields['draftedAt']?.trim().isNotEmpty == true
                ? draft.formFields['draftedAt']!.trim()
                : today)
          : sourceDocument?.draftedAt ?? today,
      dueDate: approvalDueDate(days: 3),
      progress: approvalProgressFor(steps),
      documentNo: id,
      effectiveDate: approvalDueDate(days: 3),
      cooperationDepartment: template.cooperationDepartment,
      agreement: template.agreement,
      content: draft.content,
      urgent: draft.urgent,
      receivedRequest: true,
      canCancel: true,
      canReuse: true,
      canEdit: false,
      receivers: template.receivers,
      references: template.references,
      viewers: template.viewers,
      publicReceivers: template.publicReceivers,
      linkedDocuments: draft.linkedDocuments,
      attachments: draft.attachments,
      documentLayout: draft.documentLayout,
      formFields: draft.formFields,
      lineItems: draft.lineItems,
      steps: steps,
      histories: [
        ApprovalHistory(
          id: 'HIS-REQ-$id',
          category: '결재문서 변경',
          date: '$today 09:20',
          user: '${user.name} ${user.position}',
          description: '결재 요청 상신',
          snapshot: draft.title,
        ),
      ],
    );

    setApprovalDashboardState(this, (value) {
      final documents = [
        ...value.documents.where((item) => item.id != document.id),
        document,
      ]..sort((a, b) => b.draftedAt.compareTo(a.draftedAt));
      final restrictedIds = {...value.restrictedDocumentIds};
      if (draft.departmentVisible) {
        restrictedIds.remove(document.id);
      } else {
        restrictedIds.add(document.id);
      }
      return value.copyWith(
        documents: documents,
        restrictedDocumentIds: restrictedIds,
      );
    });

    return id;
  }
}
