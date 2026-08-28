import 'package:the_we_system/features/approval/presentation/controllers/approval_provider_helpers.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';

extension ApprovalDashboardApprovalActions on ApprovalDashboardController {
  Future<void> approveDocument(
    String documentId, {
    required String action,
    required String opinion,
  }) async {
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
  }

  Future<void> cancelSubmission(String documentId) async {
    final document = await api.cancelDocument(documentId);
    replaceApprovalDocument(this, document);
  }
}
