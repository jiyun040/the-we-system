import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_history.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_step.dart';

part 'approval_document.freezed.dart';
part 'approval_document.g.dart';

@freezed
abstract class ApprovalDocument with _$ApprovalDocument {
  const factory ApprovalDocument({
    required String id,
    required String title,
    required String drafter,
    required String department,
    required String form,
    required String status,
    required String draftedAt,
    required String dueDate,
    required int progress,
    @Default('') String documentNo,
    @Default('') String effectiveDate,
    @Default('') String cooperationDepartment,
    @Default('') String agreement,
    @Default('') String content,
    @Default(false) bool urgent,
    @Default(false) bool receivedRequest,
    @Default(false) bool canCancel,
    @Default(true) bool canReuse,
    @Default(true) bool canEdit,
    @Default(<String>[]) List<String> receivers,
    @Default(<String>[]) List<String> references,
    @Default(<String>[]) List<String> viewers,
    @Default(<String>[]) List<String> publicReceivers,
    @Default(<String>[]) List<String> linkedDocuments,
    @Default('basic') String documentLayout,
    @Default(<String, String>{}) Map<String, String> formFields,
    @Default(<Map<String, String>>[]) List<Map<String, String>> lineItems,
    @Default(<ApprovalStep>[]) List<ApprovalStep> steps,
    @Default(<ApprovalHistory>[]) List<ApprovalHistory> histories,
  }) = _ApprovalDocument;

  factory ApprovalDocument.fromJson(Map<String, dynamic> json) =>
      _$ApprovalDocumentFromJson(json);
}
