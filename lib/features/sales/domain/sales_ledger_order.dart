import 'sales_ledger_entry.dart';

String _siteKey(SalesLedgerEntry entry) =>
    entry.projectName.trim().toLowerCase();

List<SalesLedgerEntry> classifyAndSortLedger(
  List<SalesLedgerEntry> current,
  List<SalesLedgerEntry> previous,
) {
  final previousSites = previous
      .map(_siteKey)
      .where((key) => key.isNotEmpty)
      .toSet();
  final entries = current.map((entry) {
    if (entry.status == '종료') return entry;
    return entry.copyWith(
      status: previousSites.contains(_siteKey(entry)) ? '진행' : '신규',
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
  int rank(String status) => switch (status) {
    '진행' => 0,
    '신규' => 1,
    '종료' => 2,
    _ => 3,
  };
  final status = rank(a.status).compareTo(rank(b.status));
  if (status != 0) return status;
  if (a.status == '신규') {
    final date = (a.startDate ?? DateTime(9999)).compareTo(
      b.startDate ?? DateTime(9999),
    );
    if (date != 0) return date;
  }
  final name = a.projectName.compareTo(b.projectName);
  if (name != 0) return name;
  return a.elevator.compareTo(b.elevator);
}
