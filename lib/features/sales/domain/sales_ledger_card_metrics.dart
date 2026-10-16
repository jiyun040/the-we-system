import 'sales_ledger_entry.dart';

class SalesLedgerCardMetrics {
  const SalesLedgerCardMetrics({
    required this.billedSiteCount,
    required this.unpaidSiteCount,
    required this.estimatedUnbilledAmount,
  });

  final int billedSiteCount;
  final int unpaidSiteCount;
  final int estimatedUnbilledAmount;

  factory SalesLedgerCardMetrics.fromEntries(
    List<SalesLedgerEntry> entries,
    DateTime month,
  ) {
    final billedSites = <String>{};
    final unpaidSites = <String>{};
    var estimatedUnbilledAmount = 0;
    final monthStart = DateTime(month.year, month.month);
    final monthEnd = DateTime(month.year, month.month + 1, 0);

    for (final entry in entries) {
      final site = entry.projectName.trim().isEmpty
          ? entry.id
          : entry.projectName.trim();
      if (entry.billingDate != null) {
        billedSites.add(site);
        if (entry.depositDate == null) unpaidSites.add(site);
        continue;
      }

      final start = entry.startDate;
      final end = entry.endDate;
      final activeStart = start != null && start.isAfter(monthStart)
          ? DateTime(start.year, start.month, start.day)
          : monthStart;
      final activeEnd = end != null && end.isBefore(monthEnd)
          ? DateTime(end.year, end.month, end.day)
          : monthEnd;
      if (!activeStart.isAfter(activeEnd)) {
        // 3,000,000원 ÷ 30일 = 호기당 하루 100,000원.
        estimatedUnbilledAmount +=
            (activeEnd.difference(activeStart).inDays + 1) * 100000;
      }
    }

    return SalesLedgerCardMetrics(
      billedSiteCount: billedSites.length,
      unpaidSiteCount: unpaidSites.length,
      estimatedUnbilledAmount: estimatedUnbilledAmount,
    );
  }
}
