import 'sales_ledger_entry.dart';

const statementBankNote = '*입금 계좌번호 : 기업은행 447-069557-04-028 우리기술주식회사';
const _negotiationNote = '※ 현장 여건으로 네고된 사항입니다.';
const statementShortRentalNote = '※ 1개월 미만 현장 1일 임대로 16만원+출장교육비 1일 25만원 입니다.';
const statementShortMonthNote =
    '※ 당 현장은 1개월 미만 현장으로 1개월 임대료 초과되어 1개월분으로 계산하였습니다.';
const _defaultStatementSupplyAmount = 3000000;

int statementSupplyAmount(SalesLedgerEntry item) {
  final days = statementUsageDays(item);
  if (days != null && days < 30) {
    return (days * 160000 + 500000).clamp(0, _defaultStatementSupplyAmount);
  }
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

String statementItemNote(
  SalesLedgerEntry item, {
  Set<String> options = const {},
}) {
  final days = statementUsageDays(item);
  final parts = <String>[];
  if (options.contains('note') && item.note.trim().isNotEmpty)
    parts.add(item.note.trim());
  if (options.contains('days') && days != null && days != 30)
    parts.add('$days일');
  return parts.join(' / ');
}

List<String> statementFooterNotes(
  Iterable<SalesLedgerEntry> items, {
  Set<String> options = const {},
}) {
  final entries = items.toList();
  final notes = <String>[];
  if (options.contains('shortRental')) notes.add(statementShortRentalNote);
  if (options.contains('shortMonth')) notes.add(statementShortMonthNote);
  if (options.contains('negotiation') &&
      entries.any(
        (item) =>
            item.adjustmentAmount > 0 || item.adjustmentReason.contains('네고'),
      )) {
    notes.add(_negotiationNote);
  }
  return notes;
}
