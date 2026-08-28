import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_attachment.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';

void main() {
  test('결재 문서 직렬화 후에도 첨부파일 원본 바이트를 유지한다', () {
    final originalBytes = Uint8List.fromList(<int>[
      0x25,
      0x50,
      0x44,
      0x46,
      0x2D,
      0x31,
      0x2E,
      0x34,
      0x0A,
      0x25,
      0x45,
      0x4F,
      0x46,
    ]);
    final attachment = ApprovalAttachment.fromBytes(
      name: '결재 시스템 테스트 파일.pdf',
      mimeType: 'application/pdf',
      bytes: originalBytes,
    );
    final document = ApprovalDocument(
      id: 'APR-TEST',
      title: '첨부 테스트',
      drafter: '교육관리자',
      department: '교육관리팀',
      form: '기본 기안서',
      status: '작성중',
      draftedAt: '2026-08-03',
      dueDate: '2026-08-06',
      progress: 0,
      attachments: <ApprovalAttachment>[attachment],
    );

    final restored = ApprovalDocument.fromJson(
      jsonDecode(jsonEncode(document.toJson())) as Map<String, dynamic>,
    );

    expect(restored.attachments, hasLength(1));
    expect(restored.attachments.single.name, attachment.name);
    expect(restored.attachments.single.mimeType, 'application/pdf');
    expect(restored.attachments.single.bytes, orderedEquals(originalBytes));
  });
}
