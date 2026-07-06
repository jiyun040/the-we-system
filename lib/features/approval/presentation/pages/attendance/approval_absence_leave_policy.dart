part of 'approval_absence_page.dart';

class _LeavePolicySection extends StatelessWidget {
  const _LeavePolicySection({required this.accounts});

  final List<EmployeeAccount> accounts;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _LeavePolicyCardData(
        id: 'default',
        badge: '기본 정책',
        title: '기본 그룹',
        lines: ['회계연도 기준 (01-01) · 1일', '연차 초과 사용 불가'],
        defaultDepartment: '회계',
      ),
      _LeavePolicyCardData(
        id: 'exception',
        badge: '예외 정책',
        title: '연차 미발생 그룹',
        lines: ['회계연도 기준 (01-01) · 1일', '연차 초과 사용 불가'],
        defaultDepartment: '교육',
      ),
      _LeavePolicyCardData(
        id: 'limited',
        badge: '제한 정책',
        title: '휴가 제한 그룹',
        lines: ['회계연도 기준 (01-01) · 1일', '특정 기간 제한 적용'],
        defaultDepartment: '개발',
      ),
    ];

    return _SectionCard(
      title: '연차정책 관리',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final singleColumn = constraints.maxWidth < 980;
          final widgets = cards
              .map(
                (card) => _LeavePolicyGroupCard(data: card, accounts: accounts),
              )
              .toList();

          if (singleColumn) {
            return Column(
              children: [
                for (var index = 0; index < widgets.length; index++) ...[
                  widgets[index],
                  if (index != widgets.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < widgets.length; index++) ...[
                Expanded(child: widgets[index]),
                if (index != widgets.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _LeavePolicyCardData {
  const _LeavePolicyCardData({
    required this.id,
    required this.badge,
    required this.title,
    required this.lines,
    required this.defaultDepartment,
  });

  final String id;
  final String badge;
  final String title;
  final List<String> lines;
  final String defaultDepartment;
}

class _LeavePolicyGroupCard extends StatefulWidget {
  const _LeavePolicyGroupCard({required this.data, required this.accounts});

  final _LeavePolicyCardData data;
  final List<EmployeeAccount> accounts;

  @override
  State<_LeavePolicyGroupCard> createState() => _LeavePolicyGroupCardState();
}

class _LeavePolicyGroupCardState extends State<_LeavePolicyGroupCard> {
  late List<EmployeeAccount> _selectedAccounts;

  @override
  void initState() {
    super.initState();
    _selectedAccounts = widget.accounts
        .where((item) => item.department == widget.data.defaultDepartment)
        .take(3)
        .toList();
  }

  Future<void> _openPicker() async {
    final result = await showDialog<List<EmployeeAccount>>(
      context: context,
      builder: (context) => _LeavePolicyMemberDialog(
        accounts: widget.accounts,
        initialSelected: _selectedAccounts,
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _selectedAccounts = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: TheWeColor.blue100.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(widget.data.badge, style: TheWeTextStyle.caption),
          ),
          const SizedBox(height: 18),
          Text(widget.data.title, style: TheWeTextStyle.title),
          const SizedBox(height: 14),
          ...widget.data.lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                line,
                style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _openPicker,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: TheWeColor.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: TheWeColor.black300.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 18,
                    color: TheWeColor.blue300,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '적용 인원',
                      style: TheWeTextStyle.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${_selectedAccounts.length}명',
                    style: TheWeTextStyle.subtitle.copyWith(
                      color: TheWeColor.blue300,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: TheWeColor.black500,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeavePolicyMemberDialog extends StatefulWidget {
  const _LeavePolicyMemberDialog({
    required this.accounts,
    required this.initialSelected,
  });

  final List<EmployeeAccount> accounts;
  final List<EmployeeAccount> initialSelected;

  @override
  State<_LeavePolicyMemberDialog> createState() =>
      _LeavePolicyMemberDialogState();
}

class _LeavePolicyMemberDialogState extends State<_LeavePolicyMemberDialog> {
  late final List<String> _departments;
  late Set<String> _selectedIds;
  late String _selectedDepartment;

  @override
  void initState() {
    super.initState();
    _departments =
        widget.accounts.map((item) => item.department).toSet().toList()..sort();
    _selectedDepartment = _departments.isEmpty ? '' : _departments.first;
    _selectedIds = widget.initialSelected.map((item) => item.id).toSet();
  }

  void _selectAll() {
    setState(() {
      _selectedIds = widget.accounts.map((item) => item.id).toSet();
    });
  }

  void _clearAll() {
    setState(_selectedIds.clear);
  }

  void _selectDepartment() {
    setState(() {
      _selectedIds = _visibleAccounts
          .where((item) => item.department == _selectedDepartment)
          .map((item) => item.id)
          .toSet();
    });
  }

  List<EmployeeAccount> get _visibleAccounts {
    if (_selectedDepartment.isEmpty) {
      return widget.accounts;
    }

    return widget.accounts
        .where((item) => item.department == _selectedDepartment)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedAccounts = widget.accounts
        .where((item) => _selectedIds.contains(item.id))
        .toList();
    final visibleAccounts = _visibleAccounts;

    return AlertDialog(
      backgroundColor: TheWeColor.white,
      surfaceTintColor: TheWeColor.white,
      title: Text('적용 인원 선택', style: TheWeTextStyle.title),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _selectAll,
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('전체 선택'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('전체 삭제'),
                  ),
                  Container(
                    width: 150,
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: TheWeColor.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: TheWeColor.black300.withValues(alpha: 0.35),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDepartment.isEmpty
                            ? null
                            : _selectedDepartment,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(16),
                        dropdownColor: TheWeColor.white,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        style: TheWeTextStyle.body,
                        items: _departments
                            .map(
                              (department) => DropdownMenuItem(
                                value: department,
                                child: Text(department),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => _selectedDepartment = value);
                        },
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _departments.isEmpty ? null : _selectDepartment,
                    icon: const Icon(Icons.business_outlined, size: 18),
                    style: FilledButton.styleFrom(
                      backgroundColor: TheWeColor.blue300,
                      foregroundColor: Colors.white,
                    ),
                    label: const Text('해당 부서만 선택'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '$_selectedDepartment 직원 목록',
                style: TheWeTextStyle.body.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: visibleAccounts
                    .map(
                      (account) => FilterChip(
                        selected: _selectedIds.contains(account.id),
                        label: Text(
                          '${account.name} · ${account.department} · ${account.position}',
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedIds.add(account.id);
                            } else {
                              _selectedIds.remove(account.id);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
              Text(
                '선택된 인원 ${selectedAccounts.length}명',
                style: TheWeTextStyle.body.copyWith(
                  color: TheWeColor.blue300,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(selectedAccounts),
          style: FilledButton.styleFrom(backgroundColor: TheWeColor.blue300),
          child: const Text('적용'),
        ),
      ],
    );
  }
}
