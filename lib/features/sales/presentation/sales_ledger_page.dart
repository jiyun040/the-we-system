import 'dart:convert';
import 'package:the_we_system/core/network/api_exception.dart';
import 'package:the_we_system/features/sales/export/sales_xlsx.dart';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:the_we_system/common/components/mobile_navigation.dart';
import 'package:the_we_system/common/components/side_bar.dart';
import 'package:the_we_system/common/components/the_we_data_table.dart';
import 'package:the_we_system/common/components/the_we_date_picker.dart';
import 'package:the_we_system/common/components/the_we_dropdown.dart';
import 'package:the_we_system/common/components/the_we_modal.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/common/components/the_we_snack_bar.dart';
import 'package:the_we_system/core/network/dio_provider.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/sales/data/sales_api_service.dart';
import 'package:the_we_system/features/sales/domain/sales_ledger_entry.dart';

class SalesLedgerPage extends ConsumerStatefulWidget {
  const SalesLedgerPage({super.key});

  @override
  ConsumerState<SalesLedgerPage> createState() => _SalesLedgerPageState();
}

class _SalesLedgerPageState extends ConsumerState<SalesLedgerPage> {
  final _search = TextEditingController();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String _status = '';
  bool _loading = true;
  String? _error;
  List<SalesLedgerEntry> _items = const [];
  SalesLedgerSummary _summary = const SalesLedgerSummary(
    supplyAmount: 0,
    billCount: 0,
    unbilledCount: 0,
    unissuedInvoiceCount: 0,
    unpaidAmount: 0,
  );

  SalesApiService get _api => SalesApiService(ref.read(dioProvider));

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _api.fetchLedger(
        month: _month,
        query: _search.text,
        status: _status,
      );
      if (!mounted) return;
      setState(() {
        _items = result.items
          ..sort((a, b) {
            final category = (a.category == '가맹' ? 1 : 0).compareTo(
              b.category == '가맹' ? 1 : 0,
            );
            return category != 0
                ? category
                : a.projectName.compareTo(b.projectName);
          });
        _summary = result.summary;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '매출관리대장을 불러오지 못했습니다.';
        });
      }
    }
  }

  Future<void> _changeMonth(int delta) async {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
    await _load();
  }

  Future<void> _edit(SalesLedgerEntry item) async {
    final changed = await showDialog<SalesLedgerEntry>(
      context: context,
      builder: (_) => _LedgerEditDialog(item: item),
    );
    if (changed == null) return;
    try {
      final saved = await _api.updateEntry(changed);
      if (!mounted) return;
      setState(
        () => _items = _items
            .map((item) => item.id == saved.id ? saved : item)
            .toList(),
      );
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingErrorMessage(
                error,
                fallback: '저장하지 못했습니다. 다시 시도해 주세요.',
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showStatement(SalesLedgerEntry entry) async {
    try {
      final statement = await _api.fetchStatement(entry.projectName, _month);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => _StatementDialog(statement: statement, month: _month),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('내역서를 생성하지 못했습니다.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref
        .watch(approvalDashboardControllerProvider)
        .asData
        ?.value;
    final user = dashboard?.currentUser;
    if (user != null && !user.canAccessSalesLedger) {
      return const Scaffold(body: Center(child: Text('매출관리대장 접근 권한이 없습니다.')));
    }
    final sideBar = dashboard == null
        ? null
        : SideBar(
            frequentForms: dashboard.dashboard.frequentForms,
            pendingDocument: dashboard.dashboard.pendingCount,
            receiveDocument: dashboard.dashboard.receivedCount,
            openPendingDocument: dashboard.dashboard.referenceCount,
            scheduledDocument: dashboard.dashboard.scheduledCount,
          );
    final page = _LedgerContent(
      month: _month,
      loading: _loading,
      error: _error,
      items: _items,
      summary: _summary,
      search: _search,
      selectedStatus: _status,
      onSearch: _load,
      onStatus: (value) {
        setState(() => _status = value);
        _load();
      },
      onPrevious: () => _changeMonth(-1),
      onNext: () => _changeMonth(1),
      onPickMonth: _pickMonth,
      onExport: _exportExcel,
      onEdit: _edit,
      onStatement: _showStatement,
    );
    return Scaffold(
      backgroundColor: TheWeColor.white,
      appBar: MediaQuery.sizeOf(context).width < 520
          ? const MobileNavigationAppBar()
          : null,
      drawer: MediaQuery.sizeOf(context).width < 520
          ? const MobileNavigationDrawer()
          : null,
      body: MediaQuery.sizeOf(context).width < 520 || sideBar == null
          ? page
          : Row(
              children: [
                sideBar,
                const SideBarDivider(),
                Expanded(child: page),
              ],
            ),
    );
  }

  Future<void> _pickMonth() async {
    final today = DateTime.now();
    final selected = await showTheWeDatePicker(
      context,
      initialDate: _month,
      firstDate: DateTime(today.year - 5),
      lastDate: today,
      title: '조회할 연월 선택',
    );
    if (selected == null) return;
    setState(() => _month = DateTime(selected.year, selected.month));
    await _load();
  }

  Future<void> _exportExcel() async {
    final html = StringBuffer(
      '<html><head><meta charset="utf-8"><style>table{border-collapse:collapse}th,td{border:1px solid #999;padding:6px}th{background:#d9effb} .contractor{background:#e7efff}.partner{background:#e8f5e9}</style></head><body><table><tr>',
    );
    const headers = [
      '번호',
      '공사명',
      '시공사',
      '협력사',
      '호기',
      '사용 시작일',
      '사용 종료일',
      '일수',
      '청구',
      '계산서',
      '입금',
      '공급가',
      '조정액',
      '회차',
      '상태',
      '비고',
      '분류',
    ];
    for (final h in headers) {
      html.write('<th>$h</th>');
    }
    html.write('</tr>');
    String esc(Object? v) => const HtmlEscape().convert(v?.toString() ?? '');
    for (var index = 0; index < _items.length; index++) {
      final item = _items[index];
      final issuerClass = (_issuerType(item) == '시공사'
          ? 'contractor'
          : (_issuerType(item) == '협력사' ? 'partner' : ''));
      final values = [
        index + 1,
        item.projectName,
        item.contractor,
        item.partner,
        item.elevator,
        _date(item.startDate),
        _date(item.endDate),
        _duration(item.startDate, item.endDate),
        _date(item.billingDate),
        _date(item.invoiceDate),
        _date(item.depositDate),
        item.supplyAmount,
        item.adjustmentAmount,
        '${item.installment}회차',
        item.status,
        _mergeNote(item.note, item.adjustmentReason),
        item.category,
      ];
      html.write('<tr>');
      for (var i = 0; i < values.length; i++) {
        final cellClass = i == 2 && issuerClass == 'contractor'
            ? issuerClass
            : (i == 3 && issuerClass == 'partner' ? issuerClass : '');
        html.write('<td class="$cellClass">${esc(values[i])}</td>');
      }
      html.write('</tr>');
    }
    html.write('</table></body></html>');
    await FileSaver.instance.saveFile(
      name: '매출관리대장_${_month.year}${_month.month.toString().padLeft(2, '0')}',
      bytes: salesXlsx(html.toString(), sheetName: '매출관리대장'),
      fileExtension: 'xlsx',
      mimeType: MimeType.custom,
      customMimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }
}

class _LedgerContent extends StatelessWidget {
  const _LedgerContent({
    required this.month,
    required this.loading,
    required this.error,
    required this.items,
    required this.summary,
    required this.search,
    required this.selectedStatus,
    required this.onSearch,
    required this.onStatus,
    required this.onPrevious,
    required this.onNext,
    required this.onPickMonth,
    required this.onExport,
    required this.onEdit,
    required this.onStatement,
  });
  final DateTime month;
  final bool loading;
  final String? error;
  final List<SalesLedgerEntry> items;
  final SalesLedgerSummary summary;
  final TextEditingController search;
  final String selectedStatus;
  final VoidCallback onSearch;
  final ValueChanged<String> onStatus;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPickMonth;
  final VoidCallback onExport;
  final ValueChanged<SalesLedgerEntry> onEdit;
  final ValueChanged<SalesLedgerEntry> onStatement;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(compact ? 18 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '매출관리대장',
              style: (compact ? TheWeTextStyle.title : TheWeTextStyle.pageTitle)
                  .copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'PDAM DB에서 현장·호기 정보를 자동 반영합니다. 행을 눌러 청구, 계산서, 입금과 금액을 수정할 수 있으며, 공사명을 눌러 내역서를 확인할 수 있습니다.',
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
            const SizedBox(height: 22),
            _SummaryCards(summary: summary),
            const SizedBox(height: 20),
            compact
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: _toolbarChildren(fullWidthSearch: true),
                  )
                : Row(children: _toolbarChildren(fullWidthSearch: false)),
            const SizedBox(height: 16),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                  ? Center(child: Text(error!))
                  : _LedgerTable(
                      items: items,
                      onEdit: onEdit,
                      onStatement: onStatement,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _toolbarChildren({required bool fullWidthSearch}) => [
    SizedBox(
      width: fullWidthSearch ? double.infinity : 300,
      child: TextField(
        controller: search,
        onSubmitted: (_) => onSearch(),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          hintText: '공사명, 시공사, 협력사 검색',
          prefixIcon: Icon(Icons.search),
        ),
      ),
    ),
    const SizedBox(width: 8),
    for (final status in const ['', '신규', '진행', '종료']) ...[
      ChoiceChip(
        label: Text(status.isEmpty ? '전체' : status),
        selected: selectedStatus == status,
        onSelected: (_) => onStatus(status),
      ),
      const SizedBox(width: 8),
    ],
    if (!fullWidthSearch) const Spacer(),
    OutlinedButton.icon(
      onPressed: onExport,
      icon: const Icon(Icons.download_outlined, size: 18),
      label: const Text('엑셀 내보내기'),
    ),
    const SizedBox(width: 8),
    IconButton(
      onPressed: onPrevious,
      icon: const Icon(Icons.chevron_left),
      tooltip: '이전 달',
    ),
    TextButton(
      onPressed: onPickMonth,
      child: Text(
        '${month.year}년 ${month.month}월',
        style: TheWeTextStyle.section,
      ),
    ),
    IconButton(
      onPressed: onNext,
      icon: const Icon(Icons.chevron_right),
      tooltip: '다음 달',
    ),
  ];
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.summary});
  final SalesLedgerSummary summary;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final cards = [
        ('공급가 합계', _money(summary.supplyAmount), 'VAT 별도', TheWeColor.black900),
        ('청구 건수', '${summary.billCount}건', '현장 기준', TheWeColor.black900),
        (
          '미청구',
          '${summary.unbilledCount}건',
          '청구일 미입력',
          const Color(0xFFE06A00),
        ),
        (
          '계산서 미발행',
          '${summary.unissuedInvoiceCount}건',
          '청구 완료 건 중',
          const Color(0xFFE06A00),
        ),
        (
          '미입금 (VAT 포함)',
          _money((summary.unpaidAmount * 1.1).round()),
          '입금일 미입력',
          TheWeColor.danger,
        ),
      ];
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: TheWeColor.blue100),
          borderRadius: BorderRadius.circular(14),
        ),
        child: constraints.maxWidth < 600
            ? Wrap(
                children: cards
                    .map(
                      (card) => SizedBox(
                        width: constraints.maxWidth / 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 8,
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Text(
                                card.$1,
                                style: TheWeTextStyle.hintText.copyWith(
                                  color: TheWeColor.black500,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                card.$2,
                                style: TheWeTextStyle.subtitle.copyWith(
                                  color: card.$4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                card.$3,
                                style: TheWeTextStyle.hintText.copyWith(
                                  color: TheWeColor.black500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              )
            : Row(
                children: cards
                    .map(
                      (card) => Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 4,
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Text(
                                card.$1,
                                style: TheWeTextStyle.hintText.copyWith(
                                  color: TheWeColor.black500,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                card.$2,
                                style: TheWeTextStyle.subtitle.copyWith(
                                  color: card.$4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                card.$3,
                                style: TheWeTextStyle.hintText.copyWith(
                                  color: TheWeColor.black500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
      );
    },
  );
}

class _LedgerTable extends StatelessWidget {
  const _LedgerTable({
    required this.items,
    required this.onEdit,
    required this.onStatement,
  });
  final List<SalesLedgerEntry> items;
  final ValueChanged<SalesLedgerEntry> onEdit;
  final ValueChanged<SalesLedgerEntry> onStatement;
  @override
  Widget build(BuildContext context) => TheWeDataTable(
    headers: const [
      '번호',
      '공사명',
      '시공사',
      '협력사',
      '호기',
      '사용일',
      '일수',
      '청구',
      '계산서',
      '입금',
      '공급가',
      '회차',
      '상태',
      '비고',
      '분류',
    ],
    minWidth: 1580,
    columnFlexes: const [
      .65,
      2.25,
      1.15,
      1.2,
      .85,
      1.25,
      .95,
      .9,
      .9,
      .9,
      1.15,
      .85,
      .8,
      1.7,
      .7,
    ],
    rows: [
      for (var index = 0; index < items.length; index++)
        _row(context, index, items[index]),
    ],
    rowColors: List.filled(items.length, Colors.white),
    cellColors: [
      for (final item in items)
        [
          for (var col = 0; col < 15; col++)
            (col == 2 && _issuerType(item) == '시공사') ||
                    (col == 3 && _issuerType(item) == '협력사')
                ? _issuerColor(item)
                : null,
        ],
    ],
    onRowTaps: [for (final item in items) () => onEdit(item)],
  );
  List<Widget> _row(BuildContext context, int index, SalesLedgerEntry item) => [
    _cell('${index + 1}'),
    Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () => onStatement(item),
        child: Text(
          item.projectName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TheWeTextStyle.caption.copyWith(
            color: TheWeColor.blue300,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
    _cell(item.contractor),
    _cell(item.partner),
    _cell(item.elevator, maxLines: 1),
    _cell(
      '${_date(item.startDate)}\n~ ${item.endDate == null ? '진행 중' : _date(item.endDate!)}',
    ),
    _cell(_duration(item.startDate, item.endDate), maxLines: 2),
    _cell(_shortDate(item.billingDate)),
    _cell(_shortDate(item.invoiceDate)),
    _cell(_shortDate(item.depositDate)),
    _cell(_money(item.supplyAmount)),
    _cell('${item.installment}회차', maxLines: 1),
    _StatusPill(status: item.status),
    _cell(item.note, left: true),
    _cell(item.category.isEmpty ? '-' : item.category),
  ];
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      '종료' => TheWeColor.danger,
      '진행' => TheWeColor.green,
      _ => TheWeColor.blue300,
    };
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status,
          style: TheWeTextStyle.hintText.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _LedgerEditDialog extends StatefulWidget {
  const _LedgerEditDialog({required this.item});
  final SalesLedgerEntry item;
  @override
  State<_LedgerEditDialog> createState() => _LedgerEditDialogState();
}

class _LedgerEditDialogState extends State<_LedgerEditDialog> {
  late String category;
  late String status;
  late TextEditingController amount;
  late TextEditingController installment;
  late TextEditingController note;
  late TextEditingController adjustment;
  late TextEditingController adjustmentReason;
  late TextEditingController invoiceIssuer;
  DateTime? usageStart;
  DateTime? usageEnd;
  DateTime? billing;
  DateTime? invoice;
  DateTime? deposit;
  @override
  void initState() {
    super.initState();
    final item = widget.item;
    category = item.category;
    status = item.status;
    final baseAmount = item.supplyAmount + item.adjustmentAmount;
    amount = TextEditingController(
      text: _money(baseAmount == 0 ? 3000000 : baseAmount),
    );
    installment = TextEditingController(text: item.installment.toString());
    note = TextEditingController(text: item.note);
    adjustment = TextEditingController(text: item.adjustmentAmount.toString());
    adjustmentReason = TextEditingController(text: item.adjustmentReason);
    invoiceIssuer = TextEditingController();
    invoiceIssuer.text = item.invoiceIssuerType.isNotEmpty
        ? item.invoiceIssuerType
        : item.invoiceIssuer;
    usageStart = item.startDate;
    usageEnd = item.endDate;
    billing = item.billingDate;
    invoice = item.invoiceDate;
    deposit = item.depositDate;
  }

  @override
  void dispose() {
    amount.dispose();
    installment.dispose();
    note.dispose();
    adjustment.dispose();
    adjustmentReason.dispose();
    invoiceIssuer.dispose();
    super.dispose();
  }

  Future<void> choose(String kind) async {
    final current = switch (kind) {
      'start' => usageStart,
      'end' => usageEnd,
      'billing' => billing,
      'invoice' => invoice,
      _ => deposit,
    };
    final selected = await showTheWeDatePicker(
      context,
      initialDate: current ?? DateTime.now(),
      clearOnReselect: true,
      hasSelection: current != null,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
      title:
          '${switch (kind) {
            'start' => '시작일',
            'end' => '종료일',
            'billing' => '청구',
            'invoice' => '계산서 발행',
            _ => '입금',
          }} 날짜 선택',
    );
    if (selected == null) return;
    if (selected.year == 1) {
      setState(() {
        if (kind == 'start') usageStart = null;
        if (kind == 'end') usageEnd = null;
        if (kind == 'billing') billing = null;
        if (kind == 'invoice') invoice = null;
        if (kind == 'deposit') deposit = null;
      });
      return;
    }
    setState(() {
      if (kind == 'billing') billing = selected;
      if (kind == 'invoice') invoice = selected;
      if (kind == 'deposit') deposit = selected;
      if (kind == 'start') usageStart = selected;
      if (kind == 'end') usageEnd = selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final compact = MediaQuery.sizeOf(context).width < 600;
    final enteredSupply = int.tryParse(amount.text.replaceAll(',', '')) ?? 0;
    final adjustmentValue =
        int.tryParse(adjustment.text.replaceAll(',', '')) ?? 0;
    final supply = enteredSupply - adjustmentValue;
    final tax = (supply * .1).round();
    final modalContentWidth = compact
        ? MediaQuery.sizeOf(context).width - 72
        : 640.0 - 56;
    final fieldWidth = compact ? double.infinity : (modalContentWidth - 16) / 2;
    Widget field(String label, Widget child, {double? width}) => SizedBox(
      width: width ?? fieldWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TheWeTextStyle.hintText.copyWith(color: TheWeColor.black500),
          ),
          const SizedBox(height: 5),
          child,
        ],
      ),
    );
    Widget dateField(String label, DateTime? value, String kind) => field(
      label,
      OutlinedButton.icon(
        onPressed: () => choose(kind),
        icon: const Icon(Icons.calendar_month_outlined, size: 18),
        label: Text(value == null ? 'YYYY.MM.DD' : _date(value)),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          minimumSize: const Size.fromHeight(42),
          foregroundColor: TheWeColor.black900,
          side: const BorderSide(color: TheWeColor.blue100),
        ),
      ),
    );
    return TheWeModalSurface(
      width: 640,
      maxWidth: 640,
      maxHeightFactor: .94,
      padding: EdgeInsets.all(compact ? 18 : 28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TheWeModalHeader(
              title: '${item.projectName} · ${item.elevator}',
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${item.contractor} / ${item.partner} · ${item.startDate?.year ?? "-"}년 ${item.startDate?.month ?? "-"}월 ·',
                  style: TheWeTextStyle.caption.copyWith(
                    color: TheWeColor.black500,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${item.installment}회차',
                      style: TheWeTextStyle.caption.copyWith(
                        color: TheWeColor.black500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(status: status),
                  ],
                ),
              ],
            ),
            const Divider(height: 30),
            Text('계약 조건', style: TheWeTextStyle.section),
            const SizedBox(height: 10),
            Text(
              '단가     월정산 · 월 ${_money(item.supplyAmount)}원',
              style: TheWeTextStyle.caption,
            ),
            const SizedBox(height: 5),
            Text('정산일  말일', style: TheWeTextStyle.caption),
            const SizedBox(height: 5),
            Text(
              '계약기간  ${_date(item.startDate)} ~ ${item.endDate == null ? '사용중' : _date(item.endDate)}',
              style: TheWeTextStyle.caption,
            ),
            const SizedBox(height: 25),
            Text('사용기간 · 금액', style: TheWeTextStyle.section),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 14,
              children: [
                field(
                  '분류',
                  TheWeDropdown<String>(
                    value: category.isEmpty ? null : category,
                    items: const ['본사', '가맹'],
                    labelBuilder: (value) => value,
                    hintText: '선택',
                    width: double.infinity,
                    onChanged: (value) =>
                        setState(() => category = value ?? ''),
                  ),
                ),
                field(
                  '상태',
                  TheWeDropdown<String>(
                    value: status,
                    items: const ['신규', '진행', '종료'],
                    labelBuilder: (value) => value,
                    width: double.infinity,
                    onChanged: (value) =>
                        setState(() => status = value ?? '신규'),
                  ),
                ),
                dateField('시작일', usageStart, 'start'),
                dateField('종료일', usageEnd, 'end'),
                field(
                  '조정액 (+ / -)',
                  TextField(
                    controller: adjustment,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                field(
                  '조정사유',
                  TextField(
                    controller: adjustmentReason,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: '예) 계약 특가, 장기사용',
                    ),
                  ),
                ),
                field(
                  '회차',
                  TextField(
                    controller: installment,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true),
                  ),
                ),
                field(
                  '공급가',
                  TextField(
                    controller: amount,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_currencyInputFormatter],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(isDense: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: TheWeColor.blue100),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _editAmountRow('공급가', _money(supply)),
                  _editAmountRow('부가세 10%', _money(tax)),
                  _editAmountRow('합계', _money(supply + tax), bold: true),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Text('청구 · 계산서 · 입금', style: TheWeTextStyle.section),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 14,
              children: [
                dateField('청구일', billing, 'billing'),
                dateField('계산서 발행일', invoice, 'invoice'),
                dateField('입금일', deposit, 'deposit'),
                field(
                  '입금액 (자동계산)',
                  InputDecorator(
                    decoration: const InputDecoration(isDense: true),
                    child: Text('합계 ${_money(supply + tax)}'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: field(
                    '계산서 발행처',
                    TheWeDropdown<String>(
                      value: invoiceIssuer.text,
                      width: double.infinity,
                      items: [
                        '시공사',
                        '협력사',
                        if (!['', '시공사', '협력사'].contains(invoiceIssuer.text))
                          invoiceIssuer.text,
                      ],
                      labelBuilder: (value) => switch (value) {
                        '시공사' => '시공사 · ${item.contractor}',
                        '협력사' => '협력사 · ${item.partner}',
                        _ => value,
                      },
                      onChanged: (value) =>
                          setState(() => invoiceIssuer.text = value ?? '협력사'),
                    ),
                    width: double.infinity,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: field(
                '비고',
                TextField(
                  controller: note,
                  decoration: const InputDecoration(isDense: true),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TheWeModalActions(
              primaryLabel: '저장',
              secondaryLabel: '취소',
              onSecondaryPressed: () => Navigator.pop(context),
              onPrimaryPressed: () {
                final cycle = int.tryParse(installment.text) ?? 1;
                Navigator.pop(
                  context,
                  item.copyWith(
                    startDate: usageStart,
                    clearStartDate: usageStart == null,
                    endDate: usageEnd,
                    clearEndDate: usageEnd == null,
                    category: category,
                    status: status,
                    installment: cycle < 1 ? 1 : cycle,
                    supplyAmount: supply < 0 ? 0 : supply,
                    adjustmentAmount: adjustmentValue,
                    adjustmentReason: adjustmentReason.text.trim(),
                    note: _mergeNote(note.text, adjustmentReason.text),
                    invoiceIssuer: invoiceIssuer.text.trim(),
                    billingDate: billing,
                    clearBillingDate: billing == null,
                    invoiceDate: invoice,
                    clearInvoiceDate: invoice == null,
                    depositDate: deposit,
                    clearDepositDate: deposit == null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/*
  The edit surface intentionally uses the same modal, field, action and date
  picker primitives as the rest of the ERP.  Keep this section free of bespoke
  AlertDialog styling so future theme changes apply consistently.
*/
/*
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PDAM 연동 정보', style: TheWeTextStyle.section),
            const SizedBox(height: 8),
            Text(
              '${widget.item.contractor} · ${widget.item.partner}\n${_date(widget.item.startDate)} ~ ${widget.item.endDate == null ? '진행 중' : _date(widget.item.endDate!)}  (${_duration(widget.item.startDate, widget.item.endDate)})',
            ),
            const Divider(height: 28),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: '분류'),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('미분류')),
                      DropdownMenuItem(value: '본사', child: Text('본사')),
                      DropdownMenuItem(value: '가맹', child: Text('가맹')),
                    ],
                    onChanged: (value) =>
                        setState(() => category = value ?? ''),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: '상태'),
                    items: const [
                      DropdownMenuItem(value: '신규', child: Text('신규')),
                      DropdownMenuItem(value: '진행', child: Text('진행')),
                      DropdownMenuItem(value: '종료', child: Text('종료')),
                    ],
                    onChanged: (value) =>
                        setState(() => status = value ?? '신규'),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: installment,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '회차'),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '공급가'),
                  ),
                ),
                _dateButton('청구일', billing, () => choose('billing')),
                _dateButton('계산서 발행일', invoice, () => choose('invoice')),
                _dateButton('입금일', deposit, () => choose('deposit')),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              maxLines: 2,
              decoration: const InputDecoration(labelText: '비고'),
            ),
            const SizedBox(height: 8),
            Text(
              '회차 1회는 신규, 2회 이상은 진행으로 자동 정리됩니다. 종료는 PDAM 종료 상태 또는 작업 완료 시 사용합니다.',
              style: TheWeTextStyle.hintText.copyWith(
                color: TheWeColor.black500,
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: () {
          final cycle = int.tryParse(installment.text) ?? 1;
          Navigator.pop(
            context,
            widget.item.copyWith(
              category: category,
              status: status == '종료' ? '종료' : (cycle > 1 ? '진행' : '신규'),
              installment: cycle < 1 ? 1 : cycle,
              supplyAmount: int.tryParse(amount.text.replaceAll(',', '')) ?? 0,
              note: note.text.trim(),
              billingDate: billing,
              clearBillingDate: billing == null,
              invoiceDate: invoice,
              clearInvoiceDate: invoice == null,
              depositDate: deposit,
              clearDepositDate: deposit == null,
            ),
          );
        },
        child: const Text('저장'),
      ),
    ],
  );
  Widget _dateButton(String label, DateTime? value, VoidCallback onPressed) =>
      SizedBox(
        width: 180,
        child: OutlinedButton(
          onPressed: onPressed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TheWeTextStyle.hintText),
              const SizedBox(height: 4),
              Text(_date(value)),
            ],
          ),
        ),
      );
}

*/

String _mergeNote(String note, String reason) {
  final n = note.trim();
  final r = reason.trim();
  if (r.isEmpty) return n;
  if (n.isEmpty || n.contains(r)) return n.isEmpty ? r : n;
  return '$n / $r';
}

String _issuerType(SalesLedgerEntry item) => item.invoiceIssuerType;

Color _issuerColor(SalesLedgerEntry item) => (_issuerType(item) == '시공사'
    ? const Color(0xFFE7EFFF)
    : (_issuerType(item) == '협력사' ? const Color(0xFFE8F5E9) : Colors.white));
Widget _editAmountRow(String label, String value, {bool bold = false}) =>
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TheWeTextStyle.caption.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TheWeTextStyle.caption.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );

class _StatementDialog extends StatelessWidget {
  const _StatementDialog({required this.statement, required this.month});
  final SalesStatement statement;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final total = statement.items.fold<int>(
      0,
      (sum, item) => sum + item.supplyAmount,
    );
    final vat = (total * .1).round();
    final issueDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final first = statement.items.firstOrNull;
    final rowCount = statement.items.length < 12 ? 12 : statement.items.length;
    final rows = <TableRow>[
      TableRow(
        children: [
          for (final label in const [
            '종 목',
            '사 용 기 간',
            '단위',
            '수량',
            '공급가',
            '세 액',
            '합 계',
            '비 고',
          ])
            _statementCell(label, bold: true),
        ],
      ),
      for (var i = 0; i < rowCount; i++)
        TableRow(
          children: i < statement.items.length
              ? [
                  _statementCell(
                    'PDAM시스템 공급\n${statement.items[i].elevator} ${statement.items[i].installment}회',
                  ),
                  _statementCell(
                    '${_date(statement.items[i].startDate)} ~ ${statement.items[i].endDate == null ? '사용중' : _date(statement.items[i].endDate)}',
                  ),
                  _statementCell('SET'),
                  _statementCell('1'),
                  _statementCell(_money(statement.items[i].supplyAmount)),
                  _statementCell(
                    _money((statement.items[i].supplyAmount * .1).round()),
                  ),
                  _statementCell(
                    _money((statement.items[i].supplyAmount * 1.1).round()),
                  ),
                  _statementCell(statement.items[i].note),
                ]
              : [
                  for (var col = 0; col < 8; col++)
                    _statementCell(col == 5 || col == 6 ? '-' : ''),
                ],
        ),
    ];
    return TheWeModalSurface(
      maxWidth: 1000,
      maxHeightFactor: .94,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: 920,
                  height: 1130,
                  padding: const EdgeInsets.fromLTRB(34, 10, 34, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      right: BorderSide(color: Colors.blue, width: 3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '내 역 서',
                        textAlign: TextAlign.center,
                        style: TheWeTextStyle.pageTitle.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 10,
                        ),
                      ),
                      const SizedBox(height: 70),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _statementLine('수 신', first?.contractor ?? ''),
                                _statementLine('발 신', '우리기술㈜'),
                                _statementLine(
                                  '현 장 명',
                                  statement.projectName,
                                  highlighted: true,
                                ),
                                _statementLine('결 제 일', '계산서 발행 후 익월 말일 이내'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/theWeLogo.png',
                                      width: 50,
                                      height: 32,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '우리기술 주식회사',
                                      style: TheWeTextStyle.subtitle.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '등록번호 : 787-88-01517   대표이사 : 조 성 률',
                                  style: TheWeTextStyle.caption,
                                ),
                                Text(
                                  '본사 : 대전광역시 대덕구 신일동로 105, 304호',
                                  style: TheWeTextStyle.caption,
                                ),
                                Text(
                                  '업태 : 제조업, 정보통신업',
                                  style: TheWeTextStyle.caption,
                                ),
                                Text(
                                  '종목 : PDAM시스템제조및공급, 응용소프트웨어개발및공급',
                                  style: TheWeTextStyle.caption,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  'TEL 070-4334-9000  FAX 042-933-0104',
                                  style: TheWeTextStyle.caption,
                                ),
                                Text(
                                  'e-mail : we8104@hanmail.net',
                                  style: TheWeTextStyle.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Container(
                        color: const Color(0xFFD9EFFB),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text('아래 품목의 내역을 제출하오니 검토 바랍니다.'),
                            ),
                            Text(issueDate),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          '내역 합계 금액(Total)              ${_money(total + vat)}  원 (VAT 포함)',
                          textAlign: TextAlign.center,
                          style: TheWeTextStyle.subtitle,
                        ),
                      ),
                      const Divider(
                        color: Colors.black,
                        thickness: 2,
                        height: 2,
                      ),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1.7),
                          1: FlexColumnWidth(2.4),
                          2: FlexColumnWidth(.6),
                          3: FlexColumnWidth(.6),
                          4: FlexColumnWidth(1.1),
                          5: FlexColumnWidth(1),
                          6: FlexColumnWidth(1.2),
                          7: FlexColumnWidth(.9),
                        },
                        border: const TableBorder(
                          horizontalInside: BorderSide(
                            color: Color(0xFFE7E7E7),
                          ),
                        ),
                        children: rows,
                      ),
                      const Spacer(),
                      const Divider(color: Colors.black54, height: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          '합     계                     ${statement.items.length}      ${_money(total)}       ${_money(vat)}       ${_money(total + vat)}',
                          textAlign: TextAlign.right,
                          style: TheWeTextStyle.subtitle,
                        ),
                      ),
                      Container(
                        color: const Color(0xFFF0F4E6),
                        padding: const EdgeInsets.all(12),
                        child: const Text(
                          '비   고     *입금 계좌번호 : 기업은행 447-069557-04-028 우리기술주식회사',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _downloadStatementExcel(context, statement),
                  icon: const Icon(Icons.table_view_outlined),
                  label: const Text('엑셀 다운로드'),
                ),
                FilledButton.icon(
                  onPressed: () =>
                      _downloadStatementPdf(context, statement, month),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('PDF 다운로드'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _statementLine(
  String label,
  String value, {
  bool highlighted = false,
}) => Container(
  color: highlighted ? const Color(0xFFE9EFFC) : Colors.transparent,
  padding: const EdgeInsets.symmetric(vertical: 7),
  child: Row(
    children: [
      SizedBox(
        width: 78,
        child: Text(
          '$label :',
          style: TheWeTextStyle.caption.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      Expanded(
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black)),
          ),
          child: Text(
            value,
            style: TheWeTextStyle.caption.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    ],
  ),
);

Future<void> _downloadStatementExcel(
  BuildContext context,
  SalesStatement statement,
) async {
  final total = statement.items.fold<int>(
    0,
    (sum, item) => sum + item.supplyAmount,
  );
  final vat = (total * .1).round();
  String esc(Object? v) => const HtmlEscape().convert(v?.toString() ?? '');
  final b = StringBuffer(
    '<html><head><meta charset="utf-8"><style>table{border-collapse:collapse}th,td{border:1px solid #999;padding:7px}th{background:#d9effb}</style></head><body>',
  );
  b.write(
    '<h2 style="text-align:center">내 역 서</h2><p>수신 : ${esc(statement.items.firstOrNull?.contractor ?? '')}<br>발신 : 우리기술㈜<br>현장명 : ${esc(statement.projectName)}<br>결제일 : 계산서 발행 후 익월 말일 이내</p>',
  );
  b.write(
    '<table><tr><th>종목</th><th>사용 기간</th><th>단위</th><th>수량</th><th>공급가</th><th>세액</th><th>합계</th><th>비고</th></tr>',
  );
  for (final item in statement.items) {
    b.write(
      '<tr><td>PDAM시스템 공급 ${esc(item.elevator)} ${item.installment}회</td><td>${_date(item.startDate)} ~ ${item.endDate == null ? '사용중' : _date(item.endDate!)}</td><td>SET</td><td>1</td><td>${_money(item.supplyAmount)}</td><td>${_money((item.supplyAmount * .1).round())}</td><td>${_money((item.supplyAmount * 1.1).round())}</td><td>${esc(_mergeNote(item.note, item.adjustmentReason))}</td></tr>',
    );
  }
  for (var i = statement.items.length; i < 12; i++) {
    b.write(
      '<tr><td></td><td></td><td></td><td></td><td></td><td>-</td><td>-</td><td></td></tr>',
    );
  }
  b.write(
    '</table><p style="text-align:right"><b>합계 ${_money(total)} / ${_money(vat)} / ${_money(total + vat)}</b></p><p>비고 *입금 계좌번호 : 기업은행 447-069557-04-028 우리기술주식회사</p></body></html>',
  );
  await FileSaver.instance.saveFile(
    name: '내역서_${statement.projectName}',
    bytes: salesXlsx(b.toString(), sheetName: '내역서'),
    fileExtension: 'xlsx',
    mimeType: MimeType.custom,
    customMimeType:
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );
  if (context.mounted) showTheWeSnackBar(context, message: '엑셀 파일로 저장했습니다.');
}

Future<void> _downloadStatementPdf(
  BuildContext context,
  SalesStatement statement,
  DateTime month,
) async {
  try {
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/SUIT-Medium.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/SUIT-Bold.ttf'),
    );
    final logo = pw.MemoryImage(
      (await rootBundle.load(
        'assets/images/theWeLogo.png',
      )).buffer.asUint8List(),
    );
    final total = statement.items.fold(
      0,
      (sum, item) => sum + item.supplyAmount,
    );
    final vat = (total * .1).round();
    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(
              child: pw.Text(
                '내 역 서',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 65),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '수신 : ${statement.items.firstOrNull?.contractor ?? '-'}',
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text('발신 : 우리기술㈜'),
                      pw.SizedBox(height: 6),
                      pw.Text('현장명 : ${statement.projectName}'),
                      pw.SizedBox(height: 6),
                      pw.Text('결제일 : 계산서 발행 후 익월 말일 이내'),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Image(logo, width: 28, height: 20),
                          pw.SizedBox(width: 4),
                          pw.Text(
                            '우리기술 주식회사',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                      pw.Text('등록번호 : 787-88-01517'),
                      pw.Text('대표이사 : 조성률'),
                      pw.Text('본사 : 대전광역시 대덕구 신일동로 105, 304호'),
                      pw.Text('업태 : 제조업, 정보통신업'),
                      pw.Text('종목 : PDAM시스템제조및공급, 응용소프트웨어개발및공급'),
                      pw.Text('TEL 070-4334-9000  FAX 042-933-0104'),
                      pw.Text('e-mail : we8104@hanmail.net'),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 26),
            pw.Container(
              color: PdfColor.fromInt(0xffd9efff),
              padding: const pw.EdgeInsets.all(10),
              child: pw.Row(
                children: [
                  pw.Expanded(child: pw.Text('아래 품목의 내역을 제출하오니 검토 바랍니다.')),
                  pw.Text(DateFormat('yyyy-MM-dd').format(DateTime.now())),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                '내역 합계 금액(Total)  ${_money(total + vat)}원 (VAT 포함)',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Divider(thickness: 2),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.white),
              cellAlignment: pw.Alignment.center,
              headers: const [
                '종목',
                '사용 기간',
                '단위',
                '수량',
                '공급가',
                '세액',
                '합계',
                '비고',
              ],
              data: [
                for (final item in statement.items)
                  [
                    'PDAM시스템 공급\n${item.elevator} ${item.installment}회',
                    '${_date(item.startDate)} ~ ${item.endDate == null ? '사용중' : _date(item.endDate!)}',
                    'SET',
                    '1',
                    _money(item.supplyAmount),
                    _money((item.supplyAmount * .1).round()),
                    _money((item.supplyAmount * 1.1).round()),
                    item.note,
                  ],
                for (var i = statement.items.length; i < 12; i++)
                  ['', '', '', '', '', '-', '-', ''],
              ],
            ),
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                '합계  ${_money(total)}  ${_money(vat)}  ${_money(total + vat)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 18),
            pw.Text('비고  *입금 계좌번호 : 기업은행 447-069557-04-028 우리기술주식회사'),
          ],
        ),
      ),
    );
    await FileSaver.instance.saveFile(
      name: '내역서_${statement.projectName}',
      bytes: await document.save(),
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
    if (context.mounted) {
      showTheWeSnackBar(context, message: '내역서를 PDF로 저장했습니다.');
    }
  } catch (error) {
    if (context.mounted) {
      showTheWeSnackBar(
        context,
        message: 'PDF 생성에 실패했습니다.',
        type: TheWeSnackBarType.error,
      );
    }
  }
}

Widget _statementCell(String value, {bool bold = false}) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
  child: Text(
    value,
    textAlign: TextAlign.center,
    maxLines: 3,
    overflow: TextOverflow.ellipsis,
    style: TheWeTextStyle.caption.copyWith(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
    ),
  ),
);

Widget _cell(String value, {bool left = false, int maxLines = 2}) => Align(
  alignment: left ? Alignment.centerLeft : Alignment.center,
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
    child: Text(
      value,
      textAlign: left ? TextAlign.left : TextAlign.center,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TheWeTextStyle.caption,
    ),
  ),
);
String _date(DateTime? value) =>
    value == null ? '-' : DateFormat('yyyy.MM.dd').format(value);
String _shortDate(DateTime? value) =>
    value == null ? '-' : DateFormat('MM.dd').format(value);
String _money(num value) => NumberFormat('#,###').format(value);

final _currencyInputFormatter = TextInputFormatter.withFunction((
  oldValue,
  newValue,
) {
  final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return const TextEditingValue();
  final formatted = _money(int.tryParse(digits) ?? 0);
  return TextEditingValue(
    text: formatted,
    selection: TextSelection.collapsed(offset: formatted.length),
  );
});

String _duration(DateTime? start, DateTime? end) {
  if (start == null) return "-";
  final days = (end ?? DateTime.now()).difference(start).inDays + 1;
  if (days <= 31) return '$days일';
  return '${days ~/ 31}개월 ${days % 31}일';
}
