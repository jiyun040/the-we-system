import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';

import 'approval_admin_dependencies.dart';
import 'approval_admin_direct_leave.dart';
import '../approval/approval_box_table_cells.dart';

class AdminComprehensiveManagement extends StatefulWidget {
  const AdminComprehensiveManagement({super.key, required this.state});

  final ApprovalDashboardState state;

  @override
  State<AdminComprehensiveManagement> createState() =>
      _AdminComprehensiveManagementState();
}

class _AdminComprehensiveManagementState
    extends State<AdminComprehensiveManagement> {
  static const _all = '전체';

  final TextEditingController _searchController = TextEditingController();
  String _status = _all;
  String _department = _all;
  String _drafter = _all;
  String _form = _all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.state.canAccessComprehensiveManagement) {
      return Container(
        key: const ValueKey('comprehensive-management-access-denied'),
        width: double.infinity,
        padding: const EdgeInsets.all(36),
        decoration: adminSurface(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 40, color: TheWeColor.black500),
            const SizedBox(height: 12),
            Text('슈퍼 어드민 전용 메뉴입니다.', style: TheWeTextStyle.subtitle),
          ],
        ),
      );
    }

    final allDocuments = [...widget.state.documents]
      ..sort((left, right) => right.draftedAt.compareTo(left.draftedAt));
    final documents = allDocuments.where(_matchesFilters).toList();
    final mobile = MediaQuery.sizeOf(context).width < 680;

    return Column(
      key: const ValueKey('admin-comprehensive-management-page'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '결재 종합관리',
          style: mobile
              ? TheWeTextStyle.title.copyWith(fontSize: 20)
              : TheWeTextStyle.title,
        ),
        const SizedBox(height: 6),
        Text(
          '전 직원이 작성한 결재 문서와 현재 처리 상태를 한곳에서 확인합니다.',
          style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
        ),
        const SizedBox(height: 18),
        _SummaryMetrics(documents: allDocuments),
        const SizedBox(height: 20),
        _FilterPanel(
          searchController: _searchController,
          statuses: _valuesFor(allDocuments, (document) => document.status),
          departments: _valuesFor(
            allDocuments,
            (document) => document.department,
          ),
          drafters: _valuesFor(allDocuments, (document) => document.drafter),
          forms: _valuesFor(allDocuments, (document) => document.form),
          status: _status,
          department: _department,
          drafter: _drafter,
          form: _form,
          onSearchChanged: (_) => setState(() {}),
          onStatusChanged: (value) => setState(() => _status = value),
          onDepartmentChanged: (value) => setState(() => _department = value),
          onDrafterChanged: (value) => setState(() => _drafter = value),
          onFormChanged: (value) => setState(() => _form = value),
          onReset: _resetFilters,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text('결재 문서', style: TheWeTextStyle.subtitle),
            const SizedBox(width: 8),
            Container(
              key: const ValueKey('comprehensive-result-count'),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: TheWeColor.blueSurface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${documents.length}건',
                style: TheWeTextStyle.caption.copyWith(
                  color: TheWeColor.blue300,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (documents.isEmpty)
          Container(
            key: const ValueKey('comprehensive-empty-state'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
            decoration: adminSurface(),
            child: Text(
              allDocuments.isEmpty ? '등록된 결재 문서가 없습니다.' : '조건에 맞는 결재 문서가 없습니다.',
              textAlign: TextAlign.center,
              style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
            ),
          )
        else if (mobile)
          ...documents.map(
            (document) => _DocumentCard(
              document: document,
              onTap: () => _openDocument(document.id),
            ),
          )
        else
          TheWeDataTable(
            headers: const [
              '기안일',
              '문서번호',
              '기안자',
              '기안부서',
              '결재양식',
              '제목',
              '현재 결재자',
              '진행률',
              '상태',
            ],
            columnFlexes: const [1.4, 1.5, 1.2, 1.3, 1.7, 3.2, 1.4, 1, 1.2],
            minWidth: 1280,
            onRowTaps: [
              for (final document in documents)
                () => _openDocument(document.id),
            ],
            rows: [
              for (final document in documents)
                [
                  _TableText(_displayDate(document.draftedAt)),
                  _TableText(
                    document.documentNo.trim().isEmpty
                        ? document.id
                        : document.documentNo,
                  ),
                  _TableText(document.drafter),
                  _TableText(document.department),
                  _TableText(document.form),
                  _TableText(
                    document.title.trim().isEmpty ? '-' : document.title,
                    align: TextAlign.left,
                  ),
                  _TableText(_activeApprover(document)),
                  _TableText('${document.progress}%'),
                  ApprovalDocumentStatusChip(document.status),
                ],
            ],
          ),
      ],
    );
  }

  bool _matchesFilters(ApprovalDocument document) {
    final keyword = _searchController.text.trim().toLowerCase();
    final matchesKeyword =
        keyword.isEmpty ||
        [
          document.id,
          document.documentNo,
          document.title,
          document.drafter,
          document.department,
          document.form,
          ...document.steps.map((step) => step.name),
        ].any((value) => value.toLowerCase().contains(keyword));
    return matchesKeyword &&
        (_status == _all || document.status == _status) &&
        (_department == _all || document.department == _department) &&
        (_drafter == _all || document.drafter == _drafter) &&
        (_form == _all || document.form == _form);
  }

  List<String> _valuesFor(
    List<ApprovalDocument> documents,
    String Function(ApprovalDocument document) selector,
  ) {
    final values =
        documents
            .map(selector)
            .where((value) => value.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return [_all, ...values];
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _status = _all;
      _department = _all;
      _drafter = _all;
      _form = _all;
    });
  }

  void _openDocument(String id) {
    context.pushNamed(AppRouteName.detail, pathParameters: {'id': id});
  }
}

class _SummaryMetrics extends StatelessWidget {
  const _SummaryMetrics({required this.documents});

  final List<ApprovalDocument> documents;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth < 600 ? 2 : 4;
      final spacing = 12.0;
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      final metrics = [
        (
          icon: Icons.description_outlined,
          label: '전체 문서',
          count: documents.length,
        ),
        (
          icon: Icons.hourglass_top_outlined,
          label: '결재 진행',
          count: documents
              .where(
                (document) =>
                    document.status == '결재대기' || document.status == '진행중',
              )
              .length,
        ),
        (
          icon: Icons.task_alt_outlined,
          label: '결재 완료',
          count: documents.where((document) => document.status == '완료').length,
        ),
        (
          icon: Icons.keyboard_return_outlined,
          label: '반려',
          count: documents.where((document) => document.status == '반려').length,
        ),
      ];
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final metric in metrics)
            AdminMetric(
              width: width,
              icon: metric.icon,
              label: metric.label,
              value: '${metric.count}건',
            ),
        ],
      );
    },
  );
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.searchController,
    required this.statuses,
    required this.departments,
    required this.drafters,
    required this.forms,
    required this.status,
    required this.department,
    required this.drafter,
    required this.form,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onDepartmentChanged,
    required this.onDrafterChanged,
    required this.onFormChanged,
    required this.onReset,
  });

  final TextEditingController searchController;
  final List<String> statuses;
  final List<String> departments;
  final List<String> drafters;
  final List<String> forms;
  final String status;
  final String department;
  final String drafter;
  final String form;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onDepartmentChanged;
  final ValueChanged<String> onDrafterChanged;
  final ValueChanged<String> onFormChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final filters = [
      (
        label: '상태',
        value: status,
        values: statuses,
        onChanged: onStatusChanged,
      ),
      (
        label: '부서',
        value: department,
        values: departments,
        onChanged: onDepartmentChanged,
      ),
      (
        label: '기안자',
        value: drafter,
        values: drafters,
        onChanged: onDrafterChanged,
      ),
      (label: '결재양식', value: form, values: forms, onChanged: onFormChanged),
    ];
    return Container(
      key: const ValueKey('comprehensive-filters'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: adminSurface(),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 280,
            child: TextField(
              key: const ValueKey('comprehensive-search'),
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                labelText: '문서 검색',
                hintText: '제목, 기안자, 문서번호 검색',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          for (final filter in filters)
            _FilterDropdown(
              label: filter.label,
              value: filter.value,
              values: filter.values,
              onChanged: filter.onChanged,
            ),
          TextButton.icon(
            key: const ValueKey('comprehensive-filter-reset'),
            onPressed: onReset,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('초기화'),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 150,
    child: DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: values.contains(value) ? value : values.first,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        for (final item in values)
          DropdownMenuItem(value: item, child: Text(item)),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    ),
  );
}

class _TableText extends StatelessWidget {
  const _TableText(this.text, {this.align = TextAlign.center});

  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    textAlign: align,
    style: TheWeTextStyle.body,
  );
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document, required this.onTap});

  final ApprovalDocument document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('comprehensive-document-${document.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: adminSurface(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      document.title.trim().isEmpty ? '-' : document.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TheWeTextStyle.subtitle.copyWith(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ApprovalDocumentStatusChip(document.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${document.drafter} · ${document.department} · ${document.form}',
                style: TheWeTextStyle.body,
              ),
              const SizedBox(height: 5),
              Text(
                '${_displayDate(document.draftedAt)} · ${document.documentNo.trim().isEmpty ? document.id : document.documentNo} · 현재 결재자 ${_activeApprover(document)}',
                style: TheWeTextStyle.caption.copyWith(
                  color: TheWeColor.black500,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _activeApprover(ApprovalDocument document) {
  return document.steps
          .where((step) => step.status == '진행중')
          .firstOrNull
          ?.name ??
      '-';
}

String _displayDate(String value) =>
    value.replaceFirst('T', ' ').split(' ').first;
