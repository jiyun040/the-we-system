part of 'approval_step.dart';

_ApprovalStep _$ApprovalStepFromJson(Map<String, dynamic> json) =>
    _ApprovalStep(
      name: json['name'] as String,
      department: json['department'] as String,
      type: json['type'] as String? ?? '결재',
      role: json['role'] as String? ?? '',
      status: json['status'] as String,
      approvedAt: json['approvedAt'] as String?,
      delegatedBy: json['delegatedBy'] as String?,
      requiresOriginalApproval:
          json['requiresOriginalApproval'] as bool? ?? false,
    );

Map<String, dynamic> _$ApprovalStepToJson(_ApprovalStep instance) =>
    <String, dynamic>{
      'name': instance.name,
      'department': instance.department,
      'type': instance.type,
      'role': instance.role,
      'status': instance.status,
      'approvedAt': instance.approvedAt,
      'delegatedBy': instance.delegatedBy,
      'requiresOriginalApproval': instance.requiresOriginalApproval,
    };
