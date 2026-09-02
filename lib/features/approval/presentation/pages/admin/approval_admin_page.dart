import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/components/the_we_logo.dart';
import 'package:the_we_system/common/components/the_we_modal.dart';
import 'package:the_we_system/common/components/the_we_snack_bar.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'approval_admin_apps_forms.dart';
import 'approval_admin_dashboard_access.dart';
import 'approval_admin_direct_leave.dart';
import 'approval_admin_document_access.dart';
import 'approval_admin_notices.dart';
import 'approval_admin_people_organization.dart';
import 'approval_admin_settings.dart';

class ApprovalAdminPage extends ConsumerStatefulWidget {
  const ApprovalAdminPage({super.key});

  @override
  ConsumerState<ApprovalAdminPage> createState() => _ApprovalAdminPageState();
}

class _ApprovalAdminPageState extends ConsumerState<ApprovalAdminPage> {
  int selectedIndex = 0;
  bool settingsUnlocked = false;

  static const destinations = [
    (Icons.dashboard_outlined, '근태 관리'),
    (Icons.folder_shared_outlined, '결재 문서 관리'),
    (Icons.people_outline, '사원 관리'),
    (Icons.account_tree_outlined, '조직 관리'),
    (Icons.apps_outlined, 'APP 관리'),
    (Icons.tune_outlined, '통합 설정'),
    (Icons.campaign_outlined, '공지 관리'),
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
                canManageNotices: state.canManageNotices,
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
                    logoBytes: state.customLogoBytes,
                    canManageNotices: state.canManageNotices,
                    onSelected: (value) =>
                        setState(() => selectedIndex = value),
                    onLeave: _leaveAdmin,
                    onLogout: _logout,
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
                            onLogout: _logout,
                          ),
                        Expanded(
                          child: SingleChildScrollView(
                            key: ValueKey('admin-page-scroll-$selectedIndex'),
                            padding: EdgeInsets.all(mobile ? 14 : 28),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 1320,
                                ),
                                child: switch (selectedIndex) {
                                  0 => AdminDashboard(state: state),
                                  1 => AdminDocumentAccessManagement(
                                    state: state,
                                  ),
                                  2 => AdminEmployeeManagement(state: state),
                                  3 => AdminOrganizationManagement(
                                    state: state,
                                  ),
                                  4 => AdminAppManagement(state: state),
                                  5 =>
                                    !state.settingsPasswordEnabled ||
                                            settingsUnlocked
                                        ? AdminIntegratedSettings(state: state)
                                        : AdminSettingsPasswordGate(
                                            onUnlocked: () => setState(
                                              () => settingsUnlocked = true,
                                            ),
                                          ),
                                  _ => AdminNoticeManagement(state: state),
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

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => TheWeConfirmDialog(
        title: '로그아웃할까요?',
        message: '관리자 계정에서 로그아웃됩니다.',
        primaryLabel: '로그아웃',
        secondaryLabel: '취소',
        primaryColor: TheWeColor.danger,
        onPrimaryPressed: () => Navigator.of(context).pop(true),
        onSecondaryPressed: () => Navigator.of(context).pop(false),
      ),
    );
    if (confirmed != true || !mounted) return;
    ref.read(approvalDashboardControllerProvider.notifier).logout();
    context.goNamed(AppRouteName.home);
  }

  Future<void> _showCompactMenu(ApprovalDashboardState state) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: state.canManageNotices
            ? destinations.length
            : destinations.length - 1,
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
          decoration: adminSurface(),
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
                  final otp = await requestAdminOtp(context);
                  if (otp == null) return;
                  final success = await ref
                      .read(approvalDashboardControllerProvider.notifier)
                      .enterAdminMode(otp);
                  if (success) {
                    onVerified();
                  }
                  if (!success && context.mounted) {
                    showTheWeSnackBar(
                      context,
                      message: 'OTP 번호가 올바르지 않습니다.',
                      type: TheWeSnackBarType.error,
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
    required this.logoBytes,
    required this.canManageNotices,
    required this.onSelected,
    required this.onLeave,
    required this.onLogout,
  });
  final int selectedIndex;
  final String portalName;
  final Uint8List? logoBytes;
  final bool canManageNotices;
  final ValueChanged<int> onSelected;
  final VoidCallback onLeave;
  final VoidCallback onLogout;

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
          TheWeLogo(bytes: logoBytes),
          const SizedBox(height: 8),
          Text(
            portalName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
          ),
          const SizedBox(height: 30),
          ...List.generate(
            canManageNotices
                ? _ApprovalAdminPageState.destinations.length
                : _ApprovalAdminPageState.destinations.length - 1,
            (index) {
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
            },
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: onLeave,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('일반 계정 화면'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('admin-logout-button'),
            onPressed: onLogout,
            icon: const Icon(Icons.logout_outlined),
            label: const Text('로그아웃'),
            style: OutlinedButton.styleFrom(
              foregroundColor: TheWeColor.danger,
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
    required this.onLogout,
  });
  final bool mobile;
  final VoidCallback? onOpenMenu;
  final VoidCallback onLeave;
  final VoidCallback onLogout;
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
        IconButton(
          key: const ValueKey('admin-logout-button'),
          onPressed: onLogout,
          tooltip: '로그아웃',
          color: TheWeColor.danger,
          icon: const Icon(Icons.logout_outlined),
        ),
      ],
    ),
  );
}

class _AdminBottomNavigation extends StatelessWidget {
  const _AdminBottomNavigation({
    required this.selectedIndex,
    required this.canManageNotices,
    required this.onSelected,
  });

  final int selectedIndex;
  final bool canManageNotices;
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
      for (final destination in _ApprovalAdminPageState.destinations.take(
        canManageNotices
            ? _ApprovalAdminPageState.destinations.length
            : _ApprovalAdminPageState.destinations.length - 1,
      ))
        NavigationDestination(
          icon: Icon(destination.$1),
          selectedIcon: Icon(destination.$1, color: TheWeColor.blue300),
          label: destination.$2,
        ),
    ],
  );
}
