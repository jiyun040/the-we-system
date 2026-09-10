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
import 'approval_admin_comprehensive_management.dart';
import 'approval_admin_dashboard_access.dart';
import 'approval_admin_direct_leave.dart';
import 'approval_admin_document_access.dart';
import 'approval_admin_notices.dart';
import 'approval_admin_people_organization.dart';
import 'approval_admin_settings.dart';

enum _AdminDestination {
  dashboard(Icons.dashboard_outlined, '근태 관리'),
  comprehensive(Icons.space_dashboard_outlined, '종합관리'),
  documentAccess(Icons.folder_shared_outlined, '결재 문서 관리'),
  employees(Icons.people_outline, '사원 관리'),
  organization(Icons.account_tree_outlined, '조직 관리'),
  apps(Icons.apps_outlined, 'APP 관리'),
  settings(Icons.tune_outlined, '통합 설정'),
  notices(Icons.campaign_outlined, '공지 관리');

  const _AdminDestination(this.icon, this.label);

  final IconData icon;
  final String label;

  bool isVisible(ApprovalDashboardState state) => switch (this) {
    comprehensive => state.canAccessComprehensiveManagement,
    notices => state.canManageNotices,
    _ => true,
  };
}

List<_AdminDestination> _visibleAdminDestinations(
  ApprovalDashboardState state,
) => _AdminDestination.values
    .where((destination) => destination.isVisible(state))
    .toList();

class ApprovalAdminPage extends ConsumerStatefulWidget {
  const ApprovalAdminPage({super.key});

  @override
  ConsumerState<ApprovalAdminPage> createState() => _ApprovalAdminPageState();
}

class _ApprovalAdminPageState extends ConsumerState<ApprovalAdminPage> {
  _AdminDestination selectedDestination = _AdminDestination.dashboard;
  bool settingsUnlocked = false;
  final ScrollController _pageScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(approvalDashboardControllerProvider);
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      backgroundColor: TheWeColor.background,
      bottomNavigationBar: asyncState.maybeWhen(
        data: (state) => state.isAdminMode && mobile
            ? _AdminBottomNavigation(
                state: state,
                selectedDestination: selectedDestination,
                onSelected: (value) =>
                    setState(() => selectedDestination = value),
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
                    state: state,
                    selectedDestination: selectedDestination,
                    portalName: state.portalName,
                    logoBytes: state.customLogoBytes,
                    onSelected: (value) =>
                        setState(() => selectedDestination = value),
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
                            key: ValueKey(
                              'admin-page-scroll-${selectedDestination.name}',
                            ),
                            controller: _pageScrollController,
                            padding: EdgeInsets.all(mobile ? 14 : 28),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 1320,
                                ),
                                child: switch (selectedDestination) {
                                  _AdminDestination.dashboard => AdminDashboard(
                                    state: state,
                                  ),
                                  _AdminDestination.comprehensive =>
                                    AdminComprehensiveManagement(state: state),
                                  _AdminDestination.documentAccess =>
                                    AdminDocumentAccessManagement(state: state),
                                  _AdminDestination.employees =>
                                    AdminEmployeeManagement(
                                      state: state,
                                      scrollController: _pageScrollController,
                                    ),
                                  _AdminDestination.organization =>
                                    AdminOrganizationManagement(state: state),
                                  _AdminDestination.apps => AdminAppManagement(
                                    state: state,
                                  ),
                                  _AdminDestination.settings =>
                                    !state.settingsPasswordEnabled ||
                                            settingsUnlocked
                                        ? AdminIntegratedSettings(state: state)
                                        : AdminSettingsPasswordGate(
                                            onUnlocked: () => setState(
                                              () => settingsUnlocked = true,
                                            ),
                                          ),
                                  _AdminDestination.notices =>
                                    AdminNoticeManagement(state: state),
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

  @override
  void dispose() {
    _pageScrollController.dispose();
    super.dispose();
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
    final destinations = _visibleAdminDestinations(state);
    final selected = await showModalBottomSheet<_AdminDestination>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: destinations.length,
        itemBuilder: (context, index) {
          final destination = destinations[index];
          return ListTile(
            selected: selectedDestination == destination,
            leading: Icon(destination.icon),
            title: Text(destination.label),
            onTap: () => Navigator.pop(context, destination),
          );
        },
      ),
    );
    if (selected != null) setState(() => selectedDestination = selected);
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
    required this.state,
    required this.selectedDestination,
    required this.portalName,
    required this.logoBytes,
    required this.onSelected,
    required this.onLeave,
    required this.onLogout,
  });
  final ApprovalDashboardState state;
  final _AdminDestination selectedDestination;
  final String portalName;
  final Uint8List? logoBytes;
  final ValueChanged<_AdminDestination> onSelected;
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
          ..._visibleAdminDestinations(state).map((destination) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                selected: selectedDestination == destination,
                selectedTileColor: TheWeColor.blueSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Icon(destination.icon),
                title: Text(destination.label),
                onTap: () => onSelected(destination),
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
    required this.state,
    required this.selectedDestination,
    required this.onSelected,
  });

  final ApprovalDashboardState state;
  final _AdminDestination selectedDestination;
  final ValueChanged<_AdminDestination> onSelected;

  @override
  Widget build(BuildContext context) {
    final destinations = _visibleAdminDestinations(state);
    final visibleSelectedIndex = destinations.indexOf(selectedDestination);
    return NavigationBar(
      selectedIndex: visibleSelectedIndex < 0 ? 0 : visibleSelectedIndex,
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
      onDestinationSelected: (index) => onSelected(destinations[index]),
      destinations: [
        for (final destination in destinations)
          NavigationDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.icon, color: TheWeColor.blue300),
            label: destination.label,
          ),
      ],
    );
  }
}
