import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/common/components/the_we_date_picker.dart';
import 'package:the_we_system/features/sales/domain/sales_ledger_entry.dart';

void main() {
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
