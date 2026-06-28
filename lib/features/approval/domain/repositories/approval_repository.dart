import 'package:the_we_system/features/approval/domain/entities/approval_dashboard.dart';
import 'package:the_we_system/features/approval/domain/entities/approval_document.dart';

abstract interface class ApprovalRepository {
  Future<ApprovalDashboard> fetchDashboard();

  Future<ApprovalDocument> fetchDocument(String id);

  Future<void> approveDocument(String id);
}
