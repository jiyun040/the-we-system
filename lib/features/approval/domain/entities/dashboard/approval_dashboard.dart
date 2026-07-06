import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:the_we_system/features/approval/domain/entities/form/approval_form.dart';

part 'approval_dashboard.freezed.dart';
part 'approval_dashboard.g.dart';

@freezed
abstract class ApprovalDashboard with _$ApprovalDashboard {
  const factory ApprovalDashboard({
    required int pendingCount,
    required int receivedCount,
    required int referenceCount,
    required int scheduledCount,
    @Default(<ApprovalForm>[]) List<ApprovalForm> frequentForms,
    @Default(<ApprovalDocument>[]) List<ApprovalDocument> processingDocuments,
    @Default(<ApprovalDocument>[]) List<ApprovalDocument> waitingDocuments,
  }) = _ApprovalDashboard;

  factory ApprovalDashboard.fromJson(Map<String, dynamic> json) =>
      _$ApprovalDashboardFromJson(json);
}
