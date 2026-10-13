import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:the_we_system/common/components/the_we_date_picker.dart';
import 'package:the_we_system/features/sales/export/sales_xlsx.dart';
import 'package:the_we_system/features/sales/domain/sales_ledger_entry.dart';

void main() {
  test(
    'Excel output is an OOXML archive with numeric amounts and issuer fills',
    () {
      final bytes = salesXlsx(
        '<html><body><h2>내역서</h2><table><tr><th>시공사</th><th>협력사</th><th>공급가</th></tr><tr><td class="contractor">우리 &amp; 기술</td><td>협력</td><td>3,000,000</td></tr><tr><td>시공</td><td class="partner">협력</td><td>2000000</td></tr></table></body></html>',
        sheetName: '매출관리대장',
      );
      expect(bytes.take(2), [80, 75]);
      final zip = ZipDecoder().decodeBytes(bytes);
      final docs = {
        for (final f in zip.files)
          f.name: XmlDocument.parse(utf8.decode(f.content)),
      };
      expect(
        docs.keys,
        containsAll([
          '[Content_Types].xml',
          '_rels/.rels',
          'xl/workbook.xml',
          'xl/_rels/workbook.xml.rels',
          'xl/styles.xml',
          'xl/worksheets/sheet1.xml',
        ]),
      );
      final cells = {
        for (final c in docs['xl/worksheets/sheet1.xml']!.findAllElements('c'))
          c.getAttribute('r'): c,
      };
      expect(cells['A3']!.getAttribute('s'), '2');
      expect(cells['B4']!.getAttribute('s'), '3');
      expect(cells['C3']!.findElements('v').single.innerText, '3000000');
      expect(cells['A3']!.innerText, '우리 & 기술');
    },
  );
  test('Cleared start date serializes as null and survives reload', () {
    final item = SalesLedgerEntry.fromJson({
      'startDate': '2026-10-10',
    }).copyWith(clearStartDate: true);
    expect(item.toEditableJson()['startDate'], isNull);
    expect(SalesLedgerEntry.fromJson(item.toEditableJson()).startDate, isNull);
  });
  testWidgets(
    'Selected calendar day clears on a second click; confirm alone keeps date',
    (tester) async {
      DateTime? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showTheWeDatePicker(
                  context,
                  initialDate: DateTime(2026, 10, 13),
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2027),
                  title: '날짜',
                  clearOnReselect: true,
                );
              },
              child: const Text('열기'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('선택'));
      await tester.pumpAndSettle();
      expect(result, DateTime(2026, 10, 13));
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('13').last);
      await tester.pumpAndSettle();
      expect(result, DateTime(1));
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('14').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('14').last);
      await tester.pumpAndSettle();
      expect(result, DateTime(1));
    },
  );
}
