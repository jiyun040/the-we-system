import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/sales/domain/sales_ledger_card_metrics.dart';
import 'package:the_we_system/features/sales/domain/sales_ledger_entry.dart';

SalesLedgerEntry entry({
  required String id,
  required String site,
  String? start,
  String? end,
  String? billing,
  String? deposit,
}) => SalesLedgerEntry.fromJson({
  'id': id,
  'projectName': site,
  'startDate': start,
  'endDate': end,
  'billingDate': billing,
  'depositDate': deposit,
});

void main() {
  test('현장은 중복 없이 세고 미청구액은 호기별 운영일로 추정한다', () {
    final metrics = SalesLedgerCardMetrics.fromEntries([
      entry(id: '1', site: 'A 현장', start: '2026-04-01'),
      entry(id: '2', site: 'A 현장', start: '2026-04-16'),
      entry(id: '3', site: 'B 현장', billing: '2026-04-03'),
      entry(id: '4', site: 'B 현장', billing: '2026-04-04'),
      entry(
        id: '5',
        site: 'C 현장',
        billing: '2026-04-05',
        deposit: '2026-04-12',
      ),
    ], DateTime(2026, 4));

    expect(metrics.billedSiteCount, 2);
    expect(metrics.unpaidSiteCount, 1);
    expect(metrics.estimatedUnbilledAmount, 4500000);
  });

  test('30일 기준 300만원은 하루 10만원으로 계산한다', () {
    final metrics = SalesLedgerCardMetrics.fromEntries([
      entry(id: '1', site: 'A 현장', start: '2026-05-01'),
    ], DateTime(2026, 5));

    expect(metrics.estimatedUnbilledAmount, 3100000);
  });
}
