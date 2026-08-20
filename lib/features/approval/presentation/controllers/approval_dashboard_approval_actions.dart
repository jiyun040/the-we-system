import 'package:the_we_system/features/approval/presentation/controllers/approval_controller_models.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_provider_helpers.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';

extension ApprovalDashboardApprovalActions on ApprovalDashboardController {
  Future<void> approveDocument(
    String documentId, {
    required String action,
    required String opinion,
  }) async {
    if (documentId.startsWith('LEAVE-DOC-')) {
      if (usesRemoteApi) {
        await api.actOnLeave(
          documentId.substring('LEAVE-DOC-'.length),
          approve: action != '반려',
        );
        await reloadRemoteState();
        return;
      }
      actOnLeave(
        documentId.substring('LEAVE-DOC-'.length),
        approve: action != '반려',
      );
      return;
    }
    if (usesRemoteApi) {
      final document = await api.actOnDocument(
        documentId,
        approve: action != '반려',
        opinion: opinion,
      );
      replaceApprovalDocument(this, document);
      return;
    }
    final current = currentDashboardState;
    final user = current?.currentUser;
    if (current == null || user == null) {
      return;
    }

    final document = current.documents
        .where((item) => item.id == documentId)
        .firstOrNull;
    if (document == null) {
      return;
    }

    final activeIndex = document.steps.indexWhere(
      (step) => step.status == '진행중',
    );
    if (activeIndex == -1) {
      return;
    }

    final activeStep = document.steps[activeIndex];
    if (!current.hasAdminDocumentAccess && activeStep.name != user.name) {
      return;
    }

    final today = approvalToday();
    final updatedSteps = [...document.steps];
    if (action == '반려') {
      updatedSteps[activeIndex] = activeStep.copyWith(
        status: '반려',
        approvedAt: '$today 09:30',
      );
      final rejectedDocument = document.copyWith(
        status: '반려',
        canCancel: false,
        canEdit: true,
        progress: approvalProgressFor(updatedSteps),
        steps: updatedSteps,
        histories: [
          ApprovalHistory(
            id: 'HIS-REJECT-${document.id}',
            category: '결재문서 변경',
            date: '$today 09:30',
            user: '${user.name} ${user.position}',
            description: opinion.isEmpty ? '반려' : '반려: $opinion',
            snapshot: document.title,
          ),
          ...document.histories,
        ],
      );
      replaceApprovalDocument(this, rejectedDocument);
      return;
    }

    updatedSteps[activeIndex] = activeStep.copyWith(
      status: '완료',
      approvedAt: '$today 09:30',
    );

    final nextIndex = activeIndex + 1;
    var status = '완료';
    if (nextIndex < updatedSteps.length) {
      updatedSteps[nextIndex] = updatedSteps[nextIndex].copyWith(status: '진행중');
      status = '결재대기';
    }

    final completedAfterSubmit = updatedSteps
        .skip(1)
        .where((step) => step.status == '완료')
        .isNotEmpty;

    final approvedDocument = document.copyWith(
      status: status,
      canCancel: !completedAfterSubmit && status != '완료',
      canEdit: false,
      progress: approvalProgressFor(updatedSteps),
      steps: updatedSteps,
      histories: [
        ApprovalHistory(
          id: 'HIS-APPROVE-${document.id}',
          category: '결재문서 변경',
          date: '$today 09:30',
          user: '${user.name} ${user.position}',
          description: opinion.isEmpty ? '승인' : '승인: $opinion',
          snapshot: document.title,
        ),
        ...document.histories,
      ],
    );

    replaceApprovalDocument(this, approvedDocument);
  }

  Future<void> cancelSubmission(String documentId) async {
    if (usesRemoteApi) {
      final document = await api.cancelDocument(documentId);
      replaceApprovalDocument(this, document);
      return;
    }
    final current = currentDashboardState;
    final user = current?.currentUser;
    if (current == null || user == null) {
      return;
    }

    final document = current.documents
        .where((item) => item.id == documentId)
        .firstOrNull;
    if (document == null) {
      return;
    }

    if (!current.hasAdminDocumentAccess && document.drafter != user.name) {
      return;
    }

    if (!document.canCancel) {
      return;
    }

    final hasApprovedFollower = document.steps
        .skip(1)
        .any((step) => step.status == '완료');
    if (hasApprovedFollower) {
      return;
    }

    final reverted = document.copyWith(
      status: '작성중',
      progress: 0,
      receivedRequest: false,
      canCancel: false,
      canEdit: true,
      documentNo: '임시저장',
      steps: buildApprovalStepsFor(
        current.accounts
            .where((account) => account.name == document.drafter)
            .first,
        current.accounts,
      ),
      histories: [
        ApprovalHistory(
          id: 'HIS-CANCEL-${document.id}',
          category: '결재문서 변경',
          date: '${approvalToday()} 09:40',
          user: '${user.name} ${user.position}',
          description: '상신 취소',
          snapshot: document.title,
        ),
        ...document.histories,
      ],
    );
    replaceApprovalDocument(this, reverted);
  }
}
