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
  bool _overdueOnly = false;
  bool _loading = true;
  int _loadVersion = 0;
  String? _error;
  List<SalesLedgerEntry> _allItems = const [];
  List<SalesLedgerEntry> _items = const [];
  SalesLedgerSummary _summary = const SalesLedgerSummary(
    supplyAmount: 0,
    billCount: 0,
    unbilledCount: 0,
    unissuedInvoiceCount: 0,
    unpaidAmount: 0,
  );
  List<SalesLedgerArchive> _archives = const [];

  SalesApiService get _api => SalesApiService(ref.read(dioProvider));

  @override
  void initState() {
    super.initState();
    _load();
    _loadArchives();
  }

  Future<void> _loadArchives() async {
    try {
      final archives = await _api.fetchArchives();
      if (mounted) setState(() => _archives = archives);
    } catch (_) {}
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final query = _normalizeSearchText(_search.text);
    final matching = query.isEmpty
        ? _allItems
        : _allItems
              .where(
                (item) => [
                  item.projectName,
                  item.contractor,
                  item.partner,
                  item.note,
                ].any((value) => _normalizeSearchText(value).contains(query)),
              )
              .toList();
    final statusItems = _status.isEmpty
        ? matching
        : matching.where((item) => item.status == _status).toList();
    _items = _overdueOnly
        ? statusItems.where(_isOverdueUnpaid).toList()
        : statusItems;
    _summary = SalesLedgerSummary.fromEntries(_items);
  }

  String _normalizeSearchText(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), '');

  Future<void> _load() async {
    final version = ++_loadVersion;
    final month = _month;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _api.fetchLedger(month: month);
      final sorted = classifyAndSortLedger(
        result.items,
        const [],
        month: month,
      );
      if (!mounted || version != _loadVersion) return;
      setState(() {
        _allItems = sorted;
        _applyFilters();
        _loading = false;
      });
    } catch (_) {
      if (mounted && version == _loadVersion) {
        setState(() {
          _loading = false;
          _error = '매출관리대장을 불러오지 못했습니다.';
        });
      }
    }
  }

  Future<void> _changeMonth(int delta) async {
    final next = DateTime(_month.year, _month.month + delta);
    final thisYear = DateTime.now().year;
    if (next.year != thisYear) return;
    setState(() => _month = next);
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
      overdueOnly: _overdueOnly,
      onSearch: () => setState(_applyFilters),
      onStatus: (value) {
        setState(() {
          _status = value;
          _overdueOnly = false;
          _applyFilters();
        });
      },
      onOverdueChanged: (value) {
        setState(() {
          _overdueOnly = value;
          if (value) _status = '';
          _applyFilters();
        });
      },
      onPrevious: () => _changeMonth(-1),
      onNext: () => _changeMonth(1),
      onPickMonth: _pickMonth,
      onExport: _exportExcel,
      onExportYear: _exportYearlyArchive,
      archives: _archives,
      onDownloadArchive: (archive) async {
        final bytes = await _api.downloadArchive(archive.year);
        await FileSaver.instance.saveFile(
          name: '매출관리대장_${archive.year}년_연간보관',
          bytes: bytes,
          fileExtension: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
      },
      onOpenArchives: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _SalesLedgerArchivesPage(api: _api)),
      ),
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
    final currentSelectedMonth = _month.month;
    final month = await showDialog<int>(
      context: context,
      builder: (dialogContext) => TheWeModalSurface(
        width: 360,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TheWeModalHeader(
              title: '조회할 월 선택',
              onClose: () => Navigator.pop(dialogContext),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.4,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final m = index + 1;
                final isSelected = m == currentSelectedMonth;
                return InkWell(
                  onTap: () => Navigator.pop(dialogContext, m),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? TheWeColor.blue300
                          : TheWeColor.blue100.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? TheWeColor.blue300
                            : Colors.transparent,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$m월',
                      style: TheWeTextStyle.subtitle.copyWith(
                        color: isSelected
                            ? TheWeColor.white
                            : TheWeColor.black900,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
    if (month == null) return;
    setState(() => _month = DateTime(DateTime.now().year, month));
    await _load();
  }

  Future<void> _exportYearlyArchive() async {
    try {
      final year = DateTime.now().year;
      final monthly = <int, List<SalesLedgerEntry>>{};
      for (var month = 1; month <= 12; month++) {
        final response = await _api.fetchLedger(month: DateTime(year, month));
        monthly[month] = classifyAndSortLedger(
          response.items,
          month == 1
              ? const []
              : (monthly[month - 1] ?? const <SalesLedgerEntry>[]),
          month: DateTime(year, month),
        );
      }
      final bytes = await annualLedgerTemplateXlsx(monthly, year);
      await _api.uploadArchive(
        year: year,
        bytes: bytes,
        filename: '매출관리대장_$year년_연간보관.xlsx',
      );
      await _loadArchives();
      if (mounted) {
        showTheWeSnackBar(context, message: '$year년 매출관리대장을 보관했습니다.');
      }
    } catch (error) {
      if (mounted) {
        showTheWeSnackBar(
          context,
          message: userFacingErrorMessage(
            error,
            fallback: '연간 매출관리대장을 보관하지 못했습니다.',
          ),
          type: TheWeSnackBarType.error,
        );
      }
    }
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

class _SalesLedgerArchivesPage extends StatefulWidget {
  const _SalesLedgerArchivesPage({required this.api});
  final SalesApiService api;
  @override
  State<_SalesLedgerArchivesPage> createState() =>
      _SalesLedgerArchivesPageState();
}

class _SalesLedgerArchivesPageState extends State<_SalesLedgerArchivesPage> {
  List<SalesLedgerArchive> _items = const [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await widget.api.fetchArchives();
    if (mounted) setState(() => _items = items);
  }

  Future<void> _rename(SalesLedgerArchive item) async {
    final controller = TextEditingController(
      text: item.name.replaceAll(RegExp(r'\.xlsx$'), ''),
    );
    final name = await showDialog<String>(
      context: context,
      builder: (context) => TheWeModalSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TheWeModalHeader(
              title: '파일 이름 수정',
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 18),
            TextField(controller: controller, autofocus: true),
            const SizedBox(height: 18),
            TheWeModalActions(
              primaryLabel: '저장',
              secondaryLabel: '취소',
              onPrimaryPressed: () => Navigator.pop(context, controller.text),
              onSecondaryPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;
    await widget.api.renameArchive(item.year, name.trim());
    await _load();
  }

  Future<void> _download(SalesLedgerArchive item) async {
    final bytes = await widget.api.downloadArchive(item.year);
    await FileSaver.instance.saveFile(
      name: item.name.replaceAll(RegExp(r'\.xlsx$'), ''),
      bytes: bytes,
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  Future<void> _delete(SalesLedgerArchive item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => TheWeConfirmDialog(
        title: '보관 파일을 삭제할까요?',
        message: '${item.year}년 매출관리대장이 삭제됩니다.',
        primaryLabel: '삭제',
        primaryColor: TheWeColor.danger,
        onPrimaryPressed: () => Navigator.pop(context, true),
        onSecondaryPressed: () => Navigator.pop(context, false),
      ),
    );
    if (confirmed != true) return;
    await widget.api.deleteArchive(item.year);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).width < 520;
    return Scaffold(
      backgroundColor: TheWeColor.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isPhone ? 18 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: '뒤로가기',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: TheWeColor.black900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '보관된 연간 매출관리대장',
                      style:
                          (isPhone
                                  ? TheWeTextStyle.title
                                  : TheWeTextStyle.pageTitle)
                              .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 56),
                child: Text(
                  '해당 리스트 클릭 시 파일이 다운로드되며, 파일명 수정이 가능합니다.',
                  style: TheWeTextStyle.caption.copyWith(
                    color: TheWeColor.black500,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: _items.isEmpty
                    ? Center(
                        child: Text(
                          '보관된 연간 매출관리대장이 없습니다.',
                          style: TheWeTextStyle.body.copyWith(
                            color: TheWeColor.black500,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
                              color: TheWeColor.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: TheWeColor.black300.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 6,
                                ),
                                leading: const Icon(
                                  Icons.description_outlined,
                                  color: TheWeColor.green,
                                ),
                                title: Text(
                                  '${item.year}년 매출관리대장',
                                  style: TheWeTextStyle.body.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: TheWeTextStyle.caption,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '보관일 ${_formatArchiveDate(item.updatedAt)}',
                                      style: TheWeTextStyle.caption.copyWith(
                                        fontSize: 11,
                                        color: TheWeColor.black500,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _download(item),
                                trailing: Wrap(
                                  children: [
                                    IconButton(
                                      tooltip: '파일 이름 수정',
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _rename(item),
                                    ),
                                    IconButton(
                                      tooltip: '삭제',
                                      color: TheWeColor.danger,
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _delete(item),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatArchiveDate(DateTime value) {
  final local = value.toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${local.year}.${twoDigits(local.month)}.${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
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
    required this.overdueOnly,
    required this.onSearch,
    required this.onStatus,
    required this.onOverdueChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onPickMonth,
    required this.onExport,
    required this.onExportYear,
    required this.archives,
    required this.onDownloadArchive,
    required this.onOpenArchives,
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
  final bool overdueOnly;
  final VoidCallback onSearch;
  final ValueChanged<String> onStatus;
  final ValueChanged<bool> onOverdueChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPickMonth;
  final VoidCallback onExport;
  final VoidCallback onExportYear;
  final List<SalesLedgerArchive> archives;
  final Future<void> Function(SalesLedgerArchive) onDownloadArchive;
  final VoidCallback onOpenArchives;
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
      ...[
        OutlinedButton.icon(
          onPressed: onOpenArchives,
          icon: const Icon(Icons.folder_open),
          label: const Text('보관된 연간 매출관리대장 열기'),
        ),
        const SizedBox(height: 16),
      ],
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
        hintText: '공사명, 시공사, 협력사, 비고 검색',
        prefixIcon: Icon(Icons.search),
      ),
    ),
  );

  List<Widget> _statusChips() => [
    for (final status in const ['', '신규', '진행', '종료'])
      ChoiceChip(
        label: Text(status.isEmpty ? '전체' : status),
        selected: !overdueOnly && selectedStatus == status,
        onSelected: (_) => onStatus(status),
      ),
    ChoiceChip(
      label: const Text('60일 초과 미입금 현장'),
      selected: overdueOnly,
      onSelected: onOverdueChanged,
    ),
  ];

  List<Widget> _navigationControls() => [
    OutlinedButton.icon(
      onPressed: onExport,
      icon: const Icon(Icons.download_outlined, size: 18),
      label: const Text('엑셀 내보내기'),
    ),
    OutlinedButton.icon(
      onPressed: onExportYear,
      icon: const Icon(Icons.archive_outlined, size: 18),
      label: const Text('올해 연간 보관'),
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
            ((col == 2 && _issuerType(item) == '시공사') ||
                    (col == 3 && _issuerType(item) == '협력사'))
                ? _issuerColor(item)
                : ((col == 7 && item.billingDate == null) ||
                      (col == 8 && item.invoiceDate == null) ||
                      (col == 9 && item.depositDate == null))
                ? TheWeColor.danger.withValues(alpha: .12)
                : null,
        ],
    ],
    onRowTaps: [for (final item in items) () => onEdit(item)],
  );
  List<Widget> _row(BuildContext context, int index, SalesLedgerEntry item) => [
    _cell('${index + 1}', maxLines: 1, fitToWidth: true),
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
    _cell(
      _duration(item.startDate, item.endDate),
      maxLines: 1,
      fitToWidth: true,
    ),
    _cell(_shortDate(item.billingDate)),
    _cell(_shortDate(item.invoiceDate)),
    _cell(_shortDate(item.depositDate)),
    _cell(_money(item.supplyAmount), maxLines: 1, fitToWidth: true),
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

String _mergeNote(String note, String reason) {
  final n = note.trim();
  final r = reason.trim();
  if (r.isEmpty) return n;
  if (n.isEmpty || n.contains(r)) return n.isEmpty ? r : n;
  return '$n / $r';
}

bool _isOverdueUnpaid(SalesLedgerEntry item) {
  final invoice = item.invoiceDate;
  if (invoice == null || item.depositDate != null) return false;
  final today = DateTime.now();
  return today.difference(invoice).inDays >= 60;
}

String _issuerType(SalesLedgerEntry item) => item.invoiceIssuerType;

Color _issuerColor(SalesLedgerEntry item) => const Color(0xFFE8F5E9);
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

Widget _cell(
  String value, {
  bool left = false,
  int maxLines = 2,
  bool fitToWidth = false,
}) => Align(
  alignment: left ? Alignment.centerLeft : Alignment.center,
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
    child: fitToWidth
        ? FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: TheWeTextStyle.caption,
            ),
          )
        : Text(
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
