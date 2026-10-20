import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../domain/sales_ledger_entry.dart';
import '../domain/sales_statement_notes.dart';
import '../export/sales_template_workbook.dart';

// A4 coordinates calibrated from the supplied worksheet's printed cell bounds.
// The background is the blank source worksheet including its original drawings.
class StatementText {
  const StatementText(
    this.text,
    this.x,
    this.y,
    this.width,
    this.height, {
    this.size = 6.88,
    this.right = false,
    this.center = false,
    this.bold = true,
    this.red = false,
  });
  final String text;
  final double x, y, width, height, size;
  final bool right, center, bold, red;
}

List<StatementText> statementPageText(
  SalesStatement statement,
  int page,
  DateTime issued,
) {
  final output = <StatementText>[];
  final first = statement.items.firstOrNull;
  final money = NumberFormat('#,##0');
  final all = statement.items.fold<int>(
    0,
    (s, e) => s + e.supplyAmount + (e.supplyAmount * .1).round(),
  );
  output.addAll([
    StatementText(
      first == null
          ? ''
          : first.invoiceIssuerType == '시공사'
          ? first.contractor
          : first.partner,
      121.4,
      138.5,
      139.1,
      25.8,
      size: 8.6,
    ),
    StatementText(statement.projectName, 121.4, 190.1, 139.1, 25.8, size: 7.74),
    StatementText(
      DateFormat('yyyy-MM-dd').format(issued),
      317.3,
      245.97,
      59.17,
      20,
      size: 7.8,
      center: true,
    ),
    StatementText(
      money.format(all),
      260.5,
      265.96,
      116,
      20,
      size: 10,
      right: true,
    ),
  ]);
  const xs = [
    37.64,
    121.402,
    260.503,
    288.903,
    317.303,
    376.469,
    435.634,
    494.799,
    553.964,
  ];
  var supply = 0, tax = 0, count = 0;
  for (var i = 0; i < 17; i++) {
    final index = page * 17 + i;
    if (index >= statement.items.length) break;
    final item = statement.items[index];
    final vat = (item.supplyAmount * .1).round();
    supply += item.supplyAmount;
    tax += vat;
    count++;
    final values = [
      '${index + 1}. PDAM시스템 공급',
      '${item.elevator} ${item.installment}회 : ${salesPeriod(item)}',
      'SET',
      '1',
      money.format(item.supplyAmount),
      money.format(vat),
      money.format(item.supplyAmount + vat),
      statementItemNote(item),
    ];
    for (var c = 0; c < 8; c++) {
      output.add(
        StatementText(
          values[c],
          xs[c],
          303.234 + i * 18.8685,
          xs[c + 1] - xs[c] - 2,
          18.8685,
          center: c >= 1 && c <= 6,
          red: c == 7,
          bold: c != 7,
        ),
      );
    }
  }
  final totals = [
    '$count',
    money.format(supply),
    money.format(tax),
    money.format(supply + tax),
  ];
  for (var c = 3; c <= 6; c++) {
    output.add(
      StatementText(
        totals[c - 3],
        xs[c],
        623.999,
        xs[c + 1] - xs[c] - 2,
        21.44,
        right: true,
        size: 8.6,
      ),
    );
  }
  final footerNotes = statementFooterNotes(
    statement.items.skip(page * 17).take(17),
  );
  if (footerNotes.isNotEmpty) {
    final lines = [...footerNotes, statementBankNote];
    for (var i = 0; i < lines.length; i++) {
      output.add(
        StatementText(
          lines[i],
          121.4,
          646.5 + i * 8.1,
          429,
          8.1,
          size: 6.2,
          bold: false,
        ),
      );
    }
  }
  return output;
}

class SalesStatementPreview extends StatelessWidget {
  const SalesStatementPreview({
    super.key,
    required this.statement,
    required this.issued,
  });
  final SalesStatement statement;
  final DateTime issued;
  @override
  Widget build(BuildContext context) {
    final pages = statement.items.isEmpty
        ? 1
        : (statement.items.length / 17).ceil();
    if (MediaQuery.sizeOf(context).width < 520) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final pageHeight = (constraints.maxWidth * 841.89 / 595.28).clamp(
            0.0,
            constraints.maxHeight,
          );
          return SingleChildScrollView(
            child: Column(
              children: [
                for (var page = 0; page < pages; page++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: pageHeight,
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 5,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: _page(page, pages),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            for (var page = 0; page < pages; page++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  width: 830,
                  height: 1174,
                  child: FittedBox(child: _page(page, pages)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _page(int page, int pages) => SizedBox(
    width: 595.28,
    height: 841.89,
    child: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/templates/statement-background.png',
            fit: BoxFit.fill,
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          top: 800,
          bottom: 0,
          child: ColoredBox(color: Colors.white),
        ),
        if (statementFooterNotes(
          statement.items.skip(page * 17).take(17),
        ).isNotEmpty)
          const Positioned(
            left: 121,
            top: 645,
            width: 431,
            height: 35,
            child: ColoredBox(color: Color(0xFFEAF0DF)),
          ),
        for (final t in statementPageText(
          statement,
          page,
          issued,
        ).where((t) => t.text.isNotEmpty))
          Positioned(
            left: t.x,
            top: t.y,
            width: t.width,
            height: t.height,
            child: Align(
              alignment: t.right
                  ? Alignment.centerRight
                  : t.center
                  ? Alignment.center
                  : Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  t.text,
                  style: TextStyle(
                    fontSize: t.size,
                    color: t.red ? Colors.red : Colors.black,
                    fontWeight: t.bold ? FontWeight.bold : FontWeight.normal,
                    fontFamily: 'SUIT-Variable',
                  ),
                ),
              ),
            ),
          ),
        if (pages > 1)
          Positioned(
            left: 500,
            top: 780,
            child: Text(
              '${page + 1}/$pages',
              style: const TextStyle(fontSize: 9),
            ),
          ),
      ],
    ),
  );
}

Future<Uint8List> statementTemplatePdf(SalesStatement statement) async {
  final background = pw.MemoryImage(
    (await rootBundle.load(
      'assets/templates/statement-background.png',
    )).buffer.asUint8List(),
  );
  final font = pw.Font.ttf(
    await rootBundle.load('assets/fonts/SUIT-Medium.ttf'),
  );
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/SUIT-Bold.ttf'));
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: font, bold: bold),
  );
  final pages = statement.items.isEmpty
      ? 1
      : (statement.items.length / 17).ceil();
  final now = DateTime.now();
  for (var page = 0; page < pages; page++) {
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Stack(
          children: [
            pw.Positioned.fill(
              child: pw.Image(background, fit: pw.BoxFit.fill),
            ),
            pw.Positioned(
              left: 0,
              right: 0,
              top: 800,
              bottom: 0,
              child: pw.Container(color: PdfColors.white),
            ),
            if (statementFooterNotes(
              statement.items.skip(page * 17).take(17),
            ).isNotEmpty)
              pw.Positioned(
                left: 121,
                top: 645,
                child: pw.Container(
                  width: 431,
                  height: 35,
                  color: PdfColor.fromInt(0xFFEAF0DF),
                ),
              ),
            for (final t in statementPageText(
              statement,
              page,
              now,
            ).where((t) => t.text.isNotEmpty))
              pw.Positioned(
                left: t.x,
                top: t.y,
                child: pw.SizedBox(
                  width: t.width,
                  height: t.height,
                  child: pw.Align(
                    alignment: t.right
                        ? pw.Alignment.centerRight
                        : t.center
                        ? pw.Alignment.center
                        : pw.Alignment.centerLeft,
                    child: pw.FittedBox(
                      fit: pw.BoxFit.scaleDown,
                      child: pw.Text(
                        t.text,
                        style: pw.TextStyle(
                          fontSize: t.size,
                          color: t.red ? PdfColors.red : PdfColors.black,
                          fontWeight: t.bold
                              ? pw.FontWeight.bold
                              : pw.FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (pages > 1)
              pw.Positioned(
                left: 500,
                top: 780,
                child: pw.Text(
                  '${page + 1}/$pages',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
          ],
        ),
      ),
    );
  }
  return doc.save();
}
