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
      final shared = XmlDocument.parse(
        utf8.decode(out['xl/sharedStrings.xml']!),
      ).findAllElements('si').toList();
      expect(shared[int.parse(cells['N1']!.innerText)].innerText, '분류');
      expect(cells['P3']!.innerText, '테스트 시공사');
      expect(cells['Q3']!.findElements('v').single.innerText, '320');
      expect(cells['J322']!.findElements('v').single.innerText, '960000000');
      expect(
        xml.findAllElements('autoFilter').single.getAttribute('ref'),
        'A1:N321',
      );
      expect(
        xml.findAllElements('pane').single.getAttribute('topLeftCell'),
        'A2',
      );
      expect(
        cells['C2']!.getAttribute('s'),
        isNot(cells['D2']!.getAttribute('s')),
      );
      final columns = xml.findAllElements('cols').single.findElements('col');
      expect(
        columns
            .firstWhere((col) => col.getAttribute('min') == '6')
            .getAttribute('width'),
        '20',
      );
      expect(
        columns
            .firstWhere((col) => col.getAttribute('min') == '7')
            .getAttribute('width'),
        '10',
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

  test('ledger colors only the issuer, billed date, and status cells', () {
    final source = File('assets/templates/ledger.xlsx').readAsBytesSync();
    final entries = items(3);
    final bytes = buildLedgerTemplate(source, [
      entries[0].copyWith(billingDate: DateTime(2026, 10, 12)),
      entries[1].copyWith(status: '진행', category: '가맹'),
      entries[2].copyWith(status: '종료'),
    ], DateTime(2026, 9));
    File('/tmp/sales-ledger-summary-verified.xlsx').writeAsBytesSync(bytes);
    final out = unzip(bytes);
    final sheet = XmlDocument.parse(
      utf8.decode(out['xl/worksheets/sheet1.xml']!),
    );
    final styles = XmlDocument.parse(utf8.decode(out['xl/styles.xml']!));
    final cells = {
      for (final cell in sheet.findAllElements('c'))
        cell.getAttribute('r'): cell,
    };
    final xfs = styles.findAllElements('cellXfs').single.childElements.toList();
    final fills = styles.findAllElements('fills').single.childElements.toList();
    final fonts = styles.findAllElements('fonts').single.childElements.toList();
    String fill(String address) {
      final xf = xfs[int.parse(cells[address]!.getAttribute('s')!)];
      final id = int.parse(xf.getAttribute('fillId')!);
      return fills[id].findAllElements('fgColor').single.getAttribute('rgb')!;
    }

    String font(String address) {
      final xf = xfs[int.parse(cells[address]!.getAttribute('s')!)];
      final id = int.parse(xf.getAttribute('fontId')!);
      return fonts[id].findAllElements('color').single.getAttribute('rgb')!;
    }

    expect(fill('C2'), 'FFCADFF7');
    expect(fill('B2'), 'FFFFFFFF');
    expect(fill('N2'), 'FFFFFFFF');
    expect(fill('B3'), 'FFF4B544');
    expect(fill('N3'), 'FFF4B544');
    expect(fill('D2'), 'FFFFFFFF');
    expect(fill('C3'), 'FFFFFFFF');
    expect(fill('D3'), 'FFDEF0E4');
    expect(fill('G2'), 'FFF9E7AD');
    expect(fill('G3'), 'FFFFFFFF');
    expect(fill('L2'), 'FFBBD6F6');
    expect(fill('L3'), 'FFA8DBB9');
    expect(fill('L4'), 'FFF3BABA');
    for (final address in ['D5', 'G5', 'L5']) {
      expect(fill(address), 'FFFFFFFF');
    }
    expect(font('D3'), 'FF245B39');
    expect(font('B3'), 'FF5C3A00');
    expect(font('G2'), 'FF6D5010');
    expect(cells['P6']!.innerText, '9월 협력사별 집계표');
    expect(cells['P11']!.innerText, '9월 본부, 가맹점 집계표');
    expect(cells['P17']!.innerText, '9월 본부 진행상황');
    expect(cells['P23']!.innerText, '9월 가맹점 진행상황');
    expect(cells['P29']!.innerText, '9월 현장상황');
    expect(cells['Q13']!.findElements('v').single.innerText, '2');
    expect(cells['Q14']!.findElements('v').single.innerText, '1');
    expect(cells['R19']!.findElements('v').single.innerText, '1');
    expect(cells['R20']!.findElements('v').single.innerText, '1');
    expect(cells['R24']!.findElements('v').single.innerText, '1');
    expect(cells['R34']!.findElements('v').single.innerText, '3');
    expect(cells['B34'], isNull);
    expect(cells['P5'], isNull);
    expect(cells['T34'], isNull);
    for (final fontNode in fonts) {
      expect(fontNode.findElements('name').single.getAttribute('val'), 'Arial');
    }
  });
}
