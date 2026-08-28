import 'approval_admin_dependencies.dart';
import 'approval_admin_direct_leave.dart';

class AdminDocumentAccessManagement extends ConsumerStatefulWidget {
  const AdminDocumentAccessManagement({super.key, required this.state});

  final ApprovalDashboardState state;

  @override
  ConsumerState<AdminDocumentAccessManagement> createState() =>
      _DocumentAccessManagementState();
}

class _DocumentAccessManagementState
    extends ConsumerState<AdminDocumentAccessManagement> {
  String selectedCategory = '';
  late Set<String> draftWideCategories;
  late Map<String, Set<String>> draftViewerIds;

  List<String> get categories => widget.state.activeFormTemplates
      .map((template) => template.category)
      .where((category) => category.isNotEmpty)
      .toSet()
      .toList();

  @override
  void initState() {
    super.initState();
    draftWideCategories = {...widget.state.organizationWideDocumentCategories};
    draftViewerIds = {
      for (final entry in widget.state.documentCategoryViewerIds.entries)
        entry.key: {...entry.value},
    };
    selectedCategory = categories.firstOrNull ?? '';
  }

  bool _isOrganizationWide(String category) =>
      draftWideCategories.contains(category) ||
      !draftViewerIds.containsKey(category);

  void _updateDraft({
    required bool organizationWide,
    required Set<String> userIds,
  }) {
    setState(() {
      if (organizationWide) {
        draftWideCategories.add(selectedCategory);
      } else {
        draftWideCategories.remove(selectedCategory);
      }
      draftViewerIds[selectedCategory] = {...userIds};
    });
  }

  void _save() {
    final notifier = ref.read(approvalDashboardControllerProvider.notifier);
    for (final category in categories) {
      notifier.updateDocumentCategoryAccess(
        category: category,
        organizationWide: _isOrganizationWide(category),
        userIds: draftViewerIds[category] ?? const <String>{},
      );
    }
    showTheWeSnackBar(context, message: '결재 문서 열람 권한을 저장했습니다.');
  }

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('admin-document-access-page'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('결재 문서 관리', style: TheWeTextStyle.title),
                const SizedBox(height: 6),
                Text(
                  '결재 구분을 선택한 뒤 문서를 열람할 사용자를 설정합니다.',
                  style: TheWeTextStyle.body.copyWith(
                    color: TheWeColor.black500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            key: const ValueKey('admin-document-access-save'),
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: TheWeColor.blue300,
              foregroundColor: TheWeColor.white,
              minimumSize: const Size(96, 46),
            ),
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('저장'),
          ),
        ],
      ),
      const SizedBox(height: 22),
      LayoutBuilder(
        builder: (context, constraints) {
          final categorySelector = _DocumentAccessCategorySelector(
            categories: categories,
            selectedCategory: selectedCategory,
            onSelected: (category) =>
                setState(() => selectedCategory = category),
          );
          final accessPanel = _DocumentCategoryAccessPanel(
            category: selectedCategory,
            accounts: widget.state.accounts,
            organizationWide: _isOrganizationWide(selectedCategory),
            selectedUserIds:
                draftViewerIds[selectedCategory] ?? const <String>{},
            onChanged: _updateDraft,
          );
          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                categorySelector,
                const SizedBox(height: 12),
                accessPanel,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 210, child: categorySelector),
              const SizedBox(width: 18),
              Expanded(child: accessPanel),
            ],
          );
        },
      ),
    ],
  );
}

class _DocumentAccessCategorySelector extends StatelessWidget {
  const _DocumentAccessCategorySelector({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('document-access-category'),
    padding: const EdgeInsets.all(10),
    decoration: adminSurface(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Text('결재 구분', style: TheWeTextStyle.subtitle),
        ),
        for (final category in categories)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Material(
              color: selectedCategory == category
                  ? TheWeColor.blueSurface
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              child: InkWell(
                key: ValueKey('document-access-category-$category'),
                onTap: () => onSelected(category),
                borderRadius: BorderRadius.circular(9),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 19,
                        color: selectedCategory == category
                            ? TheWeColor.blue300
                            : TheWeColor.black500,
                      ),
                      const SizedBox(width: 9),
                      Text(category),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _DocumentCategoryAccessPanel extends StatefulWidget {
  const _DocumentCategoryAccessPanel({
    required this.category,
    required this.accounts,
    required this.organizationWide,
    required this.selectedUserIds,
    required this.onChanged,
  });

  final String category;
  final List<EmployeeAccount> accounts;
  final bool organizationWide;
  final Set<String> selectedUserIds;
  final void Function({
    required bool organizationWide,
    required Set<String> userIds,
  })
  onChanged;

  @override
  State<_DocumentCategoryAccessPanel> createState() =>
      _DocumentCategoryAccessPanelState();
}

class _DocumentCategoryAccessPanelState
    extends State<_DocumentCategoryAccessPanel> {
  @override
  Widget build(BuildContext context) {
    final selectedAccounts = widget.accounts
        .where((account) => widget.selectedUserIds.contains(account.id))
        .toList();
    return Container(
      key: ValueKey('document-access-${widget.category}'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TheWeColor.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TheWeColor.black300.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.category} 문서 열람 권한', style: TheWeTextStyle.subtitle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 18,
            runSpacing: 4,
            children: [
              _AccessScopeOption(
                label: '전체 사용자',
                selected: widget.organizationWide,
                onTap: () => widget.onChanged(
                  organizationWide: true,
                  userIds: widget.selectedUserIds,
                ),
              ),
              _AccessScopeOption(
                label: '일부 사용자',
                selected: !widget.organizationWide,
                onTap: () => widget.onChanged(
                  organizationWide: false,
                  userIds: widget.selectedUserIds,
                ),
              ),
            ],
          ),
          if (!widget.organizationWide) ...[
            const SizedBox(height: 10),
            Text(
              '열람 대상',
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Material(
                color: TheWeColor.white,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  key: ValueKey('document-access-selector-${widget.category}'),
                  onTap: _selectUsers,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: TheWeColor.black300.withValues(alpha: .45),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_tree_outlined,
                          color: TheWeColor.blue300,
                          size: 21,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            selectedAccounts.isEmpty
                                ? '조직도에서 사용자 또는 부서 선택'
                                : '${selectedAccounts.length}명 선택됨',
                            style: TheWeTextStyle.body,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (selectedAccounts.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: selectedAccounts
                    .map(
                      (account) => InputChip(
                        label: Text('${account.name} · ${account.department}'),
                        onDeleted: () {
                          widget.onChanged(
                            organizationWide: false,
                            userIds: {...widget.selectedUserIds}
                              ..remove(account.id),
                          );
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _selectUsers() async {
    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _DocumentAccessOrganizationDialog(
        accounts: widget.accounts,
        selectedUserIds: widget.selectedUserIds,
      ),
    );
    if (selected == null) return;
    widget.onChanged(organizationWide: false, userIds: selected);
  }
}

class _AccessScopeOption extends StatelessWidget {
  const _AccessScopeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? TheWeColor.blue300 : TheWeColor.black500,
          ),
          Text(label),
        ],
      ),
    ),
  );
}

class _DocumentAccessOrganizationDialog extends StatefulWidget {
  const _DocumentAccessOrganizationDialog({
    required this.accounts,
    required this.selectedUserIds,
  });

  final List<EmployeeAccount> accounts;
  final Set<String> selectedUserIds;

  @override
  State<_DocumentAccessOrganizationDialog> createState() =>
      _DocumentAccessOrganizationDialogState();
}

class _DocumentAccessOrganizationDialogState
    extends State<_DocumentAccessOrganizationDialog> {
  late Set<String> selectedUserIds = {...widget.selectedUserIds};

  @override
  Widget build(BuildContext context) {
    final departments =
        widget.accounts.map((account) => account.department).toSet().toList()
          ..sort();
    return AlertDialog(
      key: const ValueKey('document-access-organization-dialog'),
      backgroundColor: TheWeColor.white,
      title: const Text('사용자 · 부서 선택'),
      content: SizedBox(
        width: 520,
        height: MediaQuery.sizeOf(context).height * .58,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ListView.separated(
            itemCount: departments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final department = departments[index];
              final members = widget.accounts
                  .where((account) => account.department == department)
                  .toList();
              final selectedCount = members
                  .where((member) => selectedUserIds.contains(member.id))
                  .length;
              final allSelected =
                  members.isNotEmpty && selectedCount == members.length;
              final partiallySelected = selectedCount > 0 && !allSelected;
              return Container(
                decoration: BoxDecoration(
                  color: TheWeColor.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: TheWeColor.black300.withValues(alpha: .28),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                  childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  shape: const RoundedRectangleBorder(side: BorderSide.none),
                  collapsedShape: const RoundedRectangleBorder(
                    side: BorderSide.none,
                  ),
                  leading: Icon(
                    Icons.folder_outlined,
                    color: TheWeColor.blue300,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          department,
                          style: TheWeTextStyle.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '$selectedCount/${members.length}명',
                        style: TheWeTextStyle.caption.copyWith(
                          color: TheWeColor.black500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Checkbox(
                        tristate: true,
                        value: allSelected
                            ? true
                            : partiallySelected
                            ? null
                            : false,
                        activeColor: TheWeColor.blue300,
                        onChanged: (_) =>
                            _toggleDepartment(members, selected: !allSelected),
                      ),
                    ],
                  ),
                  children: members
                      .map(
                        (account) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Material(
                            color: TheWeColor.white,
                            borderRadius: BorderRadius.circular(9),
                            child: CheckboxListTile(
                              value: selectedUserIds.contains(account.id),
                              activeColor: TheWeColor.blue300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              title: Text(account.name),
                              subtitle: Text(
                                '${account.position} · ${account.id}',
                              ),
                              onChanged: (selected) => setState(() {
                                if (selected == true) {
                                  selectedUserIds.add(account.id);
                                } else {
                                  selectedUserIds.remove(account.id);
                                }
                              }),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: TheWeColor.blue300,
            foregroundColor: TheWeColor.white,
          ),
          onPressed: () => Navigator.pop(context, selectedUserIds),
          child: const Text('저장'),
        ),
      ],
    );
  }

  void _toggleDepartment(
    List<EmployeeAccount> members, {
    required bool selected,
  }) {
    setState(() {
      if (selected) {
        selectedUserIds.addAll(members.map((member) => member.id));
      } else {
        selectedUserIds.removeAll(members.map((member) => member.id));
      }
    });
  }
}
