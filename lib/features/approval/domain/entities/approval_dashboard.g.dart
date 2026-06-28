part of 'approval_dashboard.dart';

_ApprovalDashboard _$ApprovalDashboardFromJson(Map<String, dynamic> json) =>
    _ApprovalDashboard(
      pendingCount: (json['pendingCount'] as num).toInt(),
      receivedCount: (json['receivedCount'] as num).toInt(),
      referenceCount: (json['referenceCount'] as num).toInt(),
      scheduledCount: (json['scheduledCount'] as num).toInt(),
      frequentForms:
          (json['frequentForms'] as List<dynamic>?)
              ?.map((e) => ApprovalForm.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ApprovalForm>[],
      processingDocuments:
          (json['processingDocuments'] as List<dynamic>?)
              ?.map((e) => ApprovalDocument.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ApprovalDocument>[],
      waitingDocuments:
          (json['waitingDocuments'] as List<dynamic>?)
              ?.map((e) => ApprovalDocument.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ApprovalDocument>[],
    );

Map<String, dynamic> _$ApprovalDashboardToJson(_ApprovalDashboard instance) =>
    <String, dynamic>{
      'pendingCount': instance.pendingCount,
      'receivedCount': instance.receivedCount,
      'referenceCount': instance.referenceCount,
      'scheduledCount': instance.scheduledCount,
      'frequentForms': instance.frequentForms,
      'processingDocuments': instance.processingDocuments,
      'waitingDocuments': instance.waitingDocuments,
    };
