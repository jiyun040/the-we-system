part of 'approval_document.dart';

_ApprovalDocument _$ApprovalDocumentFromJson(
  Map<String, dynamic> json,
) => _ApprovalDocument(
  id: json['id'] as String,
  title: json['title'] as String,
  drafter: json['drafter'] as String,
  department: json['department'] as String,
  form: json['form'] as String,
  status: json['status'] as String,
  draftedAt: json['draftedAt'] as String,
  dueDate: json['dueDate'] as String,
  progress: (json['progress'] as num).toInt(),
  documentNo: json['documentNo'] as String? ?? '',
  effectiveDate: json['effectiveDate'] as String? ?? '',
  cooperationDepartment: json['cooperationDepartment'] as String? ?? '',
  agreement: json['agreement'] as String? ?? '',
  content: json['content'] as String? ?? '',
  urgent: json['urgent'] as bool? ?? false,
  receivedRequest: json['receivedRequest'] as bool? ?? false,
  canCancel: json['canCancel'] as bool? ?? false,
  canReuse: json['canReuse'] as bool? ?? true,
  canEdit: json['canEdit'] as bool? ?? true,
  receivers:
      (json['receivers'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  references:
      (json['references'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  viewers:
      (json['viewers'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  publicReceivers:
      (json['publicReceivers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  linkedDocuments:
      (json['linkedDocuments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  steps:
      (json['steps'] as List<dynamic>?)
          ?.map((e) => ApprovalStep.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ApprovalStep>[],
  histories:
      (json['histories'] as List<dynamic>?)
          ?.map((e) => ApprovalHistory.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ApprovalHistory>[],
);

Map<String, dynamic> _$ApprovalDocumentToJson(_ApprovalDocument instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'drafter': instance.drafter,
      'department': instance.department,
      'form': instance.form,
      'status': instance.status,
      'draftedAt': instance.draftedAt,
      'dueDate': instance.dueDate,
      'progress': instance.progress,
      'documentNo': instance.documentNo,
      'effectiveDate': instance.effectiveDate,
      'cooperationDepartment': instance.cooperationDepartment,
      'agreement': instance.agreement,
      'content': instance.content,
      'urgent': instance.urgent,
      'receivedRequest': instance.receivedRequest,
      'canCancel': instance.canCancel,
      'canReuse': instance.canReuse,
      'canEdit': instance.canEdit,
      'receivers': instance.receivers,
      'references': instance.references,
      'viewers': instance.viewers,
      'publicReceivers': instance.publicReceivers,
      'linkedDocuments': instance.linkedDocuments,
      'steps': instance.steps,
      'histories': instance.histories,
    };
