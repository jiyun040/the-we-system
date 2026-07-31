import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/components/the_we_data_table.dart';
import 'package:the_we_system/common/components/the_we_logo.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';

class ApprovalAdminPage extends ConsumerStatefulWidget {
  const ApprovalAdminPage({super.key});

  @override
  ConsumerState<ApprovalAdminPage> createState() => _ApprovalAdminPageState();
}

class _ApprovalAdminPageState extends ConsumerState<ApprovalAdminPage> {
  int selectedIndex = 0;
  bool settingsUnlocked = false;

  static const destinations = [
    (Icons.dashboard_outlined, '관리 홈'),
    (Icons.people_outline, '사원 관리'),
    (Icons.account_tree_outlined, '조직 관리'),
    (Icons.apps_outlined, 'APP 관리'),
    (Icons.tune_outlined, '통합 설정'),
  ];

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(approvalDashboardControllerProvider);
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      backgroundColor: TheWeColor.background,
      bottomNavigationBar: asyncState.maybeWhen(
        data: (state) => state.isAdminMode && mobile
            ? _AdminBottomNavigation(
                selectedIndex: selectedIndex,
                onSelected: (value) => setState(() => selectedIndex = value),
              )
            : null,
        orElse: () => null,
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, stackTrace) =>
            const Center(child: Text('관리자 정보를 불러오지 못했습니다.')),
        data: (state) {
          if (!state.isAdminMode) {
            return _AdminAccessGate(onVerified: () => setState(() {}));
          }
          final compact = MediaQuery.sizeOf(context).width < 900;
          return SafeArea(
            child: Row(
              children: [
                if (!compact)
                  _AdminNavigation(
                    selectedIndex: selectedIndex,
                    portalName: state.portalName,
                    onSelected: (value) =>
                        setState(() => selectedIndex = value),
                    onLeave: _leaveAdmin,
                  ),
                Expanded(
                  child: ColoredBox(
                    color: TheWeColor.background,
                    child: Column(
                      children: [
                        if (compact)
                          _AdminHeader(
                            mobile: mobile,
                            onOpenMenu: !mobile
                                ? () => _showCompactMenu(state)
                                : null,
                            onLeave: _leaveAdmin,
                          ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(mobile ? 14 : 28),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 1320,
                                ),
                                child: switch (selectedIndex) {
                                  0 => _AdminDashboard(state: state),
                                  1 => _EmployeeManagement(state: state),
                                  2 => _OrganizationManagement(state: state),
                                  3 => _AppManagement(state: state),
                                  _ =>
                                    settingsUnlocked
                                        ? _IntegratedSettings(state: state)
                                        : _SettingsPasswordGate(
                                            onUnlocked: () => setState(
                                              () => settingsUnlocked = true,
                                            ),
                                          ),
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _leaveAdmin() {
    ref.read(approvalDashboardControllerProvider.notifier).leaveAdminMode();
    context.goNamed(AppRouteName.home);
  }

  Future<void> _showCompactMenu(ApprovalDashboardState state) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: destinations.length,
        itemBuilder: (context, index) => ListTile(
          selected: selectedIndex == index,
          leading: Icon(destinations[index].$1),
          title: Text(destinations[index].$2),
          onTap: () => Navigator.pop(context, index),
        ),
      ),
    );
    if (selected != null) setState(() => selectedIndex = selected);
  }
}

class _AdminAccessGate extends ConsumerWidget {
  const _AdminAccessGate({required this.onVerified});
  final VoidCallback onVerified;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(mobile ? 18 : 0),
        child: Container(
          width: mobile ? double.infinity : 440,
          padding: EdgeInsets.all(mobile ? 20 : 32),
          decoration: _adminSurface(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                size: mobile ? 40 : 56,
                color: TheWeColor.blue300,
              ),
              SizedBox(height: mobile ? 12 : 18),
              Text(
                '관리자 인증이 필요합니다',
                style: mobile
                    ? TheWeTextStyle.title.copyWith(fontSize: 20)
                    : TheWeTextStyle.title,
              ),
              const SizedBox(height: 7),
              Text(
                '관리자 권한 계정에서 OTP 인증 후 접근할 수 있습니다.',
                textAlign: TextAlign.center,
                style: TheWeTextStyle.caption.copyWith(
                  color: TheWeColor.black500,
                ),
              ),
              SizedBox(height: mobile ? 15 : 22),
              FilledButton(
                onPressed: () async {
                  final otp = await _requestOtp(context);
                  if (otp == null) return;
                  final success = ref
                      .read(approvalDashboardControllerProvider.notifier)
                      .enterAdminMode(otp);
                  if (success) {
                    onVerified();
                  }
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('OTP 번호가 올바르지 않습니다.')),
                    );
                  }
                },
                child: const Text('OTP 인증'),
              ),
              TextButton(
                onPressed: () => context.goNamed(AppRouteName.home),
                child: const Text('일반 화면으로 돌아가기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminNavigation extends StatelessWidget {
  const _AdminNavigation({
    required this.selectedIndex,
    required this.portalName,
    required this.onSelected,
    required this.onLeave,
  });
  final int selectedIndex;
  final String portalName;
  final ValueChanged<int> onSelected;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) => Container(
    width: 260,
    color: const Color(0xFFFCFCFD),
    padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
    foregroundDecoration: BoxDecoration(
      border: Border(
        right: BorderSide(color: TheWeColor.black300.withValues(alpha: .28)),
      ),
    ),
    child: Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TheWeLogo(),
          const SizedBox(height: 8),
          Text(
            portalName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
          ),
          const SizedBox(height: 30),
          ...List.generate(_ApprovalAdminPageState.destinations.length, (
            index,
          ) {
            final item = _ApprovalAdminPageState.destinations[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                selected: selectedIndex == index,
                selectedTileColor: TheWeColor.blueSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Icon(item.$1),
                title: Text(item.$2),
                onTap: () => onSelected(index),
              ),
            );
          }),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: onLeave,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('일반 계정 화면'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
          ),
        ],
      ),
    ),
  );
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({
    required this.mobile,
    required this.onOpenMenu,
    required this.onLeave,
  });
  final bool mobile;
  final VoidCallback? onOpenMenu;
  final VoidCallback onLeave;
  @override
  Widget build(BuildContext context) => Container(
    height: mobile ? 46 : 56,
    padding: EdgeInsets.symmetric(horizontal: mobile ? 14 : 28),
    color: TheWeColor.background,
    child: Row(
      children: [
        if (onOpenMenu != null)
          IconButton(onPressed: onOpenMenu, icon: const Icon(Icons.menu)),
        const Spacer(),
        IconButton(
          onPressed: onLeave,
          tooltip: '일반 화면',
          icon: const Icon(Icons.swap_horiz),
        ),
      ],
    ),
  );
}

class _AdminBottomNavigation extends StatelessWidget {
  const _AdminBottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selectedIndex,
    backgroundColor: TheWeColor.background,
    indicatorColor: Colors.transparent,
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      return TheWeTextStyle.caption.copyWith(
        color: selected ? TheWeColor.blue300 : TheWeColor.black900,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      );
    }),
    overlayColor: WidgetStatePropertyAll(
      TheWeColor.blue100.withValues(alpha: 0.18),
    ),
    onDestinationSelected: onSelected,
    destinations: [
      for (final destination in _ApprovalAdminPageState.destinations)
        NavigationDestination(
          icon: Icon(destination.$1),
          selectedIcon: Icon(destination.$1, color: TheWeColor.blue300),
          label: destination.$2,
        ),
    ],
  );
}

class _AdminDashboard extends ConsumerWidget {
  const _AdminDashboard({required this.state});
  final ApprovalDashboardState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingLeaves = state.leaveRequests
        .where((item) => item.status == '승인대기')
        .toList();
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '회사 운영 현황',
          style: mobile
              ? TheWeTextStyle.title.copyWith(fontSize: 19)
              : TheWeTextStyle.title,
        ),
        SizedBox(height: mobile ? 12 : 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth < 600
                ? (constraints.maxWidth - 10) / 2
                : constraints.maxWidth < 760
                ? constraints.maxWidth
                : (constraints.maxWidth - 36) / 4;
            return Wrap(
              spacing: mobile ? 10 : 12,
              runSpacing: mobile ? 10 : 12,
              children: [
                _AdminMetric(
                  width: width,
                  icon: Icons.people_outline,
                  label: '전체 직원',
                  value: '${state.accounts.length}명',
                ),
                _AdminMetric(
                  width: width,
                  icon: Icons.account_tree_outlined,
                  label: '부서',
                  value: '${state.departments.length}개',
                ),
                _AdminMetric(
                  width: width,
                  icon: Icons.pending_actions_outlined,
                  label: '결재 대기',
                  value: '${state.waitingDocuments.length}건',
                ),
                _AdminMetric(
                  width: width,
                  icon: Icons.beach_access_outlined,
                  label: '휴가 승인 대기',
                  value: '${pendingLeaves.length}건',
                ),
              ],
            );
          },
        ),
        SizedBox(height: mobile ? 22 : 28),
        Text(
          '휴가 승인 관리',
          style: mobile
              ? TheWeTextStyle.title.copyWith(fontSize: 19)
              : TheWeTextStyle.title,
        ),
        const SizedBox(height: 12),
        if (pendingLeaves.isEmpty)
          Container(
            width: double.infinity,
            decoration: _adminSurface(),
            padding: EdgeInsets.all(mobile ? 22 : 40),
            child: const Center(child: Text('승인 대기 중인 휴가가 없습니다.')),
          )
        else if (mobile)
          ...pendingLeaves.map((request) {
            final employee = state.accounts
                .where((item) => item.id == request.userId)
                .firstOrNull;
            return _PendingLeaveCard(
              employee: employee,
              request: request,
              onReject: () => ref
                  .read(approvalDashboardControllerProvider.notifier)
                  .updateLeaveStatus(request.id, '반려'),
              onApprove: () => ref
                  .read(approvalDashboardControllerProvider.notifier)
                  .updateLeaveStatus(request.id, '승인완료'),
            );
          })
        else
          TheWeDataTable(
            headers: const ['직원', '종류', '기간', '일수', '처리'],
            columnFlexes: const [1.8, 1.05, 2.2, .7, 1.35],
            minWidth: 980,
            rows: pendingLeaves.map((request) {
              final employee = state.accounts
                  .where((item) => item.id == request.userId)
                  .firstOrNull;
              return <Widget>[
                Text(
                  '${employee?.name ?? request.userId} · ${employee?.department ?? ''}',
                ),
                Text(request.type),
                Text('${request.startDate} ~ ${request.endDate}'),
                Text('${request.days}일'),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => ref
                          .read(approvalDashboardControllerProvider.notifier)
                          .updateLeaveStatus(request.id, '반려'),
                      child: const Text('반려'),
                    ),
                    const SizedBox(width: 6),
                    FilledButton(
                      onPressed: () => ref
                          .read(approvalDashboardControllerProvider.notifier)
                          .updateLeaveStatus(request.id, '승인완료'),
                      child: const Text('승인'),
                    ),
                  ],
                ),
              ];
            }).toList(),
          ),
      ],
    );
  }
}

class _PendingLeaveCard extends StatelessWidget {
  const _PendingLeaveCard({
    required this.employee,
    required this.request,
    required this.onReject,
    required this.onApprove,
  });

  final EmployeeAccount? employee;
  final LeaveRequest request;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(13),
    decoration: _adminSurface(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${employee?.name ?? request.userId} · ${employee?.department ?? ''}',
                style: TheWeTextStyle.subtitle.copyWith(fontSize: 16),
              ),
            ),
            Chip(
              label: Text(request.type),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${request.startDate} ~ ${request.endDate} · ${request.days}일',
          style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onReject,
                child: const Text('반려'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: onApprove,
                child: const Text('승인'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _EmployeeManagement extends ConsumerWidget {
  const _EmployeeManagement({required this.state});
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
    var isAdmin = false;
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
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('관리자 권한'),
                    value: isAdmin,
                    onChanged: (value) => setDialogState(() => isAdmin = value),
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
                      isAdmin: isAdmin,
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
    var isAdmin = account.isAdmin;
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
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('관리자 권한'),
                    value: isAdmin,
                    onChanged: (value) => setState(() => isAdmin = value),
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
          isAdmin: isAdmin,
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
    decoration: _adminSurface(),
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
        const Divider(height: 15),
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
) {
  var selectedDate = initialDate;
  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final compact = MediaQuery.sizeOf(context).width < 600;
        return Dialog(
          key: const ValueKey('hire-date-picker'),
          backgroundColor: TheWeColor.surfaceAlt,
          insetPadding: EdgeInsets.all(compact ? 16 : 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: SizedBox(
            width: 420,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 14 : 22,
                compact ? 16 : 20,
                compact ? 14 : 22,
                compact ? 14 : 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: TheWeColor.blueSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_month_outlined,
                          color: TheWeColor.blue300,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('입사일 선택', style: TheWeTextStyle.subtitle),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                        tooltip: '닫기',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 12 : 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: TheWeColor.blueSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatKoreanDate(selectedDate),
                      textAlign: TextAlign.center,
                      style: TheWeTextStyle.body.copyWith(
                        color: TheWeColor.blue300,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 4 : 8),
                  Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: TheWeColor.blue300,
                        onPrimary: Colors.white,
                        surface: TheWeColor.surfaceAlt,
                        onSurface: TheWeColor.black900,
                      ),
                    ),
                    child: CalendarDatePicker(
                      initialDate: initialDate,
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                      onDateChanged: (date) =>
                          setDialogState(() => selectedDate = date),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('취소'),
                      ),
                      SizedBox(width: compact ? 4 : 8),
                      FilledButton(
                        onPressed: () =>
                            Navigator.pop(dialogContext, selectedDate),
                        style: FilledButton.styleFrom(
                          backgroundColor: TheWeColor.black900,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 20 : 24,
                            vertical: 13,
                          ),
                        ),
                        child: const Text('선택'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

String _formatKoreanDate(DateTime date) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${date.year}년 ${date.month}월 ${date.day}일 '
      '(${weekdays[date.weekday - 1]})';
}

class _OrganizationManagement extends StatelessWidget {
  const _OrganizationManagement({required this.state});
  final ApprovalDashboardState state;
  @override
  Widget build(BuildContext context) => Column(
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
                decoration: _adminSurface(),
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
                      ],
                    ),
                    const Divider(height: 26),
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

class _AppManagement extends ConsumerWidget {
  const _AppManagement({required this.state});
  final ApprovalDashboardState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '일반 계정 업무 APP 관리',
          style: mobile
              ? TheWeTextStyle.title.copyWith(fontSize: 19)
              : TheWeTextStyle.title,
        ),
        const SizedBox(height: 8),
        Text(
          '일반 계정 홈에 노출할 업무와 전자결재 양식을 관리합니다.',
          style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
        ),
        const SizedBox(height: 18),
        ...[
          (
            PortalAppId.approval,
            '전자결재',
            Icons.approval_outlined,
            '${state.activeFormTemplates.length}개 양식 사용 중',
          ),
          (
            PortalAppId.attendance,
            '근태',
            Icons.schedule_outlined,
            '출퇴근 및 근태 현황',
          ),
          (
            PortalAppId.leave,
            '휴가',
            Icons.beach_access_outlined,
            '휴가 신청 및 연차 현황',
          ),
        ].map(
          (app) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(mobile ? 15 : 18),
            decoration: _adminSurface(),
            child: mobile
                ? Column(
                    children: [
                      Row(
                        children: [
                          Icon(app.$3, color: TheWeColor.blue300),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AppDescription(
                              title: app.$2,
                              description: app.$4,
                            ),
                          ),
                          Switch(
                            key: ValueKey('app-switch-${app.$1}'),
                            value: state.isAppEnabled(app.$1),
                            onChanged: (enabled) => ref
                                .read(
                                  approvalDashboardControllerProvider.notifier,
                                )
                                .toggleApp(app.$1, enabled),
                          ),
                        ],
                      ),
                      if (app.$1 == PortalAppId.approval) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showFormManagementDialog(context, ref),
                            icon: const Icon(Icons.description_outlined),
                            label: const Text('양식 관리'),
                          ),
                        ),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      Icon(app.$3, color: TheWeColor.blue300),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _AppDescription(
                          title: app.$2,
                          description: app.$4,
                        ),
                      ),
                      Switch(
                        key: ValueKey('app-switch-${app.$1}'),
                        value: state.isAppEnabled(app.$1),
                        onChanged: (enabled) => ref
                            .read(approvalDashboardControllerProvider.notifier)
                            .toggleApp(app.$1, enabled),
                      ),
                      if (app.$1 == PortalAppId.approval) ...[
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () =>
                              _showFormManagementDialog(context, ref),
                          child: const Text('양식 관리'),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(mobile ? 15 : 18),
          decoration: _adminSurface(),
          child: Row(
            children: [
              const Icon(Icons.groups_outlined, color: TheWeColor.blue300),
              const SizedBox(width: 16),
              const Expanded(
                child: _AppDescription(
                  title: '인력현황',
                  description: '관리자 계정에서만 노출',
                ),
              ),
              const Chip(
                avatar: Icon(Icons.lock_outline, size: 16),
                label: Text('관리자 전용'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppDescription extends StatelessWidget {
  const _AppDescription({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: TheWeTextStyle.subtitle),
      Text(
        description,
        style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
      ),
    ],
  );
}

Future<void> _showFormManagementDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final mobile = MediaQuery.sizeOf(context).width < 600;
  if (mobile) {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: TheWeColor.background,
      builder: (sheetContext) => FractionallySizedBox(
        key: const ValueKey('mobile-form-management-sheet'),
        heightFactor: .72,
        child: _FormManagementContent(
          mobile: true,
          onClose: () => Navigator.pop(sheetContext),
        ),
      ),
    );
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: TheWeColor.background,
      child: SizedBox(
        width: 820,
        height: 640,
        child: _FormManagementContent(
          mobile: false,
          onClose: () => Navigator.pop(dialogContext),
        ),
      ),
    ),
  );
}

class _FormManagementContent extends ConsumerWidget {
  const _FormManagementContent({required this.mobile, required this.onClose});

  final bool mobile;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(approvalDashboardControllerProvider).asData?.value;
    if (state == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 16 : 24,
        mobile ? 4 : 24,
        mobile ? 16 : 24,
        mobile ? 16 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mobile) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '전자결재 양식 관리',
                    style: TheWeTextStyle.title.copyWith(fontSize: 20),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  tooltip: '닫기',
                ),
              ],
            ),
            Text(
              '사용하지 않는 양식은 일반 계정에서 바로 숨겨집니다.',
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showFormEditor(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('양식 추가'),
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('전자결재 양식 관리', style: TheWeTextStyle.title),
                      const SizedBox(height: 4),
                      Text(
                        '사용 여부를 끄면 일반 계정의 기안 양식에서 즉시 제외됩니다.',
                        style: TheWeTextStyle.caption.copyWith(
                          color: TheWeColor.black500,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showFormEditor(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('양식 추가'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  tooltip: '닫기',
                ),
              ],
            ),
          const SizedBox(height: 16),
          Expanded(
            child: state.formTemplates.isEmpty
                ? const Center(child: Text('등록된 양식이 없습니다.'))
                : ListView.separated(
                    itemCount: state.formTemplates.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final template = state.formTemplates[index];
                      final enabled = !state.disabledFormTemplateIds.contains(
                        template.id,
                      );
                      return _FormTemplateCard(
                        template: template,
                        enabled: enabled,
                        mobile: mobile,
                        onEnabledChanged: (value) => ref
                            .read(approvalDashboardControllerProvider.notifier)
                            .toggleFormTemplate(template.id, value),
                        onEdit: () =>
                            _showFormEditor(context, ref, template: template),
                        onDelete: () =>
                            _deleteFormTemplate(context, ref, template),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FormTemplateCard extends StatelessWidget {
  const _FormTemplateCard({
    required this.template,
    required this.enabled,
    required this.mobile,
    required this.onEnabledChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final ApprovalFormTemplate template;
  final bool enabled;
  final bool mobile;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(14, mobile ? 9 : 10, 7, mobile ? 9 : 10),
    decoration: BoxDecoration(
      color: TheWeColor.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: TheWeColor.black300.withValues(alpha: .18)),
    ),
    child: mobile
        ? Column(
            children: [
              Row(
                children: [
                  Expanded(child: _FormTemplateDescription(template: template)),
                  Switch(
                    key: ValueKey('form-switch-${template.id}'),
                    value: enabled,
                    onChanged: onEnabledChanged,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('수정'),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('삭제'),
                    style: TextButton.styleFrom(
                      foregroundColor: TheWeColor.danger,
                    ),
                  ),
                ],
              ),
            ],
          )
        : Row(
            children: [
              Expanded(child: _FormTemplateDescription(template: template)),
              Switch(
                key: ValueKey('form-switch-${template.id}'),
                value: enabled,
                onChanged: onEnabledChanged,
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: '양식 수정',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: TheWeColor.danger,
                tooltip: '양식 삭제',
              ),
            ],
          ),
  );
}

class _FormTemplateDescription extends StatelessWidget {
  const _FormTemplateDescription({required this.template});

  final ApprovalFormTemplate template;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(template.name, style: TheWeTextStyle.subtitle),
      const SizedBox(height: 3),
      Text(
        '${template.category} · ${template.description}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
      ),
    ],
  );
}

Future<void> _deleteFormTemplate(
  BuildContext context,
  WidgetRef ref,
  ApprovalFormTemplate template,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: TheWeColor.surfaceAlt,
      title: const Text('양식 삭제'),
      content: Text('${template.name} 양식을 삭제할까요?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: TheWeColor.danger),
          child: const Text('삭제'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    ref
        .read(approvalDashboardControllerProvider.notifier)
        .deleteFormTemplate(template.id);
  }
}

Future<void> _showFormEditor(
  BuildContext context,
  WidgetRef ref, {
  ApprovalFormTemplate? template,
}) async {
  final category = TextEditingController(text: template?.category);
  final name = TextEditingController(text: template?.name);
  final description = TextEditingController(text: template?.description);
  final defaultTitle = TextEditingController(text: template?.defaultTitle);
  final defaultContent = TextEditingController(text: template?.defaultContent);
  var error = '';

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: TheWeColor.surfaceAlt,
        title: Text(template == null ? '양식 추가' : '양식 수정'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: category,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: '분류'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: '양식명'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: description,
                  decoration: const InputDecoration(labelText: '설명'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: defaultTitle,
                  decoration: const InputDecoration(labelText: '기본 제목'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: defaultContent,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: '기본 본문'),
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
                  .saveFormTemplate(
                    templateId: template?.id,
                    category: category.text,
                    name: name.text,
                    description: description.text,
                    defaultTitle: defaultTitle.text,
                    defaultContent: defaultContent.text,
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

class _SettingsPasswordGate extends ConsumerStatefulWidget {
  const _SettingsPasswordGate({required this.onUnlocked});
  final VoidCallback onUnlocked;
  @override
  ConsumerState<_SettingsPasswordGate> createState() =>
      _SettingsPasswordGateState();
}

class _SettingsPasswordGateState extends ConsumerState<_SettingsPasswordGate> {
  final controller = TextEditingController();
  String error = '';
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 460,
      padding: const EdgeInsets.all(30),
      decoration: _adminSurface(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 48),
          const SizedBox(height: 16),
          Text('통합설정 보안 확인', style: TheWeTextStyle.title),
          const SizedBox(height: 8),
          const Text('현재 계정 비밀번호를 다시 입력해 주세요.'),
          const SizedBox(height: 20),
          TextField(
            controller: controller,
            obscureText: true,
            onSubmitted: (_) => _verify(),
            decoration: InputDecoration(
              labelText: '비밀번호',
              errorText: error.isEmpty ? null : error,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: _verify, child: const Text('통합설정 열기')),
        ],
      ),
    ),
  );
  void _verify() {
    if (ref
        .read(approvalDashboardControllerProvider.notifier)
        .verifyCurrentPassword(controller.text)) {
      widget.onUnlocked();
    } else {
      setState(() => error = '비밀번호가 올바르지 않습니다.');
    }
  }
}

class _IntegratedSettings extends ConsumerWidget {
  const _IntegratedSettings({required this.state});
  final ApprovalDashboardState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('로그인 및 권한 보안', style: TheWeTextStyle.title),
        const SizedBox(height: 6),
        Text(
          '아래 보안 정책은 현재 관리자 인증 흐름에 필수로 적용되어 있습니다.',
          style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: _adminSurface(),
          child: const Column(
            children: [
              _SecurityPolicyTile(
                icon: Icons.phonelink_lock_outlined,
                title: '관리자 OTP 2차 인증',
                subtitle: '관리자 모드 전환 시 6자리 OTP 인증을 필수로 요구합니다.',
              ),
              Divider(height: 1),
              _SecurityPolicyTile(
                icon: Icons.password_outlined,
                title: '통합설정 비밀번호 재확인',
                subtitle: '통합설정 진입 전에 현재 계정 비밀번호를 다시 확인합니다.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('근속연수별 연차 설정', style: TheWeTextStyle.title),
        const SizedBox(height: 12),
        _AnnualLeavePolicyEditor(policy: state.annualLeaveByYear),
      ],
    );
  }
}

class _SecurityPolicyTile extends StatelessWidget {
  const _SecurityPolicyTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    leading: Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: TheWeColor.blueSurface,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: TheWeColor.blue300),
    ),
    title: Text(title, style: TheWeTextStyle.subtitle),
    subtitle: Text(subtitle),
    trailing: Chip(
      avatar: const Icon(
        Icons.check_circle_outline,
        size: 17,
        color: TheWeColor.green,
      ),
      label: const Text('사용 중'),
      side: BorderSide(color: TheWeColor.green.withValues(alpha: .28)),
      backgroundColor: TheWeColor.green.withValues(alpha: .08),
    ),
  );
}

class _AnnualLeavePolicyEditor extends ConsumerStatefulWidget {
  const _AnnualLeavePolicyEditor({required this.policy});

  final Map<int, int> policy;

  @override
  ConsumerState<_AnnualLeavePolicyEditor> createState() =>
      _AnnualLeavePolicyEditorState();
}

class _AnnualLeavePolicyEditorState
    extends ConsumerState<_AnnualLeavePolicyEditor> {
  late final Map<int, TextEditingController> controllers;
  bool dirty = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    controllers = {
      for (final entry in widget.policy.entries.where((item) => item.key <= 10))
        entry.key: TextEditingController(text: entry.value.toString()),
    };
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Container(
      padding: EdgeInsets.all(mobile ? 15 : 22),
      decoration: _adminSurface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mobile) ...[
            Text(
              '근속연수에 따라 지급할 연차 일수를 입력해 주세요.',
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: dirty ? _save : null,
                icon: const Icon(Icons.save_outlined),
                label: const Text('연차 설정 저장'),
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: Text(
                    '근속연수에 따라 지급할 연차 일수를 입력한 뒤 저장해 주세요.',
                    style: TheWeTextStyle.body.copyWith(
                      color: TheWeColor.black500,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: dirty ? _save : null,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('연차 설정 저장'),
                ),
              ],
            ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth < 600
                  ? (constraints.maxWidth - 8) / 2
                  : 150.0;
              return Wrap(
                spacing: mobile ? 8 : 12,
                runSpacing: mobile ? 8 : 12,
                children: controllers.entries
                    .map(
                      (entry) => SizedBox(
                        width: itemWidth,
                        child: TextField(
                          key: ValueKey('annual-leave-${entry.key}'),
                          controller: entry.value,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {
                            dirty = true;
                            error = '';
                          }),
                          decoration: InputDecoration(
                            labelText: '${entry.key}년차',
                            suffixText: '일',
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              error,
              style: TheWeTextStyle.caption.copyWith(color: TheWeColor.danger),
            ),
          ],
        ],
      ),
    );
  }

  void _save() {
    final policy = <int, int>{};
    for (final entry in controllers.entries) {
      final days = int.tryParse(entry.value.text.trim());
      if (days == null || days < 1 || days > 365) {
        setState(() => error = '${entry.key}년차 연차 일수를 확인해 주세요.');
        return;
      }
      policy[entry.key] = days;
    }
    final message = ref
        .read(approvalDashboardControllerProvider.notifier)
        .updateAnnualLeavePolicies(policy);
    if (message != null) {
      setState(() => error = message);
      return;
    }
    setState(() {
      dirty = false;
      error = '';
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('연차 설정이 저장되었습니다.')));
  }
}

class _AdminMetric extends StatelessWidget {
  const _AdminMetric({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });
  final double width;
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final compact = width < 220;
    return Container(
      width: width,
      padding: EdgeInsets.all(compact ? 13 : 20),
      decoration: _adminSurface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: TheWeColor.blue300, size: compact ? 22 : 24),
          SizedBox(height: compact ? 9 : 16),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TheWeTextStyle.caption.copyWith(
              color: TheWeColor.black500,
              fontSize: compact ? 12 : null,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: compact
                ? TheWeTextStyle.metric.copyWith(fontSize: 24)
                : TheWeTextStyle.metric,
          ),
        ],
      ),
    );
  }
}

BoxDecoration _adminSurface() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: TheWeColor.black300.withValues(alpha: .22)),
  boxShadow: const [
    BoxShadow(color: Color(0x08000000), blurRadius: 18, offset: Offset(0, 8)),
  ],
);

Future<String?> _requestOtp(BuildContext context) async {
  final controller = TextEditingController();
  final mobile = MediaQuery.sizeOf(context).width < 600;
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: mobile ? 22 : 40,
        vertical: 24,
      ),
      backgroundColor: Colors.white,
      title: const Text('OTP 2차 인증'),
      content: SizedBox(
        width: mobile ? double.maxFinite : 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('관리자 OTP 앱에 표시된 6자리 번호를 입력하세요.'),
            const SizedBox(height: 6),
            Text(
              '프로토타입 인증번호: 123456',
              style: TheWeTextStyle.caption.copyWith(color: TheWeColor.blue300),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'OTP 인증번호'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('인증'),
        ),
      ],
    ),
  );
}
