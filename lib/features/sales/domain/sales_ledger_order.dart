import 'sales_ledger_entry.dart';

String _siteKey(SalesLedgerEntry entry) =>
    entry.projectName.trim().toLowerCase();
String _deviceKey(SalesLedgerEntry entry) =>
    '${_siteKey(entry)}|${entry.elevator.trim().toLowerCase()}';

List<SalesLedgerEntry> classifyAndSortLedger(
  List<SalesLedgerEntry> current,
  List<SalesLedgerEntry> previous, {
  DateTime? month,
}) {
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
    final useStart = entry.contractStartDate ?? entry.startDate;
    if (month != null && useStart != null) {
      final startedInMonth =
          useStart.year == month.year && useStart.month == month.month;
      return entry.copyWith(status: startedInMonth ? '신규' : '진행');
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
  sortLedgerEntries(entries);
  return entries;
}

void sortLedgerEntries(List<SalesLedgerEntry> entries) {
  final originalIndex = {
    for (var i = 0; i < entries.length; i++) entries[i].id: i,
  };
  final hasProgressSite = entries
      .where((entry) => entry.status == '진행')
      .map((entry) => _siteKey(entry))
      .toSet();
  entries.sort((a, b) {
    // A completed row keeps its incoming position; only its status changes.
    if (a.status == '종료' || b.status == '종료') {
      return (originalIndex[a.id] ?? 0).compareTo(originalIndex[b.id] ?? 0);
    }
    final aFranchise = a.category == '가맹';
    final bFranchise = b.category == '가맹';
    if (aFranchise != bFranchise) return aFranchise ? 1 : -1;
    final aGrouped = hasProgressSite.contains(_siteKey(a));
    final bGrouped = hasProgressSite.contains(_siteKey(b));
    if (aGrouped != bGrouped) return aGrouped ? -1 : 1;
    if (aGrouped && _siteKey(a) != _siteKey(b)) {
      final site = _siteKey(a).compareTo(_siteKey(b));
      if (site != 0) return site;
    }
    final status = _statusRank(a.status).compareTo(_statusRank(b.status));
    if (status != 0) return status;
    if (a.status == '신규' && b.status == '신규') {
      final date = (a.contractStartDate ?? a.startDate ?? DateTime(9999))
          .compareTo(b.contractStartDate ?? b.startDate ?? DateTime(9999));
      if (date != 0) return date;
    }
    return compareSalesLedgerEntries(a, b);
  });
}

int _statusRank(String status) => switch (status) {
  '진행' => 0,
  '신규' => 1,
  '종료' => 2,
  _ => 3,
};

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
