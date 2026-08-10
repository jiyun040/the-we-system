import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_step.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_document_pdf.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_document_sheet.dart';
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

  testWidgets('상신 문서는 추가 결재 정보 없이 빈 표 행까지 유지한다', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const document = ApprovalDocument(
      id: 'APP-SHEET',
      title: '구매 요청',
      drafter: '홍길동',
      department: '지원팀',
      form: '비품/소모품 구입신청서',
      status: '결재대기',
      draftedAt: '2026-08-07',
      dueDate: '2026-08-10',
      progress: 20,
      documentNo: 'APP-SHEET',
      documentLayout: 'purchase',
      receivers: ['대표'],
      references: ['부서장'],
      viewers: ['직원'],
      cooperationDepartment: '회계팀',
      agreement: '순차합의',
      formFields: {'note': ''},
      lineItems: [
        {
          'date': '2026-08-07',
          'item': '노트북',
          'quantity': '1',
          'amount': '1000000',
          'total': '1000000',
          'remark': '',
        },
        {
          'date': '',
          'item': '',
          'quantity': '',
          'amount': '',
          'total': '',
          'remark': '',
        },
        {
          'date': '',
          'item': '',
          'quantity': '',
          'amount': '',
          'total': '',
          'remark': '',
        },
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ApprovalDocumentSheet(document: document),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('submitted-document-line-2')),
      findsOneWidget,
    );
    expect(find.text('수    신'), findsNothing);
    expect(find.text('참    조'), findsNothing);
    expect(find.text('열 람 자'), findsNothing);
    expect(find.text('협조부서'), findsNothing);
    expect(find.text('합    의'), findsNothing);
    expect(find.text('합    계 (V.A.T 포함)'), findsOneWidget);
  });

  test('상신 문서를 인쇄 가능한 PDF 바이트로 만든다', () async {
    final document = ApprovalDocument(
      id: 'APP-TEST',
      title: '출력 테스트',
      drafter: '홍길동',
      department: '지원팀',
      form: '비품/소모품 구입신청서',
      status: '결재대기',
      draftedAt: '2026-08-06',
      dueDate: '2026-08-09',
      progress: 20,
      documentNo: 'APP-TEST',
      content: '결재 문서 출력 내용',
      documentLayout: 'purchase',
      formFields: const {'note': ''},
      lineItems: List.generate(
        16,
        (_) => const {
          'date': '',
          'item': '',
          'quantity': '',
          'amount': '',
          'total': '',
          'remark': '',
        },
      ),
      steps: const [
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
