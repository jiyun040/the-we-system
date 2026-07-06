part of 'approval_providers.dart';

extension ApprovalDashboardDraftActions on ApprovalDashboardController {
  ApprovalDocument buildDraftDocument(String formId) {
    final current = _currentState;
    final user = current?.currentUser;
    final template = current?.formTemplates
        .where((item) => item.id == formId)
        .firstOrNull;
    if (current == null || user == null || template == null) {
      return _fallbackDraft;
    }

    final now = _today();
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
      steps: _buildStepsFor(user, current.accounts),
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
  }) async {
    final current = _currentState;
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
        : _nextDraftId(current.documents);
    final now = _today();

    final draft = ApprovalDocument(
      id: id,
      title: title,
      drafter: user.name,
      department: user.department,
      form: template.name,
      status: '작성중',
      draftedAt: currentDocument?.draftedAt ?? now,
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
      steps: _buildStepsFor(user, current.accounts),
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

    _setDashboardState(this, (value) {
      final documents = [
        ...value.documents.where((item) => item.id != id),
        draft,
      ]..sort((a, b) => b.draftedAt.compareTo(a.draftedAt));
      return value.copyWith(documents: documents);
    });
    return id;
  }

  Future<String?> requestApproval({
    String? documentId,
    required ApprovalRequestDraft draft,
  }) async {
    final current = _currentState;
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
        : _nextApprovalId(current.documents);
    final today = _today();
    final steps = _submitSteps(user, current.accounts);
    final document = ApprovalDocument(
      id: id,
      title: draft.title,
      drafter: user.name,
      department: user.department,
      form: template.name,
      status: '결재대기',
      draftedAt: sourceDocument?.draftedAt ?? today,
      dueDate: _dueDate(days: 3),
      progress: _progressFor(steps),
      documentNo: id,
      effectiveDate: _dueDate(days: 3),
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

    _setDashboardState(this, (value) {
      final documents = [
        ...value.documents.where((item) => item.id != document.id),
        document,
      ]..sort((a, b) => b.draftedAt.compareTo(a.draftedAt));
      return value.copyWith(documents: documents);
    });

    return id;
  }
}
