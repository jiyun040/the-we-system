import 'approval_admin_dependencies.dart';
import 'approval_admin_direct_leave.dart';

class AdminEmployeeManagement extends ConsumerWidget {
  const AdminEmployeeManagement({super.key, required this.state});
  final ApprovalDashboardState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = MediaQuery.sizeOf(context).width < 700;
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
          ...state.accounts.map(
            (account) => _EmployeeCard(
              account: account,
              onEdit: () => _editEmployee(context, ref, account),
            ),
          )
        else
          TheWeDataTable(
            headers: const ['이름/아이디', '부서', '직위', '입사일', '권한', '관리'],
            columnFlexes: const [1.65, 1.25, 1, 1.25, .9, .7],
            minWidth: 1050,
            rows: state.accounts
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

  Future<void> _addEmployee(BuildContext context, WidgetRef ref) async {
    final id = TextEditingController();
    final password = TextEditingController();
    final name = TextEditingController();
    final email = TextEditingController();
    final department = TextEditingController();
    final position = TextEditingController();
    final hireDate = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
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
    final department = TextEditingController(text: account.department);
    final position = TextEditingController(text: account.position);
    final hireDate = TextEditingController(text: account.hireDate);
    final password = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: TheWeColor.surfaceAlt,
          title: Text('${account.name} 계정 수정'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                children: [
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
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '새 비밀번호',
                      hintText: '변경하지 않으면 비워두세요.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    ref
        .read(approvalDashboardControllerProvider.notifier)
        .updateEmployee(
          userId: account.id,
          department: department.text,
          position: position.text,
          hireDate: hireDate.text,
          password: password.text,
          isAdmin: account.isAdmin,
        );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.account, required this.onEdit});

  final EmployeeAccount account;
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
      ],
    ),
  );
}

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
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('조직도 및 부서 관리', style: TheWeTextStyle.title),
      const SizedBox(height: 8),
      Text(
        '계정에 설정된 부서 기준으로 전자결재 부서 문서함이 자동 연결됩니다.',
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
            children: state.departments.map((department) {
              final members = state.accounts
                  .where((account) => account.department == department)
                  .toList();
              return Container(
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
                        Chip(label: Text('${members.length}명')),
                        IconButton(
                          onPressed: () =>
                              renameAdminDepartment(context, ref, department),
                          icon: const Icon(Icons.edit_outlined, size: 19),
                          tooltip: '부서명 수정',
                        ),
                      ],
                    ),
                    adminDivider(height: 26),
                    ...members.map(
                      (member) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: CircleAvatar(
                          child: Text(member.name.substring(0, 1)),
                        ),
                        title: Text(member.name),
                        subtitle: Text('${member.position} · ${member.id}'),
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
  );
}

Future<void> renameAdminDepartment(
  BuildContext context,
  WidgetRef ref,
  String department,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _RenameDepartmentDialog(
      department: department,
      onSave: (nextName) => ref
          .read(approvalDashboardControllerProvider.notifier)
          .renameDepartment(department, nextName),
    ),
  );
}

class _RenameDepartmentDialog extends StatefulWidget {
  const _RenameDepartmentDialog({
    required this.department,
    required this.onSave,
  });

  final String department;
  final String? Function(String nextName) onSave;

  @override
  State<_RenameDepartmentDialog> createState() =>
      _RenameDepartmentDialogState();
}

class _RenameDepartmentDialogState extends State<_RenameDepartmentDialog> {
  late final TextEditingController _controller;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.department);
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
      title: const Text('부서명 수정'),
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
          child: const Text('저장'),
        ),
      ],
    );
  }
}
