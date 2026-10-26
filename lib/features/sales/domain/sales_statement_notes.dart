import 'sales_ledger_entry.dart';

const statementBankNote = '*입금 계좌번호 : 기업은행 447-069557-04-028 우리기술주식회사';
const _negotiationNote = '※ 현장 여건으로 네고된 사항입니다.';
const _defaultStatementSupplyAmount = 3000000;

int statementSupplyAmount(SalesLedgerEntry item) {
  final days = statementUsageDays(item);
  if (days != null && days != 30) return days * 100000;
  return item.supplyAmount > 0
      ? item.supplyAmount
      : _defaultStatementSupplyAmount;
}

/// Expands a statement with one negative negotiation line for each negotiated
/// item. The boolean marks the synthetic negotiation row.
List<(SalesLedgerEntry, bool)> statementRows(
  Iterable<SalesLedgerEntry> items,
) => [
  for (final item in items) ...[
    (item, false),
    if (item.adjustmentAmount > 0) (item, true),
  ],
];

int? statementUsageDays(SalesLedgerEntry item) {
  final start = item.startDate;
  final end = item.endDate;
  if (start == null || end == null || end.isBefore(start)) return null;
  return DateTime.utc(
        end.year,
        end.month,
        end.day,
      ).difference(DateTime.utc(start.year, start.month, start.day)).inDays +
      1;
}

String statementItemNote(SalesLedgerEntry item) {
  final days = statementUsageDays(item);
  return days != null && days != 30 ? '$days일' : '';
}

List<String> statementFooterNotes(Iterable<SalesLedgerEntry> items) {
  final entries = items.toList();
  final notes = <String>[];
  if (entries.any(
    (item) => item.adjustmentAmount > 0 || item.adjustmentReason.contains('네고'),
  )) {
    notes.add(_negotiationNote);
  }
  return notes;
}
