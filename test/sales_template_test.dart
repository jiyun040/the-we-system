import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:the_we_system/features/sales/domain/sales_ledger_entry.dart';
import 'package:the_we_system/features/sales/export/sales_template_workbook.dart';

void main() {
  List<SalesLedgerEntry> items(int count) => List.generate(
    count,
    (i) => SalesLedgerEntry.fromJson({
      'id': '$i',
      'projectName': '테스트 현장',
      'contractor': '테스트 시공사',
      'partner': '테스트 협력사',
      'elevator': '${i + 1}호기',
      'startDate': '2026-09-01',
      'endDate': '2026-09-30',
      'invoiceIssuer': i.isEven ? '시공사' : '협력사',
      'invoiceDate': '2026-10-12',
      'supplyAmount': 3000000,
      'installment': 1,
      'note': '검증용 데이터',
      'category': '본사',
      'status': '신규',
    }),
  );
  Map<String, List<int>> unzip(List<int> bytes) => {
    for (final file in ZipDecoder().decodeBytes(bytes).files)
      file.name: file.content,
  };
  test(
    'ledger retains source layout and styles while replacing records and summary',
    () {
      final source = File('assets/templates/ledger.xlsx').readAsBytesSync();
      final bytes = buildLedgerTemplate(source, items(320), DateTime(2026, 9));
      File('/tmp/sales-ledger-verified.xlsx').writeAsBytesSync(bytes);
      final out = unzip(bytes);
      final xml = XmlDocument.parse(
        utf8.decode(out['xl/worksheets/sheet1.xml']!),
      );
      final cells = {
        for (final c in xml.findAllElements('c')) c.getAttribute('r'): c,
      };
      expect(cells['B2']!.innerText, '테스트 현장');
      expect(cells['N1']!.innerText, '분류');
      expect(cells['P3']!.innerText, '테스트 시공사');
      expect(cells['Q3']!.findElements('v').single.innerText, '320');
      expect(cells['J322']!.findElements('v').single.innerText, '960000000');
      expect(
        xml.findAllElements('pane').single.getAttribute('topLeftCell'),
        'A2',
      );
      expect(
        cells['C2']!.getAttribute('s'),
        isNot(cells['D2']!.getAttribute('s')),
      );
      expect(
        xml.findAllElements('cols').single.toXmlString(),
        XmlDocument.parse(
          utf8.decode(unzip(source)['xl/worksheets/sheet1.xml']!),
        ).findAllElements('cols').single.toXmlString(),
      );
      expect(utf8.decode(out['xl/workbook.xml']!), contains('9월'));
    },
  );
  test(
    'statement preserves images, merges, print layout and paginates all records',
    () {
      final source = File('assets/templates/statement.xlsx').readAsBytesSync();
      final bytes = buildStatementTemplate(
        source,
        SalesStatement(projectName: '테스트 현장', items: items(18)),
        DateTime(2026, 10, 13),
      );
      File('/tmp/sales-statement-verified.xlsx').writeAsBytesSync(bytes);
      final out = unzip(bytes);
      final original = unzip(source);
      expect(out['xl/styles.xml'], original['xl/styles.xml']);
      for (final key in original.keys.where((k) => k.startsWith('xl/media/'))) {
        expect(out[key], original[key]);
      }
      final workbook = XmlDocument.parse(utf8.decode(out['xl/workbook.xml']!));
      expect(workbook.findAllElements('sheet').length, 2);
      final first = XmlDocument.parse(
        utf8.decode(out['xl/worksheets/sheet1.xml']!),
      );
      final second = XmlDocument.parse(
        utf8.decode(out['xl/worksheets/sheet2.xml']!),
      );
      String v(XmlDocument doc, String cell) => doc
          .findAllElements('c')
          .firstWhere((c) => c.getAttribute('r') == cell)
          .findElements('v')
          .single
          .innerText;
      expect(v(first, 'G29'), '56100000');
      expect(v(second, 'G29'), '3300000');
      expect(v(first, 'C10'), '59400000');
      expect(
        first.findAllElements('pane').single.getAttribute('topLeftCell'),
        'A12',
      );
      expect(
        second
            .findAllElements('c')
            .firstWhere((c) => c.getAttribute('r') == 'G13')
            .findElements('v'),
        isEmpty,
      );
      expect(second.findAllElements('row').last.getAttribute('r'), '31');
      expect(
        first.findAllElements('mergeCells').single.toXmlString(),
        XmlDocument.parse(
          utf8.decode(original['xl/worksheets/sheet1.xml']!),
        ).findAllElements('mergeCells').single.toXmlString(),
      );
    },
  );
}
