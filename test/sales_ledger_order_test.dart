import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/sales/domain/sales_ledger_entry.dart';
import 'package:the_we_system/features/sales/domain/sales_ledger_order.dart';

void main() {
  SalesLedgerEntry entry(String name, String date, {String status = '신규'}) =>
      SalesLedgerEntry.fromJson({
        'id': '$name-$date',
        'projectName': name,
        'startDate': date,
        'status': status,
      });

  test('전월 사용 현장은 진행, 당월 첫 사용 현장은 신규로 정렬한다', () {
    final result = classifyAndSortLedger(
      [
        entry('다 현장', '2026-10-20'),
        entry('나 현장', '2026-10-03'),
        entry('가 현장', '2026-10-10'),
        entry('종료 현장', '2026-10-01', status: '종료'),
        entry('기존 현장', '2026-10-02'),
        entry('가 진행', '2026-10-15'),
      ],
      [entry('기존 현장', '2026-09-01'), entry('가 진행', '2026-09-20')],
    );
    expect(result.map((item) => '${item.projectName}:${item.status}'), [
      '가 진행:진행',
      '기존 현장:진행',
      '나 현장:신규',
      '가 현장:신규',
      '다 현장:신규',
      '종료 현장:종료',
    ]);
  });
}
