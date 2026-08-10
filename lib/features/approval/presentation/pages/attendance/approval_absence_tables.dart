import 'dart:math' as math;

import 'approval_absence_dependencies.dart';
import 'approval_absence_cards.dart';
import 'approval_absence_company_table.dart';
import 'approval_attendance_models.dart';

class ApprovalAttendanceTabPill extends StatelessWidget {
  const ApprovalAttendanceTabPill({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? TheWeColor.blue100 : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TheWeTextStyle.body.copyWith(
            color: selected ? TheWeColor.black900 : TheWeColor.black900,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class ApprovalManagementGroupCardData {
  const ApprovalManagementGroupCardData({
    required this.badge,
    required this.title,
    required this.rows,
  });

  final String badge;
  final String title;
  final List<String> rows;
}

class ApprovalManagementGroupCard extends StatelessWidget {
  const ApprovalManagementGroupCard({super.key, required this.data});

  final ApprovalManagementGroupCardData data;

  @override
  Widget build(BuildContext context) {
    return ApprovalAttendanceSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: TheWeColor.blue100.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(data.badge, style: TheWeTextStyle.caption),
          ),
          const SizedBox(height: 18),
          Text(data.title, style: TheWeTextStyle.title),
          const SizedBox(height: 14),
          ...data.rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                row,
                style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ApprovalAddManagementCard extends StatelessWidget {
  const ApprovalAddManagementCard({super.key, required this.title, this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: TheWeColor.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: TheWeColor.black300.withValues(alpha: 0.18),
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: TheWeColor.black300.withValues(alpha: 0.4),
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TheWeTextStyle.title,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ApprovalAttendanceTableHeader {
  const ApprovalAttendanceTableHeader(this.label, {this.flex = 2});

  final String label;
  final int flex;
}

class ApprovalGenericTable extends StatelessWidget {
  const ApprovalGenericTable({
    super.key,
    required this.headers,
    required this.rows,
    this.emptyMessage = '목록이 없습니다.',
  });

  final List<ApprovalAttendanceTableHeader> headers;
  final List<List<String>> rows;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final minimumWidth = headers.fold<double>(
      0,
      (sum, item) => sum + (item.flex * 110),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          if (rows.isEmpty) {
            return ApprovalMobileEmptyTable(message: emptyMessage);
          }

          return Column(
            children: rows
                .map(
                  (row) => ApprovalMobileDataCard(
                    entries: [
                      for (var index = 0; index < headers.length; index++)
                        MapEntry(headers[index].label, row[index]),
                    ],
                  ),
                )
                .toList(),
          );
        }

        final width = math.max(constraints.maxWidth, minimumWidth);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: headers
                        .map(
                          (header) => ApprovalAttendanceTableCell(
                            header.label,
                            flex: header.flex,
                            header: true,
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (rows.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: TheWeColor.black300.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                    child: Text(
                      emptyMessage,
                      textAlign: TextAlign.center,
                      style: TheWeTextStyle.body.copyWith(
                        color: TheWeColor.black500,
                      ),
                    ),
                  )
                else
                  ...rows.map(
                    (row) => Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: TheWeColor.black300.withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          for (var index = 0; index < headers.length; index++)
                            ApprovalAttendanceTableCell(
                              row[index],
                              flex: headers[index].flex,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ApprovalRequestTable extends StatelessWidget {
  const ApprovalRequestTable({super.key, required this.requests});

  final List<AttendanceRequestRecord> requests;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          if (requests.isEmpty) {
            return const ApprovalMobileEmptyTable(message: '목록이 없습니다.');
          }

          return Column(
            children: requests
                .map(
                  (item) => ApprovalMobileDataCard(
                    entries: [
                      MapEntry('신청유형', item.type),
                      MapEntry('신청일', item.date),
                      MapEntry('시간', item.timeRange),
                      MapEntry('사유', item.reason),
                      MapEntry('상태', item.status),
                    ],
                  ),
                )
                .toList(),
          );
        }

        final width = constraints.maxWidth < 900 ? 900.0 : constraints.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: TheWeColor.black300.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    children: const [
                      ApprovalAttendanceTableCell(
                        '신청유형',
                        flex: 2,
                        header: true,
                      ),
                      ApprovalAttendanceTableCell('신청일', flex: 2, header: true),
                      ApprovalAttendanceTableCell('시간', flex: 2, header: true),
                      ApprovalAttendanceTableCell('사유', flex: 5, header: true),
                      ApprovalAttendanceTableCell('상태', flex: 2, header: true),
                    ],
                  ),
                ),
                if (requests.isEmpty)
                  Container(
                    height: 70,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: TheWeColor.black300.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                    child: Text(
                      '목록이 없습니다.',
                      style: TheWeTextStyle.body.copyWith(
                        color: TheWeColor.black500,
                      ),
                    ),
                  )
                else
                  ...requests.map(
                    (item) => Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: TheWeColor.black300.withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          ApprovalAttendanceTableCell(item.type, flex: 2),
                          ApprovalAttendanceTableCell(item.date, flex: 2),
                          ApprovalAttendanceTableCell(item.timeRange, flex: 2),
                          ApprovalAttendanceTableCell(item.reason, flex: 5),
                          ApprovalStatusBadgeCell(item.status, flex: 2),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ApprovalMobileEmptyTable extends StatelessWidget {
  const ApprovalMobileEmptyTable({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: TheWeColor.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TheWeColor.black300.withValues(alpha: 0.2)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
      ),
    );
  }
}

class ApprovalMobileDataCard extends StatelessWidget {
  const ApprovalMobileDataCard({super.key, required this.entries});

  final List<MapEntry<String, String>> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TheWeColor.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TheWeColor.black300.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 82,
                      child: Text(
                        entry.key,
                        style: TheWeTextStyle.caption.copyWith(
                          color: TheWeColor.black500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(entry.value, style: TheWeTextStyle.body),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
