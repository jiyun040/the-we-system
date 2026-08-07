import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_step.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_document_pdf.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_input_formatters.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('결재 날짜와 금액을 포맷하고 수량은 숫자만 허용한다', () {
    const dateFormatter = ApprovalDateInputFormatter();
    final amountFormatter = ApprovalAmountInputFormatter();
    const digitsFormatter = ApprovalDigitsInputFormatter();

    expect(
      dateFormatter
          .formatEditUpdate(
            TextEditingValue.empty,
            const TextEditingValue(text: '20260806'),
          )
          .text,
      '2026-08-06',
    );
    expect(
      amountFormatter
          .formatEditUpdate(
            TextEditingValue.empty,
            const TextEditingValue(text: '1234567'),
          )
          .text,
      '1,234,567',
    );
    expect(
      digitsFormatter
          .formatEditUpdate(
            TextEditingValue.empty,
            const TextEditingValue(text: '12개A3'),
          )
          .text,
      '123',
    );
  });

  test('상신 문서를 인쇄 가능한 PDF 바이트로 만든다', () async {
    const document = ApprovalDocument(
      id: 'APP-TEST',
      title: '출력 테스트',
      drafter: '홍길동',
      department: '지원팀',
      form: '업무기안[기본양식]',
      status: '결재대기',
      draftedAt: '2026-08-06',
      dueDate: '2026-08-09',
      progress: 20,
      documentNo: 'APP-TEST',
      content: '결재 문서 출력 내용',
      steps: [
        ApprovalStep(
          name: '홍길동',
          department: '지원팀',
          type: '신청',
          role: '대리',
          status: '완료',
        ),
        ApprovalStep(
          name: '김대표',
          department: '경영팀',
          type: '승인',
          role: '대표',
          status: '진행중',
        ),
      ],
    );

    final bytes = await buildApprovalDocumentPdf(document);
    expect(bytes.length, greaterThan(100));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
