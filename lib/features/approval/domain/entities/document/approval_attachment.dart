import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
class ApprovalAttachment {
  const ApprovalAttachment({
    required this.name,
    required this.mimeType,
    required this.base64Data,
  });

  factory ApprovalAttachment.fromBytes({
    required String name,
    required String mimeType,
    required Uint8List bytes,
  }) => ApprovalAttachment(
    name: name,
    mimeType: mimeType,
    base64Data: base64Encode(bytes),
  );

  factory ApprovalAttachment.fromJson(Map<String, dynamic> json) =>
      ApprovalAttachment(
        name: json['name'] as String? ?? '',
        mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
        base64Data: json['base64Data'] as String? ?? '',
      );

  final String name;
  final String mimeType;
  final String base64Data;

  Uint8List get bytes => base64Decode(base64Data);
  int get sizeBytes => bytes.lengthInBytes;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'mimeType': mimeType,
    'base64Data': base64Data,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApprovalAttachment &&
          name == other.name &&
          mimeType == other.mimeType &&
          base64Data == other.base64Data;

  @override
  int get hashCode => Object.hash(name, mimeType, base64Data);
}
