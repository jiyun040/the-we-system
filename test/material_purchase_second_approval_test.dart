import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:the_we_system/features/approval/presentation/pages/approval/approval_detail_page.dart';

void main() {
  const approved = ApprovalDocument(
    id: 'APR-1',
    title: '자재',
    drafter: '기안자',
    department: '공무팀',
    form: '자재구매신청서',
    status: '완료',
    draftedAt: '2026-11-11',
    dueDate: '2026-11-11',
    progress: 100,
  );

  test('1차 승인 후 기안자만 사진을 바꾸고 2차 요청 후에는 잠긴다', () {
    expect(canUpdateMaterialPhotos(approved, '기안자'), isTrue);
    expect(canUpdateMaterialPhotos(approved, '다른 사람'), isFalse);
    expect(
      canUpdateMaterialPhotos(
        approved.copyWith(
          status: '결재대기',
          formFields: const {'_materialApprovalStage': 'second_pending'},
        ),
        '기안자',
      ),
      isFalse,
    );
    expect(
      canUpdateMaterialPhotos(
        approved.copyWith(
          formFields: const {'_materialApprovalStage': 'complete'},
        ),
        '기안자',
      ),
      isFalse,
    );
  });
}
