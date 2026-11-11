import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/sales/domain/sales_ledger_entry.dart';
import 'package:the_we_system/features/sales/presentation/sales_ledger_page.dart';

SalesLedgerEntry entry(String id, String project, {String issuer = '협력사'}) =>
    SalesLedgerEntry.fromJson({
      'id': id,
      'projectName': project,
      'contractor': '시공 업체',
      'partner': '협력 업체',
      'invoiceIssuer': issuer,
      'depositDate': id == '2' ? '2026-11-02' : null,
    });

void main() {
  test('청구일과 계산서일은 같은 현장에만 반영하고 입금일은 유지한다', () {
    final first = entry('1', 'A');
    final second = entry('2', 'A');
    final other = entry('3', 'B');
    final changed = first.copyWith(
      billingDate: DateTime(2026, 11, 3),
      invoiceDate: DateTime(2026, 11, 4),
      depositDate: DateTime(2026, 11, 5),
    );
    final updates = siteDateUpdates([first, second, other], first, changed);
    expect(updates, hasLength(1));
    expect(updates.single.id, '2');
    expect(updates.single.billingDate, DateTime(2026, 11, 3));
    expect(updates.single.invoiceDate, DateTime(2026, 11, 4));
    expect(updates.single.depositDate, DateTime(2026, 11, 2));
  });

  testWidgets('직접입력 업체명을 저장 결과에 담는다', (tester) async {
    tester.view.physicalSize = const Size(1000, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SalesLedgerEntry? saved;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) => ElevatedButton(
          onPressed: () async {
            saved = await showDialog<SalesLedgerEntry>(
              context: context,
              builder: (_) => LedgerEditDialog(item: entry('1', 'A')),
            );
          },
          child: const Text('열기'),
        )),
      ),
    ));
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('협력사 · 협력 업체'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('직접입력').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '계산서 발행 업체명 입력'), '새 업체');
    tester.testTextInput.hide();
    await tester.ensureVisible(find.text('저장'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(saved?.invoiceIssuer, '새 업체');
    expect(saved?.invoiceIssuerName, '새 업체');
  });
}
