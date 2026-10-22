import 'sales_ledger_entry.dart';

String _siteKey(SalesLedgerEntry entry) =>
    entry.projectName.trim().toLowerCase();
String _deviceKey(SalesLedgerEntry entry) =>
    '${_siteKey(entry)}|${entry.elevator.trim().toLowerCase()}';

List<SalesLedgerEntry> classifyAndSortLedger(
  List<SalesLedgerEntry> current,
  List<SalesLedgerEntry> previous,
  {DateTime? month}
) {
  final previousDevices = previous
      .where(
        (entry) =>
            _siteKey(entry).isNotEmpty && entry.elevator.trim().isNotEmpty,
      )
      .map(_deviceKey)
      .toSet();
  final previousIds = previous
      .map((entry) => entry.id)
      .where((id) => id.isNotEmpty)
      .toSet();
  final entries = current.map((entry) {
    if (entry.status == '종료') return entry;
    if (month != null && entry.recordDate != null) {
      final recordedInMonth = entry.recordDate!.year == month.year &&
          entry.recordDate!.month == month.month;
      return entry.copyWith(status: recordedInMonth ? '신규' : '진행');
    }
    return entry.copyWith(
      status:
          (entry.id.isNotEmpty && previousIds.contains(entry.id)) ||
              (entry.elevator.trim().isNotEmpty &&
                  previousDevices.contains(_deviceKey(entry)))
          ? '진행'
          : '신규',
    );
  }).toList();
  entries.sort(compareSalesLedgerEntries);
  return entries;
}

int compareSalesLedgerEntries(SalesLedgerEntry a, SalesLedgerEntry b) {
  final category = (a.category == '가맹' ? 1 : 0).compareTo(
    b.category == '가맹' ? 1 : 0,
  );
  if (category != 0) return category;
  final name = a.projectName.compareTo(b.projectName);
  if (name != 0) return name;
  int rank(String status) => status == '신규' ? 1 : 0;
  final status = rank(a.status).compareTo(rank(b.status));
  if (status != 0) return status;
  final date = (a.contractStartDate ?? a.startDate ?? DateTime(9999)).compareTo(
    b.contractStartDate ?? b.startDate ?? DateTime(9999),
  );
  if (date != 0) return date;
  return a.elevator.compareTo(b.elevator);
}
