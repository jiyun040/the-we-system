import 'dart:convert';

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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장하지 못했습니다. 다시 시도해 주세요.')),
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
    final rows = <List<String>>[
      [
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
        '회차',
        '상태',
        '비고',
        '분류',
      ],
      for (var index = 0; index < _items.length; index++)
        [
          '${index + 1}',
          _items[index].projectName,
          _items[index].contractor,
          _items[index].partner,
          _items[index].elevator,
          _date(_items[index].startDate),
          _date(_items[index].endDate),
          _duration(_items[index].startDate, _items[index].endDate),
          _date(_items[index].billingDate),
          _date(_items[index].invoiceDate),
          _date(_items[index].depositDate),
          '${_items[index].supplyAmount}',
          '${_items[index].installment}회차',
          _items[index].status,
          _items[index].note,
          _items[index].category,
        ],
    ];
    String escape(String value) => '"${value.replaceAll('"', '""')}"';
    final bytes = Uint8List.fromList(
      utf8.encode(
        '\uFEFF${rows.map((row) => row.map(escape).join(',')).join('\r\n')}',
      ),
    );
    await FileSaver.instance.saveFile(
      name: '매출관리대장_${_month.year}${_month.month.toString().padLeft(2, '0')}',
      bytes: bytes,
      fileExtension: 'csv',
      mimeType: MimeType.custom,
      customMimeType: 'text/csv;charset=utf-8',
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
              'PDAM DB에서 현장·호기 정보를 자동 반영합니다. 행을 눌러 청구, 계산서, 입금과 금액을 수정할 수 있습니다.',
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
      .45,
      2.6,
      1.15,
      1.2,
      .7,
      1.45,
      .9,
      .9,
      .9,
      .9,
      1.15,
      .7,
      .8,
      1.7,
      .7,
    ],
    rows: [
      for (var index = 0; index < items.length; index++)
        _row(context, index, items[index]),
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
    _cell(item.elevator),
    _cell(
      '${_date(item.startDate)}\n~ ${item.endDate == null ? '진행 중' : _date(item.endDate!)}',
    ),
    _cell(_duration(item.startDate, item.endDate)),
    _cell(_shortDate(item.billingDate)),
    _cell(_shortDate(item.invoiceDate)),
    _cell(_shortDate(item.depositDate)),
    _cell(_money(item.supplyAmount)),
    _cell('${item.installment}회차'),
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
  DateTime? billing;
  DateTime? invoice;
  DateTime? deposit;
  @override
  void initState() {
    super.initState();
    final item = widget.item;
    category = item.category;
    status = item.status;
    amount = TextEditingController(text: _money(item.supplyAmount));
    installment = TextEditingController(text: item.installment.toString());
    note = TextEditingController(text: item.note);
    billing = item.billingDate;
    invoice = item.invoiceDate;
    deposit = item.depositDate;
  }

  @override
  void dispose() {
    amount.dispose();
    installment.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> choose(String kind) async {
    final current = switch (kind) {
      'billing' => billing,
      'invoice' => invoice,
      _ => deposit,
    };
    final selected = await showTheWeDatePicker(
      context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
      title: '$kind 날짜 선택',
    );
    if (selected == null) return;
    setState(() {
      if (kind == 'billing') billing = selected;
      if (kind == 'invoice') invoice = selected;
      if (kind == 'deposit') deposit = selected;
    });
  }

  @override
  Widget build(BuildContext context) => TheWeModalSurface(
    width: 720,
    maxWidth: 720,
    maxHeightFactor: .92,
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TheWeModalHeader(
            title: '${widget.item.projectName} · ${widget.item.elevator}',
            onClose: () => Navigator.pop(context),
          ),
          const SizedBox(height: 20),
          Text('PDAM 연동 정보', style: TheWeTextStyle.section),
          const SizedBox(height: 8),
          Text(
            '${widget.item.contractor} · ${widget.item.partner}\n${_date(widget.item.startDate)} ~ ${widget.item.endDate == null ? '진행 중' : _date(widget.item.endDate!)}  (${_duration(widget.item.startDate, widget.item.endDate)})',
            style: TheWeTextStyle.body,
          ),
          const Divider(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 205,
                child: DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: '분류'),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('미분류')),
                    DropdownMenuItem(value: '본사', child: Text('본사')),
                    DropdownMenuItem(value: '가맹', child: Text('가맹')),
                  ],
                  onChanged: (value) => setState(() => category = value ?? ''),
                ),
              ),
              SizedBox(
                width: 205,
                child: DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: '상태'),
                  items: const [
                    DropdownMenuItem(value: '신규', child: Text('신규')),
                    DropdownMenuItem(value: '진행', child: Text('진행')),
                    DropdownMenuItem(value: '종료', child: Text('종료')),
                  ],
                  onChanged: (value) => setState(() => status = value ?? '신규'),
                ),
              ),
              SizedBox(
                width: 205,
                child: TextField(
                  controller: installment,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '회차'),
                ),
              ),
              SizedBox(
                width: 205,
                child: TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_currencyInputFormatter],
                  decoration: const InputDecoration(labelText: '공급가'),
                ),
              ),
              _dateButton('청구일', billing, () => choose('billing')),
              _dateButton('계산서 발행일', invoice, () => choose('invoice')),
              _dateButton('입금일', deposit, () => choose('deposit')),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: note,
            maxLines: 3,
            decoration: const InputDecoration(labelText: '비고'),
          ),
          const SizedBox(height: 10),
          Text(
            '입금액은 공급가와 부가세를 기준으로 자동 계산됩니다. 회차 1회는 신규, 2회 이상은 진행으로 정리됩니다.',
            style: TheWeTextStyle.hintText.copyWith(color: TheWeColor.black500),
          ),
          const SizedBox(height: 22),
          TheWeModalActions(
            primaryLabel: '저장',
            secondaryLabel: '취소',
            primaryColor: TheWeColor.black900,
            onSecondaryPressed: () => Navigator.pop(context),
            onPrimaryPressed: () {
              final cycle = int.tryParse(installment.text) ?? 1;
              Navigator.pop(
                context,
                widget.item.copyWith(
                  category: category,
                  status: status,
                  installment: cycle < 1 ? 1 : cycle,
                  supplyAmount:
                      int.tryParse(amount.text.replaceAll(',', '')) ?? 0,
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
          ),
        ],
      ),
    ),
  );
  Widget _dateButton(String label, DateTime? value, VoidCallback onPressed) =>
      SizedBox(
        width: 205,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
            ),
            child: Text(_date(value)),
          ),
        ),
      );
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

class _StatementDialog extends StatelessWidget {
  const _StatementDialog({required this.statement, required this.month});
  final SalesStatement statement;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final total = statement.items.fold(
      0,
      (value, item) => value + item.supplyAmount,
    );
    final vat = (total * .1).round();
    final rows = <TableRow>[
      TableRow(
        decoration: const BoxDecoration(color: TheWeColor.blueSurface),
        children: [
          for (final label in const [
            '종목',
            '사용 기간',
            '단위',
            '수량',
            '공급가',
            '세액',
            '합계',
            '비고',
          ])
            _statementCell(label, bold: true),
        ],
      ),
      for (final item in statement.items)
        TableRow(
          children: [
            _statementCell('PDAM시스템 공급\n${item.elevator}'),
            _statementCell(
              '${_date(item.startDate)} ~ ${item.endDate == null ? '진행 중' : _date(item.endDate!)}',
            ),
            _statementCell('SET'),
            _statementCell('1'),
            _statementCell(_money(item.supplyAmount)),
            _statementCell(_money((item.supplyAmount * .1).round())),
            _statementCell(_money((item.supplyAmount * 1.1).round())),
            _statementCell(item.note),
          ],
        ),
    ];
    return TheWeModalSurface(
      maxWidth: 980,
      maxHeightFactor: .92,
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TheWeModalHeader(
            title: '내 역 서',
            onClose: () => Navigator.pop(context),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: _statementInfo(
                  '수신',
                  statement.items.firstOrNull?.partner ?? '-',
                ),
              ),
              SizedBox(
                width: 280,
                child: _statementInfo('현장명', statement.projectName),
              ),
              _statementInfo(
                '발행일',
                DateFormat('yyyy-MM-dd').format(DateTime.now()),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: TheWeColor.blueSurface,
            child: Text(
              '아래 품목의 내역을 제출하오니 검토 바랍니다.  ${month.year}-${month.month.toString().padLeft(2, '0')}',
              style: TheWeTextStyle.body,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '내역 합계 금액(Total)  ${_money((total + vat))}원 (VAT 포함)',
              style: TheWeTextStyle.subtitle,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 900,
              child: Table(
                border: TableBorder.all(color: TheWeColor.blue100),
                columnWidths: const {
                  0: FlexColumnWidth(1.5),
                  1: FlexColumnWidth(2.2),
                  2: FlexColumnWidth(.7),
                  3: FlexColumnWidth(.6),
                  4: FlexColumnWidth(1.1),
                  5: FlexColumnWidth(.9),
                  6: FlexColumnWidth(1.1),
                  7: FlexColumnWidth(1.4),
                },
                children: rows,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Spacer(),
              Text(
                '합계  ${_money(total)}  ${_money(vat)}  ${_money(total + vat)}',
                style: TheWeTextStyle.subtitle,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFF4F6E9),
            child: const Text('비고  *입금 계좌번호 : 기업은행 447-069557-04-028 우리기술주식회사'),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _downloadStatementPdf(context, statement, month),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('PDF 다운로드'),
            ),
          ),
        ],
      ),
    );
  }
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
            pw.SizedBox(height: 22),
            pw.Text('수신 : ${statement.items.firstOrNull?.partner ?? '-'}'),
            pw.Text('현장명 : ${statement.projectName}'),
            pw.Text('발행일 : ${DateFormat('yyyy-MM-dd').format(DateTime.now())}'),
            pw.SizedBox(height: 16),
            pw.Container(
              color: PdfColor.fromInt(0xffd9efff),
              padding: const pw.EdgeInsets.all(10),
              child: pw.Text(
                '아래 품목의 내역을 제출하오니 검토 바랍니다.  ${month.year}-${month.month.toString().padLeft(2, '0')}',
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
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xffd9efff),
              ),
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
                    'PDAM시스템 공급\n${item.elevator}',
                    '${_date(item.startDate)} ~ ${item.endDate == null ? '진행 중' : _date(item.endDate!)}',
                    'SET',
                    '1',
                    _money(item.supplyAmount),
                    _money((item.supplyAmount * .1).round()),
                    _money((item.supplyAmount * 1.1).round()),
                    item.note,
                  ],
              ],
            ),
            pw.SizedBox(height: 14),
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

Widget _statementInfo(String label, String value) => Padding(
  padding: const EdgeInsets.only(right: 22),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TheWeTextStyle.hintText.copyWith(color: TheWeColor.black500),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TheWeTextStyle.body.copyWith(fontWeight: FontWeight.w700),
      ),
    ],
  ),
);

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

Widget _cell(String value, {bool left = false}) => Align(
  alignment: left ? Alignment.centerLeft : Alignment.center,
  child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(
      value,
      textAlign: left ? TextAlign.left : TextAlign.center,
      maxLines: 2,
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

String _duration(DateTime start, DateTime? end) {
  final days = (end ?? DateTime.now()).difference(start).inDays + 1;
  if (days <= 31) return '$days일';
  return '${days ~/ 31}개월 ${days % 31}일';
}
