import 'approval_admin_dependencies.dart';
import 'approval_admin_direct_leave.dart';

class AdminDepartmentLeaveApprovalLines extends ConsumerWidget {
  const AdminDepartmentLeaveApprovalLines({super.key, required this.state});

  final ApprovalDashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    decoration: adminSurface(),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var index = 0; index < state.departments.length; index++) ...[
          _DepartmentLeaveApprovalLineTile(
            state: state,
            department: state.departments[index],
          ),
          if (index != state.departments.length - 1) adminDivider(),
        ],
      ],
    ),
  );
}

class _DepartmentLeaveApprovalLineTile extends ConsumerWidget {
  const _DepartmentLeaveApprovalLineTile({
    required this.state,
    required this.department,
  });

  final ApprovalDashboardState state;
  final String department;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userIds = state.leaveApprovalLines[department] ?? const <String>[];
    final approvers = userIds
        .map(
          (userId) => state.accounts
              .where((account) => account.id == userId)
              .firstOrNull,
        )
        .nonNulls
        .toList();
    final description = approvers.isEmpty
        ? '미설정 · 기본 대표 결재'
        : approvers
              .map((account) => '${account.name} ${account.position}')
              .join('  →  ');
    return ListTile(
      key: ValueKey('leave-approval-line-$department'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      leading: const CircleAvatar(
        backgroundColor: TheWeColor.blueSurface,
        child: Icon(Icons.account_tree_outlined, color: TheWeColor.blue300),
      ),
      title: Text(department, style: TheWeTextStyle.subtitle),
      subtitle: Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: OutlinedButton(
        key: ValueKey('leave-approval-line-edit-$department'),
        onPressed: () => _showEditor(context, ref, userIds),
        child: const Text('결재라인 설정'),
      ),
    );
  }

  Future<void> _showEditor(
    BuildContext context,
    WidgetRef ref,
    List<String> initialIds,
  ) async {
    final selectedIds = [...initialIds];
    var error = '';
    final saved = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final selectedAccounts = selectedIds
              .map(
                (userId) => state.accounts
                    .where((account) => account.id == userId)
                    .firstOrNull,
              )
              .nonNulls
              .toList();
          final unselectedAccounts = state.accounts
              .where((account) => !selectedIds.contains(account.id))
              .toList();
          return TheWeModalSurface(
            key: const ValueKey('leave-approval-line-editor'),
            maxWidth: 720,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TheWeModalHeader(
                  title: '$department 휴가 결재라인',
                  onClose: () => Navigator.pop(dialogContext),
                ),
                const SizedBox(height: 8),
                Text(
                  '위에서부터 순서대로 결재하며 마지막 사용자가 최종 승인합니다.',
                  style: TheWeTextStyle.body.copyWith(
                    color: TheWeColor.black500,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (
                        var index = 0;
                        index < selectedAccounts.length;
                        index++
                      )
                        _approvalAccountTile(
                          selectedAccounts[index],
                          selected: true,
                          order: index + 1,
                          onChanged: () => setDialogState(() {
                            selectedIds.remove(selectedAccounts[index].id);
                            error = '';
                          }),
                          onMoveUp: index == 0
                              ? null
                              : () => setDialogState(() {
                                  final moved = selectedIds.removeAt(index);
                                  selectedIds.insert(index - 1, moved);
                                }),
                          onMoveDown: index == selectedAccounts.length - 1
                              ? null
                              : () => setDialogState(() {
                                  final moved = selectedIds.removeAt(index);
                                  selectedIds.insert(index + 1, moved);
                                }),
                        ),
                      if (selectedAccounts.isNotEmpty &&
                          unselectedAccounts.isNotEmpty)
                        const Divider(height: 24),
                      for (final account in unselectedAccounts)
                        _approvalAccountTile(
                          account,
                          selected: false,
                          onChanged: () => setDialogState(() {
                            selectedIds.add(account.id);
                            error = '';
                          }),
                        ),
                    ],
                  ),
                ),
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    error,
                    style: TheWeTextStyle.caption.copyWith(
                      color: TheWeColor.danger,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                TheWeModalActions(
                  primaryLabel: '저장',
                  secondaryLabel: '취소',
                  onSecondaryPressed: () => Navigator.pop(dialogContext),
                  onPrimaryPressed: () {
                    if (selectedIds.isEmpty) {
                      setDialogState(() => error = '한 명 이상의 결재자를 선택해 주세요.');
                      return;
                    }
                    Navigator.pop(dialogContext, [...selectedIds]);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
    if (saved == null || !context.mounted) return;
    final message = ref
        .read(approvalDashboardControllerProvider.notifier)
        .updateDepartmentLeaveApprovalLine(department, saved);
    showTheWeSnackBar(
      context,
      message: message ?? '$department 휴가 결재라인을 저장했습니다.',
      type: message == null
          ? TheWeSnackBarType.success
          : TheWeSnackBarType.error,
    );
  }

  Widget _approvalAccountTile(
    EmployeeAccount account, {
    required bool selected,
    required VoidCallback onChanged,
    int? order,
    VoidCallback? onMoveUp,
    VoidCallback? onMoveDown,
  }) => ListTile(
    key: ValueKey('leave-approver-${account.id}'),
    dense: true,
    leading: selected
        ? CircleAvatar(radius: 15, child: Text('$order'))
        : const Icon(Icons.person_outline),
    title: Text('${account.name} ${account.position}'),
    subtitle: Text('${account.department} · ${account.id}'),
    onTap: onChanged,
    trailing: selected
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onMoveUp,
                icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                tooltip: '위로 이동',
              ),
              IconButton(
                onPressed: onMoveDown,
                icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                tooltip: '아래로 이동',
              ),
              IconButton(
                onPressed: onChanged,
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: '제외',
              ),
            ],
          )
        : const Icon(Icons.add_rounded),
  );
}
