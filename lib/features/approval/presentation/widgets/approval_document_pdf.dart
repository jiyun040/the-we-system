import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:the_we_system/common/components/the_we_snack_bar.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_step.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_input_formatters.dart';

Future<void> exportApprovalDocumentPdf(
  BuildContext context,
  ApprovalDocument document,
) async {
  try {
    final bytes = await buildApprovalDocumentPdf(document);
    final rawName = document.title.trim().isEmpty
        ? document.form
        : document.title;
    final fileName = rawName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    await FileSaver.instance.saveFile(
      name: '${document.documentNo}_$fileName',
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
    if (context.mounted) {
      showTheWeSnackBar(context, message: '결재 문서를 PDF로 저장했습니다.');
    }
  } catch (error, stackTrace) {
    debugPrint('approval-pdf: $error\n$stackTrace');
    if (context.mounted) {
      showTheWeSnackBar(
        context,
        message: 'PDF를 만들지 못했습니다. 다시 시도해 주세요.',
        type: TheWeSnackBarType.error,
      );
    }
  }
}

Future<Uint8List> buildApprovalDocumentPdf(ApprovalDocument document) async {
  final fontData = await _loadPdfFont('assets/fonts/SUIT-Medium.ttf');
  final boldFontData = await _loadPdfFont('assets/fonts/SUIT-Bold.ttf');
  final font = pw.Font.ttf(fontData);
  final boldFont = pw.Font.ttf(boldFontData);
  final pdf = pw.Document();
  final baseTheme = pw.ThemeData.withFont(base: font, bold: boldFont);
  const baseText = pw.TextStyle(color: PdfColors.black);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      theme: baseTheme.copyWith(
        defaultTextStyle: baseText,
        paragraphStyle: baseText,
        tableHeader: baseText,
        tableCell: baseText,
      ),
      build: (_) => _buildDocument(document),
    ),
  );
  return pdf.save();
}

Future<ByteData> _loadPdfFont(String assetPath) async {
  try {
    return await rootBundle.load(assetPath);
  } catch (error, stackTrace) {
    debugPrint('approval-pdf-font-fallback: $error\n$stackTrace');
    return rootBundle.load('assets/fonts/SUIT-Variable.ttf');
  }
}

List<pw.Widget> _buildDocument(ApprovalDocument document) {
  final widgets = <pw.Widget>[
    pw.Text(
      _sheetTitle(document),
      style: pw.TextStyle(
        color: PdfColors.black,
        fontSize: 22,
        fontWeight: pw.FontWeight.bold,
      ),
      textAlign: pw.TextAlign.center,
    ),
    pw.SizedBox(height: 18),
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 5,
          child: _infoTable([
            ('문서번호', document.documentNo),
            ('작성일', document.draftedAt),
            ('작성부서', document.department),
            ('작성자', document.drafter),
          ]),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(flex: 6, child: _approvalLine(document.steps)),
      ],
    ),
    pw.SizedBox(height: 14),
    if (document.documentLayout == 'payroll') _wideRow('제목', document.title),
  ];

  if (document.documentLayout == 'payroll') {
    widgets.add(_wideRow('참조', document.formFields['reference'] ?? '-'));
  }

  if (document.documentLayout == 'basic' ||
      document.documentLayout == 'payroll') {
    widgets.addAll([
      _sectionHeader('상 세 내 용'),
      pw.Container(
        width: double.infinity,
        constraints: pw.BoxConstraints(
          minHeight: document.documentLayout == 'basic' ? 320 : 250,
        ),
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: .8),
        ),
        child: pw.Text(
          document.content.isEmpty ? '-' : document.content,
          style: const pw.TextStyle(
            color: PdfColors.black,
            fontSize: 11,
            lineSpacing: 3,
          ),
        ),
      ),
    ]);
    return widgets;
  }

  final columns = _columnsFor(document.documentLayout);
  final columnFlex = columns.fold<int>(0, (sum, column) => sum + column.$3);
  widgets.add(
    _flexWideRow(
      '비고',
      document.formFields['note'] ?? '-',
      labelFlex: columns.first.$3,
      valueFlex: columnFlex - columns.first.$3,
    ),
  );
  final rows = document.lineItems
      .map(
        (item) => columns
            .map((column) => _displayCell(column.$1, item[column.$1] ?? ''))
            .toList(),
      )
      .toList();
  widgets.add(
    pw.TableHelper.fromTextArray(
      headers: columns.map((column) => column.$2).toList(),
      data: rows,
      headerStyle: pw.TextStyle(
        color: PdfColors.black,
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
      ),
      cellStyle: const pw.TextStyle(color: PdfColors.black, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      border: pw.TableBorder.all(color: PdfColors.black, width: .8),
      columnWidths: {
        for (var index = 0; index < columns.length; index++)
          index: pw.FlexColumnWidth(columns[index].$3.toDouble()),
      },
    ),
  );
  widgets.add(
    _flexWideRow(
      '합계',
      _totalAmount(document),
      labelFlex: columnFlex - columns.last.$3,
      valueFlex: columns.last.$3,
    ),
  );
  widgets.addAll([
    pw.SizedBox(height: 18),
    pw.Text(
      '위 금액을 청구하오니 결재하여 주시기 바랍니다.',
      style: const pw.TextStyle(color: PdfColors.black, fontSize: 10),
      textAlign: pw.TextAlign.center,
    ),
    pw.SizedBox(height: 18),
    pw.Text(
      '우리기술 주식회사',
      style: pw.TextStyle(
        color: PdfColors.black,
        fontWeight: pw.FontWeight.bold,
      ),
      textAlign: pw.TextAlign.center,
    ),
  ]);
  return widgets;
}

pw.Widget _approvalLine(List<ApprovalStep> steps) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
  children: [
    _sectionHeader('결재 라인'),
    pw.Row(
      children: steps.take(4).map((step) {
        final result = step.status == '완료'
            ? '승인'
            : step.status == '반려'
            ? '반려'
            : step.status;
        return pw.Expanded(
          child: pw.Container(
            height: 72,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: .8),
            ),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Text(
                  step.role.isEmpty ? step.type : step.role,
                  style: const pw.TextStyle(
                    color: PdfColors.black,
                    fontSize: 8,
                  ),
                ),
                pw.Text(
                  step.name,
                  style: const pw.TextStyle(
                    color: PdfColors.black,
                    fontSize: 9,
                  ),
                ),
                pw.Text(
                  result,
                  style: const pw.TextStyle(
                    color: PdfColors.black,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  ],
);

pw.Widget _infoTable(List<(String, String)> rows) =>
    pw.Column(children: rows.map((row) => _wideRow(row.$1, row.$2)).toList());

pw.Widget _wideRow(String label, String value) => pw.Table(
  border: pw.TableBorder.all(color: PdfColors.black, width: .8),
  defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
  columnWidths: const {0: pw.FixedColumnWidth(70), 1: pw.FlexColumnWidth()},
  children: [
    pw.TableRow(
      children: [
        pw.Container(
          color: PdfColors.grey200,
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              color: PdfColors.black,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            value.trim().isEmpty ? '-' : value,
            style: const pw.TextStyle(color: PdfColors.black, fontSize: 10),
          ),
        ),
      ],
    ),
  ],
);

pw.Widget _flexWideRow(
  String label,
  String value, {
  required int labelFlex,
  required int valueFlex,
}) => pw.Table(
  border: pw.TableBorder.all(color: PdfColors.black, width: .8),
  defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
  columnWidths: {
    0: pw.FlexColumnWidth(labelFlex.toDouble()),
    1: pw.FlexColumnWidth(valueFlex.toDouble()),
  },
  children: [
    pw.TableRow(
      children: [
        pw.Container(
          color: PdfColors.grey200,
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          child: pw.Text(
            label,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              color: PdfColors.black,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          child: pw.Text(
            value.trim().isEmpty ? '-' : value,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              color: PdfColors.black,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  ],
);

pw.Widget _sectionHeader(String title) => pw.Container(
  width: double.infinity,
  alignment: pw.Alignment.center,
  padding: const pw.EdgeInsets.all(6),
  decoration: pw.BoxDecoration(
    color: PdfColors.grey200,
    border: pw.Border.all(color: PdfColors.black, width: .8),
  ),
  child: pw.Text(
    title,
    style: pw.TextStyle(
      color: PdfColors.black,
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
    ),
  ),
);

List<(String, String, int)> _columnsFor(String layout) => switch (layout) {
  'hospitality' => const [
    ('date', '결제일', 2),
    ('customer', '이용 가맹점명', 3),
    ('place', '접대처', 3),
    ('attendees', '참석 인원', 4),
    ('amount', '금액', 2),
  ],
  'purchase' => const [
    ('date', '날짜', 2),
    ('item', '내용', 3),
    ('quantity', '수량', 2),
    ('amount', '금액', 2),
    ('total', '합계금액', 2),
    ('remark', '비고', 3),
  ],
  _ => const [
    ('date', '입금일', 2),
    ('item', '항목', 3),
    ('purpose', '적요', 6),
    ('amount', '금액', 2),
  ],
};

String _displayCell(String key, String value) {
  if (key == 'amount' || key == 'total') return formatApprovalAmount(value);
  return value;
}

String _totalAmount(ApprovalDocument document) {
  final total = calculateApprovalLineItemsTotal(document.lineItems);
  return total.isEmpty ? '-' : '${formatApprovalAmount(total)}원';
}

String _sheetTitle(ApprovalDocument document) =>
    switch (document.documentLayout) {
      'expense' => '지출결의서(지급품의)',
      'hospitality' => '지출결의서(기업업무추진비)',
      'purchase' => '비품/소모품 구입신청서',
      'payroll' => '급여대장 기안서',
      _ when document.form.contains('협조') => '업 무 협 조',
      _ when document.form.contains('휴가') => '휴 가 신 청',
      _ => '업 무 기 안',
    };
