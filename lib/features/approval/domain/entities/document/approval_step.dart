import 'package:freezed_annotation/freezed_annotation.dart';

part 'approval_step.freezed.dart';
part 'approval_step.g.dart';

@freezed
abstract class ApprovalStep with _$ApprovalStep {
  const factory ApprovalStep({
    required String name,
    required String department,
    @Default('결재') String type,
    @Default('') String role,
    required String status,
    String? approvedAt,
    String? delegatedBy,
    @Default(false) bool requiresOriginalApproval,
  }) = _ApprovalStep;

  factory ApprovalStep.fromJson(Map<String, dynamic> json) =>
      _$ApprovalStepFromJson(json);
}
