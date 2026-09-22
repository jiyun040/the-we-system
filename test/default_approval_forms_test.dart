import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_default_forms.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';

void main() {
  test('서버에서 받은 양식만 표시한다', () {
    const customizedBusinessDraft = ApprovalFormTemplate(
      id: 'business-draft',
      category: '커스텀 분류',
      name: '내가 수정한 업무기안',
      description: '사용자 설정 유지',
      defaultTitle: '커스텀 제목',
      defaultContent: '커스텀 본문',
      receivers: ['대표이사'],
      references: [],
      viewers: [],
      publicReceivers: [],
      cooperationDepartment: '기술부',
      agreement: '사용자 합의 설정',
      lineItemRows: 20,
    );
    const customForm = ApprovalFormTemplate(
      id: 'my-custom-form',
      category: '사용자 정의',
      name: '내 커스텀 양식',
      description: '직접 만든 양식',
      defaultTitle: '직접 만든 제목',
      defaultContent: '직접 만든 본문',
      receivers: [],
      references: [],
      viewers: [],
      publicReceivers: [],
      cooperationDepartment: '',
      agreement: '',
    );

    final merged = mergeApprovalFormTemplates(const [
      customizedBusinessDraft,
      customForm,
    ]);

    expect(merged, hasLength(2));
    expect(
      merged.where((form) => form.id == 'business-draft').single.name,
      '내가 수정한 업무기안',
    );
    expect(merged.where((form) => form.id == 'my-custom-form'), hasLength(1));
    expect(
      merged.map((form) => form.id),
      isNot(contains('material-purchase-request')),
    );
    final materialPurchase = approvalDefaultFormTemplates
        .where((form) => form.id == 'material-purchase-request')
        .single;
    expect(materialPurchase.name, '자재구매신청서');
    expect(materialPurchase.cooperationDepartment, '공무팀');
    expect(materialPurchase.documentLayout, ApprovalDocumentLayout.purchase);
    expect(materialPurchase.lineItemRows, 16);
    expect(materialPurchase.approvalLines, hasLength(1));
    expect(materialPurchase.approvalLines.single.userIds, ['김현정']);
  });
}
