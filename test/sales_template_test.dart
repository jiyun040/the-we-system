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

  test(
    'statement shows short usage and standard notices without private notes',
    () {
      final source = File('assets/templates/statement.xlsx').readAsBytesSync();
      final short = items(1).single.copyWith(
        endDate: DateTime(2026, 9, 28),
        note: '서비스에서만 보이는 메모',
        adjustmentAmount: 100000,
      );
      final bytes = buildStatementTemplate(
        source,
        SalesStatement(projectName: '테스트 현장', items: [short]),
        DateTime(2026, 10, 13),
      );
      File('/tmp/short-statement.xlsx').writeAsBytesSync(bytes);
      final sheet = XmlDocument.parse(
        utf8.decode(unzip(bytes)['xl/worksheets/sheet1.xml']!),
      );
      final cells = {
        for (final cell in sheet.findAllElements('c'))
          cell.getAttribute('r'): cell,
      };
      expect(cells['H12']!.innerText, '28일');
      expect(cells['C30']!.innerText, contains('1일 임대로 16만원'));
      expect(cells['C30']!.innerText, contains('1개월분으로 계산하였습니다'));
      expect(cells['C30']!.innerText, contains('네고된 사항입니다'));
      expect(sheet.toXmlString(), isNot(contains('서비스에서만 보이는 메모')));
    },
  );

  test('ledger export keeps existing and new equipment together by site', () {
    final source = File('assets/templates/ledger.xlsx').readAsBytesSync();
    SalesLedgerEntry entry(
      String site,
      String device,
      String status,
      String category,
    ) => SalesLedgerEntry.fromJson({
      'id': '$site-$device',
      'projectName': site,
      'elevator': device,
      'startDate': '2026-10-01',
      'status': status,
      'category': category,
    });
    final bytes = buildLedgerTemplate(source, [
      entry('가 현장', '2호기', '신규', '본사'),
      entry('나 현장', '1호기', '진행', '본사'),
      entry('가 현장', '1호기', '종료', '본사'),
      entry('가 현장', '3호기', '진행', '가맹'),
    ], DateTime(2026, 10));
    final sheet = XmlDocument.parse(
      utf8.decode(unzip(bytes)['xl/worksheets/sheet1.xml']!),
    );
    final cells = {
      for (final cell in sheet.findAllElements('c'))
        cell.getAttribute('r'): cell,
    };
    expect(
      [for (var row = 2; row <= 5; row++) cells['E$row']!.innerText],
      ['1호기', '2호기', '1호기', '3호기'],
    );
    expect(
      [for (var row = 2; row <= 5; row++) cells['L$row']!.innerText],
      ['종료', '신규', '진행', '진행'],
    );
  });

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
    expect(fill('B4'), 'FFF4B544');
    expect(fill('N4'), 'FFF4B544');
    expect(fill('D2'), 'FFFFFFFF');
    expect(fill('C3'), 'FFCADFF7');
    expect(fill('D3'), 'FFFFFFFF');
    expect(fill('D4'), 'FFDEF0E4');
    expect(fill('G2'), 'FFFFFFFF');
    expect(fill('G3'), 'FFF9E7AD');
    expect(fill('G4'), 'FFFFFFFF');
    expect(fill('L2'), 'FFF3BABA');
    expect(fill('L3'), 'FFBBD6F6');
    expect(fill('L4'), 'FFA8DBB9');
    for (final address in ['D5', 'G5', 'L5']) {
      expect(fill(address), 'FFFFFFFF');
    }
    expect(font('D4'), 'FF245B39');
    expect(font('B4'), 'FF5C3A00');
    expect(font('G3'), 'FF6D5010');
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
