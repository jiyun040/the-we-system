import 'package:flutter/services.dart';

import 'approval_admin_dependencies.dart';
import 'approval_admin_annual_leave_policy.dart';
import 'approval_admin_apps_forms.dart';
import 'approval_admin_direct_leave.dart';
import 'approval_admin_leave_approval_lines.dart';
import 'approval_admin_people_organization.dart';

class AdminSettingsPasswordGate extends ConsumerStatefulWidget {
  const AdminSettingsPasswordGate({super.key, required this.onUnlocked});
  final VoidCallback onUnlocked;
  @override
  ConsumerState<AdminSettingsPasswordGate> createState() =>
      _SettingsPasswordGateState();
}

class _SettingsPasswordGateState
    extends ConsumerState<AdminSettingsPasswordGate> {
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
      decoration: adminSurface(),
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
  Future<void> _verify() async {
    if (await ref
        .read(approvalDashboardControllerProvider.notifier)
        .verifyCurrentPassword(controller.text)) {
      widget.onUnlocked();
    } else {
      setState(() => error = '비밀번호가 올바르지 않습니다.');
    }
  }
}

class AdminIntegratedSettings extends ConsumerWidget {
  const AdminIntegratedSettings({super.key, required this.state});
  final ApprovalDashboardState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('포털 및 로고', style: TheWeTextStyle.title),
        const SizedBox(height: 6),
        Text(
          '일반 계정과 관리자 계정에 공통으로 표시할 포털명과 로고를 관리합니다.',
          style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
        ),
        const SizedBox(height: 12),
        _BrandingSettingsCard(state: state),
        const SizedBox(height: 24),
        Text('조직도 설정', style: TheWeTextStyle.title),
        const SizedBox(height: 6),
        Text(
          '부서 구성과 소속 인원을 확인하고 부서명을 수정합니다.',
          style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
        ),
        const SizedBox(height: 12),
        _IntegratedOrganizationSettings(state: state),
        const SizedBox(height: 24),
        Text('APP 설정', style: TheWeTextStyle.title),
        const SizedBox(height: 6),
        Text(
          '일반 계정 홈과 메뉴에 표시할 업무 APP을 설정합니다.',
          style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
        ),
        const SizedBox(height: 12),
        _IntegratedAppSettings(state: state),
        const SizedBox(height: 24),
        _LoginSecurityHeader(account: state.currentUser),
        const SizedBox(height: 12),
        Container(
          decoration: adminSurface(),
          child: Column(
            children: [
              _SecurityPolicyTile(
                key: const ValueKey('security-settings-password'),
                icon: Icons.password_outlined,
                title: '통합설정 비밀번호 재확인',
                subtitle: '통합설정 진입 전에 현재 계정 비밀번호를 다시 확인합니다.',
                value: state.settingsPasswordEnabled,
                onChanged: (value) => ref
                    .read(approvalDashboardControllerProvider.notifier)
                    .updateSecurityPolicy(settingsPasswordEnabled: value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('관리자 권한 설정', style: TheWeTextStyle.title),
        const SizedBox(height: 6),
        Text(
          '관리자 모드와 통합설정은 전용 관리자 계정 한 개만 사용합니다.',
          style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
        ),
        const SizedBox(height: 12),
        _AdminPermissionSettings(state: state),
        const SizedBox(height: 24),
        Text('근속연수별 연차 설정', style: TheWeTextStyle.title),
        const SizedBox(height: 12),
        AdminAnnualLeavePolicyEditor(
          policy: state.annualLeaveByYear,
          monthlyLeavePerMonth: state.monthlyLeavePerMonth,
        ),
      ],
    );
  }
}

class _LoginSecurityHeader extends ConsumerWidget {
  const _LoginSecurityHeader({required this.account});

  final EmployeeAccount? account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final changeButton = account?.canChangeAdminOtp == true
        ? FilledButton.icon(
            key: const ValueKey('admin-otp-change-button'),
            onPressed: () async {
              final changed = await showDialog<bool>(
                context: context,
                builder: (context) => const _ChangeAdminOtpDialog(),
              );
              if (changed == true && context.mounted) {
                showTheWeSnackBar(context, message: 'OTP 번호가 변경되었습니다.');
              }
            },
            icon: const Icon(Icons.pin_outlined, size: 18),
            label: const Text('OTP 번호 변경'),
          )
        : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final description = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('로그인·2차 인증', style: TheWeTextStyle.title),
            const SizedBox(height: 6),
            Text(
              '관리자 모드 진입에는 OTP 인증이 항상 필요합니다.',
              style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
            ),
          ],
        );
        if (constraints.maxWidth < 640 || changeButton == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              description,
              if (changeButton != null) ...[
                const SizedBox(height: 12),
                changeButton,
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: description),
            changeButton,
          ],
        );
      },
    );
  }
}

class _ChangeAdminOtpDialog extends ConsumerStatefulWidget {
  const _ChangeAdminOtpDialog();

  @override
  ConsumerState<_ChangeAdminOtpDialog> createState() =>
      _ChangeAdminOtpDialogState();
}

class _ChangeAdminOtpDialogState extends ConsumerState<_ChangeAdminOtpDialog> {
  final currentController = TextEditingController();
  final nextController = TextEditingController();
  final confirmController = TextEditingController();
  String error = '';
  bool saving = false;

  @override
  void dispose() {
    currentController.dispose();
    nextController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const ValueKey('admin-otp-change-dialog'),
    backgroundColor: TheWeColor.white,
    title: const Text('OTP 번호 변경'),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _otpField(controller: currentController, label: '현재 OTP'),
          const SizedBox(height: 10),
          _otpField(controller: nextController, label: '새 OTP'),
          const SizedBox(height: 10),
          _otpField(controller: confirmController, label: '새 OTP 확인'),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 8),
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
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context, false),
        child: const Text('취소'),
      ),
      FilledButton(
        key: const ValueKey('admin-otp-change-submit'),
        onPressed: saving ? null : _submit,
        child: Text(saving ? '변경 중...' : '변경'),
      ),
    ],
  );

  Widget _otpField({
    required TextEditingController controller,
    required String label,
  }) => TextField(
    controller: controller,
    obscureText: true,
    keyboardType: TextInputType.number,
    maxLength: 6,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label, counterText: ''),
  );

  Future<void> _submit() async {
    final currentOtp = currentController.text;
    final nextOtp = nextController.text;
    if (currentOtp.length != 6 || nextOtp.length != 6) {
      setState(() => error = 'OTP는 숫자 6자리로 입력해 주세요.');
      return;
    }
    if (nextOtp != confirmController.text) {
      setState(() => error = '새 OTP 번호가 일치하지 않습니다.');
      return;
    }
    setState(() {
      saving = true;
      error = '';
    });
    final result = await ref
        .read(approvalDashboardControllerProvider.notifier)
        .changeAdminOtp(currentOtp: currentOtp, newOtp: nextOtp);
    if (!mounted) return;
    if (result == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      saving = false;
      error = result;
    });
  }
}

class _IntegratedOrganizationSettings extends ConsumerStatefulWidget {
  const _IntegratedOrganizationSettings({required this.state});

  final ApprovalDashboardState state;

  @override
  ConsumerState<_IntegratedOrganizationSettings> createState() =>
      _IntegratedOrganizationSettingsState();
}

class _IntegratedOrganizationSettingsState
    extends ConsumerState<_IntegratedOrganizationSettings> {
  final Map<String, ExpansibleController> _controllers = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleExpansionChanged(String department, bool expanded) {
    if (!expanded) return;
    for (final entry in _controllers.entries) {
      if (entry.key != department && entry.value.isExpanded) {
        entry.value.collapse();
      }
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: adminSurface(),
    clipBehavior: Clip.antiAlias,
    child: Material(
      color: Colors.transparent,
      child: Column(
        children: [
          for (
            var index = 0;
            index < widget.state.departments.length;
            index++
          ) ...[
            Builder(
              builder: (context) {
                final department = widget.state.departments[index];
                final members =
                    widget.state.accounts
                        .where((account) => account.department == department)
                        .toList()
                      ..sort((a, b) => a.name.compareTo(b.name));
                final controller = _controllers.putIfAbsent(
                  department,
                  ExpansibleController.new,
                );
                return ExpansionTile(
                  key: PageStorageKey('organization-$department'),
                  controller: controller,
                  onExpansionChanged: (expanded) =>
                      _handleExpansionChanged(department, expanded),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  tilePadding: const EdgeInsets.only(left: 12, right: 10),
                  childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  leading: const Icon(
                    Icons.folder_shared_outlined,
                    color: TheWeColor.blue300,
                  ),
                  title: Text(department, style: TheWeTextStyle.subtitle),
                  subtitle: Text('${members.length}명 소속 · 눌러서 구성원 확인'),
                  trailing: IconButton(
                    onPressed: () =>
                        renameAdminDepartment(context, ref, department),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: '부서명 수정',
                  ),
                  children: [
                    if (members.isEmpty)
                      const ListTile(
                        dense: true,
                        leading: Icon(Icons.person_off_outlined),
                        title: Text('소속 직원이 없습니다.'),
                      )
                    else
                      ...members.map(
                        (member) => Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Material(
                            color: TheWeColor.surfaceAlt,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: TheWeColor.black300.withValues(
                                  alpha: .3,
                                ),
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: TheWeColor.blueSurface,
                                child: Text(member.name.substring(0, 1)),
                              ),
                              title: Text(
                                member.name,
                                style: TheWeTextStyle.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${member.position} · ${member.id}',
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            if (index != widget.state.departments.length - 1) adminDivider(),
          ],
        ],
      ),
    ),
  );
}

class _BrandingSettingsCard extends ConsumerStatefulWidget {
  const _BrandingSettingsCard({required this.state});

  final ApprovalDashboardState state;

  @override
  ConsumerState<_BrandingSettingsCard> createState() =>
      _BrandingSettingsCardState();
}

class _BrandingSettingsCardState extends ConsumerState<_BrandingSettingsCard> {
  late final TextEditingController portalNameController;

  @override
  void initState() {
    super.initState();
    portalNameController = TextEditingController(text: widget.state.portalName);
  }

  @override
  void didUpdateWidget(covariant _BrandingSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.portalName != widget.state.portalName &&
        portalNameController.text != widget.state.portalName) {
      portalNameController.text = widget.state.portalName;
    }
  }

  @override
  void dispose() {
    portalNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 15 : 22),
      decoration: adminSurface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TheWeLogo(height: 66, bytes: widget.state.customLogoBytes),
                const SizedBox(height: 12),
                _logoActions(context),
              ],
            )
          else
            Row(
              children: [
                TheWeLogo(height: 76, bytes: widget.state.customLogoBytes),
                const SizedBox(width: 22),
                Expanded(
                  child: Text(
                    widget.state.customLogoFileName ?? '기본 프로젝트 로고 사용 중',
                    style: TheWeTextStyle.body.copyWith(
                      color: TheWeColor.black500,
                    ),
                  ),
                ),
                _logoActions(context),
              ],
            ),
          const SizedBox(height: 18),
          TextField(
            key: const ValueKey('portal-name-field'),
            controller: portalNameController,
            decoration: const InputDecoration(labelText: '임직원 포털 명'),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _savePortalName,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('포털 명 저장'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoActions(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      OutlinedButton.icon(
        key: const ValueKey('portal-logo-upload'),
        onPressed: _pickLogo,
        icon: const Icon(Icons.upload_file_outlined, size: 18),
        label: const Text('로고 변경'),
      ),
      TextButton(
        onPressed: widget.state.customLogoBytes == null
            ? null
            : () => ref
                  .read(approvalDashboardControllerProvider.notifier)
                  .resetPortalLogo(),
        child: const Text('기본 로고'),
      ),
    ],
  );

  Future<void> _pickLogo() async {
    const imageTypes = XTypeGroup(
      label: '로고 이미지',
      extensions: ['png', 'jpg', 'jpeg', 'webp'],
    );
    final file = await openFile(acceptedTypeGroups: [imageTypes]);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final message = ref
        .read(approvalDashboardControllerProvider.notifier)
        .updatePortalLogo(bytes, file.name);
    if (!mounted) return;
    showTheWeSnackBar(
      context,
      message: message ?? '로고가 변경되었습니다.',
      type: message == null
          ? TheWeSnackBarType.success
          : TheWeSnackBarType.error,
    );
  }

  void _savePortalName() {
    if (portalNameController.text.trim().isEmpty) {
      showTheWeSnackBar(
        context,
        message: '포털 명을 입력해 주세요.',
        type: TheWeSnackBarType.error,
      );
      return;
    }
    ref
        .read(approvalDashboardControllerProvider.notifier)
        .updatePortalName(portalNameController.text);
    showTheWeSnackBar(context, message: '포털 명이 저장되었습니다.');
  }
}

class _IntegratedAppSettings extends ConsumerWidget {
  const _IntegratedAppSettings({required this.state});

  final ApprovalDashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const apps = [
      (PortalAppId.approval, '전자결재', Icons.approval_outlined),
      (PortalAppId.attendance, '근태', Icons.schedule_outlined),
      (PortalAppId.leave, '휴가', Icons.beach_access_outlined),
    ];
    return Container(
      decoration: adminSurface(),
      child: Column(
        children: [
          for (var index = 0; index < apps.length; index++) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 5,
              ),
              leading: Icon(apps[index].$3, color: TheWeColor.blue300),
              title: Text(apps[index].$2, style: TheWeTextStyle.subtitle),
              subtitle: Text(
                apps[index].$1 == PortalAppId.approval
                    ? '${state.activeFormTemplates.length}개 양식 사용 중'
                    : '일반 계정 홈과 메뉴 노출',
              ),
              trailing: Switch(
                key: ValueKey('integrated-app-switch-${apps[index].$1}'),
                value: state.isAppEnabled(apps[index].$1),
                onChanged: (value) => ref
                    .read(approvalDashboardControllerProvider.notifier)
                    .toggleApp(apps[index].$1, value),
              ),
            ),
            if (apps[index].$1 == PortalAppId.approval)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        showAdminFormManagementDialog(context, ref),
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('전자결재 양식 관리'),
                  ),
                ),
              ),
            if (apps[index].$1 == PortalAppId.leave)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    key: const ValueKey(
                      'integrated-leave-approval-line-management',
                    ),
                    onPressed: () => showAdminLeaveApprovalLineManagementDialog(
                      context,
                      state,
                    ),
                    icon: const Icon(Icons.account_tree_outlined, size: 18),
                    label: const Text('휴가 결재라인 관리'),
                  ),
                ),
              ),
            if (index != apps.length - 1) adminDivider(),
          ],
        ],
      ),
    );
  }
}

class _SecurityPolicyTile extends StatelessWidget {
  const _SecurityPolicyTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

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
    trailing: Switch(value: value, onChanged: onChanged),
  );
}

class _AdminPermissionSettings extends StatelessWidget {
  const _AdminPermissionSettings({required this.state});

  final ApprovalDashboardState state;

  @override
  Widget build(BuildContext context) {
    final account = state.accounts.where((item) => item.isAdmin).firstOrNull;
    return Container(
      decoration: adminSurface(),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: TheWeColor.blueSurface,
          child: Icon(Icons.admin_panel_settings_outlined),
        ),
        title: Text(account?.name ?? '관리자 없음', style: TheWeTextStyle.subtitle),
        subtitle: Text(
          account == null
              ? '전용 관리자 계정을 찾을 수 없습니다.'
              : '${account.department} · ${account.position} · ${account.id}',
        ),
        trailing: const Chip(label: Text('전용 관리자')),
      ),
    );
  }
}
