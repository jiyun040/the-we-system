// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approval_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ApprovalHistory _$ApprovalHistoryFromJson(Map<String, dynamic> json) =>
    _ApprovalHistory(
      id: json['id'] as String,
      category: json['category'] as String,
      date: json['date'] as String,
      user: json['user'] as String,
      description: json['description'] as String,
      snapshot: json['snapshot'] as String? ?? '',
    );

Map<String, dynamic> _$ApprovalHistoryToJson(_ApprovalHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': instance.category,
      'date': instance.date,
      'user': instance.user,
      'description': instance.description,
      'snapshot': instance.snapshot,
    };
