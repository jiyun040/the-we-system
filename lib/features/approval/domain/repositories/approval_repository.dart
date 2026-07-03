import 'package:the_we_system/features/approval/domain/entities/dashboard/approval_dashboard.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';

abstract interface class ApprovalRepository {
  Future<ApprovalDashboard> fetchDashboard();

  Future<ApprovalDocument> fetchDocument(String id);

  Future<void> approveDocument(String id);
}
