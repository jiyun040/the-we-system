part of 'approval_form.dart';

_ApprovalForm _$ApprovalFormFromJson(Map<String, dynamic> json) =>
    _ApprovalForm(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      recentCount: (json['recentCount'] as num).toInt(),
    );

Map<String, dynamic> _$ApprovalFormToJson(_ApprovalForm instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'recentCount': instance.recentCount,
    };
