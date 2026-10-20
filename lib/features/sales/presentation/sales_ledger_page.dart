import 'package:the_we_system/core/network/api_exception.dart';
import 'package:the_we_system/features/sales/export/sales_template_workbook.dart';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'sales_statement_preview.dart';
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
import 'package:the_we_system/features/sales/domain/sales_ledger_order.dart';
import 'package:the_we_system/features/sales/domain/sales_ledger_card_metrics.dart';

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
      final result = await _api.fetchLedger(month: _month, query: _search.text);
      final previous = await _api.fetchLedger(
        month: DateTime(_month.year, _month.month - 1),
      );
      final sorted = classifyAndSortLedger(result.items, previous.items);
      if (!mounted) return;
      setState(() {
        _items = _status.isEmpty
            ? sorted
            : sorted.where((item) => item.status == _status).toList();
        _summary = SalesLedgerSummary.fromEntries(_items);
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
    await FileSaver.instance.saveFile(
      name: '매출관리대장_${_month.year}${_month.month.toString().padLeft(2, '0')}',
      bytes: await ledgerTemplateXlsx(_items, _month),
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
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
    final content = <Widget>[
      Text(
        '매출관리대장',
        style: (compact ? TheWeTextStyle.title : TheWeTextStyle.pageTitle)
            .copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 6),
      Text(
        'PDAM DB에서 현장·호기 정보를 자동 반영합니다. 행을 눌러 청구, 계산서, 입금과 금액을 수정할 수 있으며, 공사명을 눌러 내역서를 확인할 수 있습니다.',
        style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
      ),
      const SizedBox(height: 22),
      _SummaryCards(summary: summary, items: items, month: month),
      const SizedBox(height: 20),
      if (compact) ...[
        _searchField(fullWidth: true),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: _statusChips()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: _navigationControls(),
        ),
      ] else
        Row(children: _toolbarChildren()),
      const SizedBox(height: 16),
    ];
    Widget table() => loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(child: Text(error!))
        : _LedgerTable(items: items, onEdit: onEdit, onStatement: onStatement);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(compact ? 18 : 28),
        child: compact
            ? LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...content,
                      SizedBox(height: constraints.maxHeight, child: table()),
                    ],
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...content,
                  Expanded(child: table()),
                ],
              ),
      ),
    );
  }

  Widget _searchField({required bool fullWidth}) => SizedBox(
    width: fullWidth ? double.infinity : 300,
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
  );

  List<Widget> _statusChips() => [
    for (final status in const ['', '신규', '진행', '종료'])
      ChoiceChip(
        label: Text(status.isEmpty ? '전체' : status),
        selected: selectedStatus == status,
        onSelected: (_) => onStatus(status),
      ),
  ];

  List<Widget> _navigationControls() => [
    OutlinedButton.icon(
      onPressed: onExport,
      icon: const Icon(Icons.download_outlined, size: 18),
      label: const Text('엑셀 내보내기'),
    ),
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

  List<Widget> _toolbarChildren() => [
    _searchField(fullWidth: false),
    const SizedBox(width: 8),
    for (final chip in _statusChips()) ...[chip, const SizedBox(width: 8)],
    const Spacer(),
    for (final control in _navigationControls()) ...[
      control,
      const SizedBox(width: 8),
    ],
  ];
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({
    required this.summary,
    required this.items,
    required this.month,
  });
  final SalesLedgerSummary summary;
  final List<SalesLedgerEntry> items;
  final DateTime month;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final metrics = SalesLedgerCardMetrics.fromEntries(items, month);
      final cards = [
        ('공급가 합계', _money(summary.supplyAmount), 'VAT 별도', TheWeColor.black900),
        (
          '청구 건수',
          '${summary.billCount}건',
          '현장 ${metrics.billedSiteCount}곳',
          TheWeColor.black900,
        ),
        (
          '미청구',
          '${summary.unbilledCount}건',
          '예상 ${_money(metrics.estimatedUnbilledAmount)}',
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
          '현장 ${metrics.unpaidSiteCount}곳',
          TheWeColor.danger,
        ),
      ];
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: TheWeColor.blue100),
          borderRadius: BorderRadius.circular(14),
        ),
        child: constraints.maxWidth < 600
            ? Column(
                children: [
                  for (var index = 0; index < cards.length; index += 2)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _summaryCard(cards[index])),
                        Expanded(
                          child: index + 1 < cards.length
                              ? _summaryCard(cards[index + 1])
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                ],
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

  Widget _summaryCard((String, String, String, Color) card) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
    child: Column(
      children: [
        Text(
          card.$1,
          textAlign: TextAlign.center,
          style: TheWeTextStyle.hintText.copyWith(color: TheWeColor.black500),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            card.$2,
            style: TheWeTextStyle.subtitle.copyWith(color: card.$4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          card.$3,
          textAlign: TextAlign.center,
          style: TheWeTextStyle.hintText.copyWith(color: TheWeColor.black500),
        ),
      ],
    ),
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
              '계약기간  ${_date(item.contractStartDate ?? item.startDate)} ~ ${(item.contractEndDate ?? item.endDate) == null ? '사용중' : _date(item.contractEndDate ?? item.endDate)}',
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
                  '조정액 (네고)',
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
              '전월 사용내역이 있는 현장은 진행, 이번 달 처음 들어온 현장은 신규로 표시됩니다. 종료는 PDAM 종료 상태 또는 작업 완료 시 사용합니다.',
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
  Widget build(BuildContext context) => TheWeModalSurface(
    maxWidth: 1000,
    maxHeightFactor: .94,
    padding: const EdgeInsets.all(18),
    child: Column(
      children: [
        TheWeModalHeader(title: '내역서', onClose: () => Navigator.pop(context)),
        Expanded(
          child: SalesStatementPreview(
            statement: statement,
            issued: DateTime.now(),
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _downloadStatementExcel(context, statement),
              icon: const Icon(Icons.table_view_outlined),
              label: const Text('엑셀 다운로드'),
            ),
            FilledButton.icon(
              onPressed: () => _downloadStatementPdf(context, statement, month),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('PDF 다운로드'),
            ),
          ],
        ),
      ],
    ),
  );
}

Future<void> _downloadStatementExcel(
  BuildContext context,
  SalesStatement statement,
) async {
  await FileSaver.instance.saveFile(
    name: '내역서_${statement.projectName}',
    bytes: await statementTemplateXlsx(statement),
    fileExtension: 'xlsx',
    mimeType: MimeType.microsoftExcel,
  );
  if (context.mounted) showTheWeSnackBar(context, message: '엑셀 파일로 저장했습니다.');
}

Future<void> _downloadStatementPdf(
  BuildContext context,
  SalesStatement statement,
  DateTime month,
) async {
  try {
    await FileSaver.instance.saveFile(
      name: '내역서_${statement.projectName}',
      bytes: await statementTemplatePdf(statement),
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
