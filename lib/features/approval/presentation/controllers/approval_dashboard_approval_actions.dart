import 'package:the_we_system/features/approval/presentation/controllers/approval_provider_helpers.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';

extension ApprovalDashboardApprovalActions on ApprovalDashboardController {
  Future<void> approveDocument(
    String documentId, {
    required String action,
    required String opinion,
  }) async {
    try {
      if (documentId.startsWith('LEAVE-DOC-')) {
        await api.actOnLeave(
          documentId.substring('LEAVE-DOC-'.length),
          approve: action != '반려',
        );
        await reloadRemoteState();
        return;
      }
      final document = await api.actOnDocument(
        documentId,
        approve: action != '반려',
        opinion: opinion,
      );
      replaceApprovalDocument(this, document);
    } catch (error) {
      reportOperationError(error, fallback: '결재 처리를 완료하지 못했습니다.');
    }
  }

  Future<void> cancelSubmission(String documentId) async {
    try {
      final document = await api.cancelDocument(documentId);
      replaceApprovalDocument(this, document);
    } catch (error) {
      reportOperationError(error, fallback: '상신 취소를 완료하지 못했습니다.');
    }
  }
}
