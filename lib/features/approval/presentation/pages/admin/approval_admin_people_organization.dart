import 'approval_admin_dependencies.dart';
import 'approval_admin_direct_leave.dart';

class AdminEmployeeManagement extends ConsumerWidget {
  const AdminEmployeeManagement({super.key, required this.state});
  final ApprovalDashboardState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = MediaQuery.sizeOf(context).width < 700;
    final orderedAccounts = state.organizationOrderedAccounts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '전체 직원 사원관리',
                style: mobile
                    ? TheWeTextStyle.title.copyWith(fontSize: 19)
                    : TheWeTextStyle.title,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _addEmployee(context, ref),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('직원 추가'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (mobile)
          ...orderedAccounts.map(
            (account) => _EmployeeCard(
              account: account,
              state: state,
              onEdit: () => _editEmployee(context, ref, account),
            ),
          )
        else
          TheWeDataTable(
            headers: const [
              '이름/아이디',
              '부서',
              '직위',
              '입사일',
              '연차',
              '월차',
              '잔여',
              '권한',
              '관리',
            ],
            columnFlexes: const [1.6, 1.15, .9, 1.15, .8, .8, .8, .85, .65],
            minWidth: 1320,
            rows: orderedAccounts
                .map(
                  (account) => <Widget>[
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(account.name),
                        const SizedBox(height: 3),
                        Text(
                          account.id,
                          style: TheWeTextStyle.caption.copyWith(
                            color: TheWeColor.black500,
                          ),
                        ),
                      ],
                    ),
                    Text(account.department),
                    Text(account.position),
                    Text(account.hireDate),
                    Text(adminLeaveDays(state.annualLeaveDaysFor(account))),
                    Text(adminLeaveDays(state.monthlyLeaveDaysFor(account))),
                    Text(
                      adminLeaveDays(state.remainingAnnualLeaveFor(account)),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Chip(
                        backgroundColor: account.isAdmin
                            ? TheWeColor.blueSurface
                            : TheWeColor.background,
                        side: BorderSide(
                          color: TheWeColor.black300.withValues(alpha: .2),
                        ),
                        label: Text(account.isAdmin ? '관리자' : '일반'),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _editEmployee(context, ref, account),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: '계정 수정',
                    ),
                  ],
                )
                .toList(),
          ),
      ],
    );
  }

  Future<void> _addEmployee(
    BuildContext context,
    WidgetRef ref, {
    String initialDepartment = '',
  }) async {
    final id = TextEditingController();
    final password = TextEditingController();
    final name = TextEditingController();
    final email = TextEditingController();
    final department = TextEditingController(text: initialDepartment);
    final position = TextEditingController();
    final hireDate = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
    final annualLeave = TextEditingController(
      text: (state.annualLeaveByYear[1] ?? 15).toString(),
    );
    final monthlyLeave = TextEditingController(text: '0');
    final remainingLeave = TextEditingController(text: '0');
    var error = '';

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: TheWeColor.surfaceAlt,
          title: const Text('직원 추가'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: '이름'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: id,
                    decoration: const InputDecoration(labelText: '아이디'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: '초기 비밀번호'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: '이메일'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: department,
                    readOnly: initialDepartment.isNotEmpty,
                    decoration: const InputDecoration(labelText: '부서'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: position,
                    decoration: const InputDecoration(labelText: '직위'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: hireDate,
                    readOnly: true,
                    onTap: () => _selectHireDate(context, hireDate),
                    decoration: const InputDecoration(
                      labelText: '입사일',
                      suffixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _leaveDaysField(annualLeave, '연차 개수'),
                  const SizedBox(height: 10),
                  _leaveDaysField(monthlyLeave, '월차 개수'),
                  const SizedBox(height: 10),
                  _leaveDaysField(remainingLeave, '잔여 개수'),
                  if (error.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        error,
                        style: TheWeTextStyle.caption.copyWith(
                          color: TheWeColor.danger,
                        ),
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
                final message = ref
                    .read(approvalDashboardControllerProvider.notifier)
                    .addEmployee(
                      id: id.text,
                      password: password.text,
                      name: name.text,
                      department: department.text,
                      position: position.text,
                      email: email.text,
                      hireDate: hireDate.text,
                      isAdmin: false,
                      annualLeaveDays: annualLeave.text,
                      monthlyLeaveDays: monthlyLeave.text,
                      remainingLeaveDays: remainingLeave.text,
                    );
                if (message != null) {
                  setDialogState(() => error = message);
                  return;
                }
                Navigator.pop(context);
              },
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editEmployee(
    BuildContext context,
    WidgetRef ref,
    EmployeeAccount account,
  ) async {
    final name = TextEditingController(text: account.name);
    final email = TextEditingController(text: account.email);
    final department = TextEditingController(text: account.department);
    final position = TextEditingController(text: account.position);
    final hireDate = TextEditingController(text: account.hireDate);
    final annualLeave = TextEditingController(
      text: _leaveNumber(state.annualLeaveDaysFor(account)),
    );
    final monthlyLeave = TextEditingController(
      text: _leaveNumber(state.monthlyLeaveDaysFor(account)),
    );
    final remainingLeave = TextEditingController(
      text: _leaveNumber(state.remainingAnnualLeaveFor(account)),
    );
    final password = TextEditingController();
    var error = '';
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: TheWeColor.surfaceAlt,
          title: Text('${account.name} 계정 수정'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: '이름'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: '이메일'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: department,
                    decoration: const InputDecoration(labelText: '부서'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: position,
                    decoration: const InputDecoration(labelText: '직위'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: hireDate,
                    readOnly: true,
                    onTap: () => _selectHireDate(context, hireDate),
                    decoration: const InputDecoration(
                      labelText: '입사일',
                      suffixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _leaveDaysField(annualLeave, '연차 개수'),
                  const SizedBox(height: 10),
                  _leaveDaysField(monthlyLeave, '월차 개수'),
                  const SizedBox(height: 10),
                  _leaveDaysField(remainingLeave, '잔여 개수'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '새 비밀번호',
                      hintText: '변경하지 않으면 비워두세요.',
                    ),
                  ),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        error,
                        style: TheWeTextStyle.caption.copyWith(
                          color: TheWeColor.danger,
                        ),
                      ),
                    ),
                  ],
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
                final message = ref
                    .read(approvalDashboardControllerProvider.notifier)
                    .updateEmployee(
                      userId: account.id,
                      name: name.text,
                      email: email.text,
                      department: department.text,
                      position: position.text,
                      hireDate: hireDate.text,
                      password: password.text,
                      isAdmin: account.isAdmin,
                      annualLeaveDays: annualLeave.text,
                      monthlyLeaveDays: monthlyLeave.text,
                      remainingLeaveDays: remainingLeave.text,
                    );
                if (message != null) {
                  setDialogState(() => error = message);
                  return;
                }
                Navigator.pop(context);
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({
    required this.account,
    required this.state,
    required this.onEdit,
  });

  final EmployeeAccount account;
  final ApprovalDashboardState state;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('employee-card-${account.id}'),
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: adminSurface(),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: TheWeColor.blueSurface,
              child: Text(
                account.name.substring(0, 1),
                style: TheWeTextStyle.subtitle.copyWith(
                  color: TheWeColor.blue300,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: TheWeTextStyle.subtitle.copyWith(fontSize: 16),
                  ),
                  Text(
                    account.id,
                    style: TheWeTextStyle.caption.copyWith(
                      color: TheWeColor.black500,
                    ),
                  ),
                ],
              ),
            ),
            Chip(
              backgroundColor: account.isAdmin
                  ? TheWeColor.blueSurface
                  : TheWeColor.background,
              side: BorderSide(
                color: TheWeColor.black300.withValues(alpha: .2),
              ),
              label: Text(account.isAdmin ? '관리자' : '일반'),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: '계정 수정',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        adminDivider(height: 15),
        Row(
          children: [
            Expanded(
              child: _EmployeeInfo(label: '부서', value: account.department),
            ),
            Expanded(
              child: _EmployeeInfo(label: '직위', value: account.position),
            ),
            Expanded(
              child: _EmployeeInfo(label: '입사일', value: account.hireDate),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _EmployeeInfo(
                label: '연차',
                value: adminLeaveDays(state.annualLeaveDaysFor(account)),
              ),
            ),
            Expanded(
              child: _EmployeeInfo(
                label: '월차',
                value: adminLeaveDays(state.monthlyLeaveDaysFor(account)),
              ),
            ),
            Expanded(
              child: _EmployeeInfo(
                label: '잔여',
                value: adminLeaveDays(state.remainingAnnualLeaveFor(account)),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _leaveDaysField(TextEditingController controller, String label) =>
    TextField(
      key: ValueKey('employee-leave-field-$label'),
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, suffixText: '일'),
    );

String _leaveNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

class _EmployeeInfo extends StatelessWidget {
  const _EmployeeInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        label,
        style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TheWeTextStyle.body.copyWith(fontSize: 13),
      ),
    ],
  );
}

Future<void> _selectHireDate(
  BuildContext context,
  TextEditingController controller,
) async {
  final initialDate = DateTime.tryParse(controller.text) ?? DateTime.now();
  final selected = await _showHireDatePicker(context, initialDate);
  if (selected == null) return;
  controller.text = selected.toIso8601String().substring(0, 10);
}

Future<DateTime?> _showHireDatePicker(
  BuildContext context,
  DateTime initialDate,
) => showTheWeDatePicker(
  context,
  initialDate: initialDate,
  firstDate: DateTime(1950),
  lastDate: DateTime.now(),
  title: '입사일 선택',
  dialogKey: const ValueKey('hire-date-picker'),
);

class AdminOrganizationManagement extends ConsumerWidget {
  const AdminOrganizationManagement({super.key, required this.state});
  final ApprovalDashboardState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
    key: const ValueKey('admin-organization-page'),
    width: double.infinity,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('조직도 및 부서 관리', style: TheWeTextStyle.title)),
            OutlinedButton.icon(
              key: const ValueKey('add-department-button'),
              onPressed: () => addAdminDepartment(context, ref),
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('부서 추가'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '부서 순서를 변경하고 구성원을 추가·수정·삭제할 수 있으며 전자결재 부서 문서함에 자동 연결됩니다.',
          style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth < 680
                ? constraints.maxWidth
                : (constraints.maxWidth - 16) / 2;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: state.departments.asMap().entries.map((entry) {
                final index = entry.key;
                final department = entry.value;
                final protectsHeadcount = department == '대표이사';
                final members =
                    state.accounts
                        .where((account) => account.department == department)
                        .toList()
                      ..sort(compareEmployeeOrganizationOrder);
                return Container(
                  key: ValueKey('department-card-$department'),
                  width: width,
                  padding: const EdgeInsets.all(20),
                  decoration: adminSurface(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.folder_shared_outlined,
                            color: TheWeColor.blue300,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              department,
                              style: TheWeTextStyle.subtitle,
                            ),
                          ),
                          _DepartmentOrderButtons(
                            department: department,
                            canMoveUp: index > 0,
                            canMoveDown: index < state.departments.length - 1,
                            onMove: (offset) => ref
                                .read(
                                  approvalDashboardControllerProvider.notifier,
                                )
                                .moveDepartment(department, offset),
                          ),
                          Chip(label: Text('${members.length}명')),
                          if (!protectsHeadcount)
                            IconButton(
                              onPressed: () =>
                                  AdminEmployeeManagement(
                                    state: state,
                                  )._addEmployee(
                                    context,
                                    ref,
                                    initialDepartment: department,
                                  ),
                              icon: const Icon(
                                Icons.person_add_alt_outlined,
                                size: 19,
                              ),
                              tooltip: '$department 구성원 추가',
                            ),
                          IconButton(
                            onPressed: () =>
                                renameAdminDepartment(context, ref, department),
                            icon: const Icon(Icons.edit_outlined, size: 19),
                            tooltip: '부서명 수정',
                          ),
                          IconButton(
                            onPressed: () => deleteAdminDepartment(
                              context,
                              ref,
                              department,
                              members,
                            ),
                            icon: const Icon(Icons.delete_outline, size: 19),
                            tooltip: '부서 삭제',
                          ),
                        ],
                      ),
                      adminDivider(height: 26),
                      if (members.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '소속 구성원이 없습니다.',
                            style: TheWeTextStyle.body.copyWith(
                              color: TheWeColor.black500,
                            ),
                          ),
                        ),
                      ...members.map(
                        (member) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: CircleAvatar(
                            child: Text(member.name.substring(0, 1)),
                          ),
                          title: Text(member.name),
                          subtitle: Text('${member.position} · ${member.id}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => AdminEmployeeManagement(
                                  state: state,
                                )._editEmployee(context, ref, member),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: '${member.name} 정보 수정',
                              ),
                              if (!protectsHeadcount)
                                IconButton(
                                  onPressed: () =>
                                      deleteAdminEmployee(context, ref, member),
                                  icon: const Icon(
                                    Icons.person_remove_outlined,
                                    size: 18,
                                  ),
                                  tooltip: '${member.name} 구성원 삭제',
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    ),
  );
}

class _DepartmentOrderButtons extends StatelessWidget {
  const _DepartmentOrderButtons({
    required this.department,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMove,
  });

  final String department;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 28,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(
          key: ValueKey('move-department-up-$department'),
          icon: Icons.keyboard_arrow_up,
          tooltip: '$department 위로 이동',
          onPressed: canMoveUp ? () => onMove(-1) : null,
        ),
        _button(
          key: ValueKey('move-department-down-$department'),
          icon: Icons.keyboard_arrow_down,
          tooltip: '$department 아래로 이동',
          onPressed: canMoveDown ? () => onMove(1) : null,
        ),
      ],
    ),
  );

  Widget _button({
    required Key key,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) => IconButton(
    key: key,
    onPressed: onPressed,
    icon: Icon(icon, size: 18),
    tooltip: tooltip,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 28, height: 26),
    visualDensity: VisualDensity.compact,
  );
}

Future<void> addAdminDepartment(BuildContext context, WidgetRef ref) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _DepartmentNameDialog(
      title: '부서 추가',
      actionLabel: '추가',
      onSave: (name) => ref
          .read(approvalDashboardControllerProvider.notifier)
          .addDepartment(name),
    ),
  );
}

Future<void> renameAdminDepartment(
  BuildContext context,
  WidgetRef ref,
  String department,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _DepartmentNameDialog(
      title: '부서명 수정',
      actionLabel: '저장',
      initialName: department,
      onSave: (nextName) => ref
          .read(approvalDashboardControllerProvider.notifier)
          .renameDepartment(department, nextName),
    ),
  );
}

Future<void> deleteAdminDepartment(
  BuildContext context,
  WidgetRef ref,
  String department,
  List<EmployeeAccount> members,
) async {
  if (members.isNotEmpty) {
    showTheWeSnackBar(
      context,
      message: '소속 구성원을 이동하거나 삭제한 뒤 부서를 삭제해 주세요.',
      type: TheWeSnackBarType.error,
    );
    return;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: TheWeColor.surfaceAlt,
      title: const Text('부서 삭제'),
      content: Text('$department 부서를 삭제할까요?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: FilledButton.styleFrom(backgroundColor: TheWeColor.danger),
          child: const Text('삭제'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final message = ref
      .read(approvalDashboardControllerProvider.notifier)
      .deleteDepartment(department);
  if (message != null) {
    showTheWeSnackBar(context, message: message, type: TheWeSnackBarType.error);
  }
}

Future<void> deleteAdminEmployee(
  BuildContext context,
  WidgetRef ref,
  EmployeeAccount employee,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: TheWeColor.surfaceAlt,
      title: const Text('구성원 삭제'),
      content: Text('${employee.name}님의 계정을 비활성화하고 조직도에서 제외할까요?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: FilledButton.styleFrom(backgroundColor: TheWeColor.danger),
          child: const Text('삭제'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final message = ref
      .read(approvalDashboardControllerProvider.notifier)
      .deleteEmployee(employee.id);
  if (message != null) {
    showTheWeSnackBar(context, message: message, type: TheWeSnackBarType.error);
  }
}

class _DepartmentNameDialog extends StatefulWidget {
  const _DepartmentNameDialog({
    required this.title,
    required this.actionLabel,
    required this.onSave,
    this.initialName = '',
  });

  final String title;
  final String actionLabel;
  final String initialName;
  final String? Function(String nextName) onSave;

  @override
  State<_DepartmentNameDialog> createState() => _DepartmentNameDialogState();
}

class _DepartmentNameDialogState extends State<_DepartmentNameDialog> {
  late final TextEditingController _controller;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: TheWeColor.surfaceAlt,
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: TextField(
          key: const ValueKey('department-name-field'),
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: '부서명',
            errorText: _error.isEmpty ? null : _error,
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
            final message = widget.onSave(_controller.text);
            if (message != null) {
              setState(() => _error = message);
              return;
            }
            Navigator.pop(context);
          },
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}
