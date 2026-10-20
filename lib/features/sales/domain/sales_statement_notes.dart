import 'sales_ledger_entry.dart';

const statementBankNote = '*입금 계좌번호 : 기업은행 447-069557-04-028 우리기술주식회사';
const _dailyRentalNote = '※ 1개월 미만 현장 1일 임대로 16만원+출장교육비 1일 25만원 입니다.';
const _monthlyCapNote = '※ 당 현장은 1개월 미만 현장으로 1개월 임대료 초과되어 1개월분으로 계산하였습니다';
const _negotiationNote = '※ 현장 여건으로 네고된 사항입니다.';

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
  // A complete calendar month is not a short rental, including February.
  final start = item.startDate;
  final end = item.endDate;
  if ((item.month?.isNotEmpty ?? false) &&
      start != null &&
      end != null &&
      start.day == 1 &&
      start.year == end.year &&
      start.month == end.month &&
      end.day == DateTime(end.year, end.month + 1, 0).day) {
    return '';
  }
  final days = statementUsageDays(item);
  return days != null && days < 30 ? '$days일' : '';
}

List<String> statementFooterNotes(Iterable<SalesLedgerEntry> items) {
  final entries = items.toList();
  final notes = <String>[];
  if (entries.any((item) => statementItemNote(item).isNotEmpty)) {
    notes.addAll([_dailyRentalNote, _monthlyCapNote]);
  }
  if (entries.any(
    (item) => item.adjustmentAmount > 0 || item.adjustmentReason.contains('네고'),
  )) {
    notes.add(_negotiationNote);
  }
  return notes;
}
