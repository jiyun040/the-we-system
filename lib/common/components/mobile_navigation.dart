import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/components/the_we_modal.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';

class MobileNavigationBar extends ConsumerWidget {
  const MobileNavigationBar({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(approvalDashboardControllerProvider).asData?.value;
    final destinations = <(String, NavigationDestination)>[
      const (
        'home',
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_outlined, color: TheWeColor.blue300),
          label: '홈',
        ),
      ),
      if (state?.isAppEnabled(PortalAppId.approval) ?? true)
        const (
          PortalAppId.approval,
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(
              Icons.description_outlined,
              color: TheWeColor.blue300,
            ),
            label: '결재',
          ),
        ),
      if (state?.isAppEnabled(PortalAppId.attendance) ?? true)
        const (
          PortalAppId.attendance,
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(
              Icons.schedule_outlined,
              color: TheWeColor.blue300,
            ),
            label: '근태',
          ),
        ),
      if (state?.isAppEnabled(PortalAppId.leave) ?? true)
        const (
          PortalAppId.leave,
          NavigationDestination(
            icon: Icon(Icons.beach_access_outlined),
            selectedIcon: Icon(
              Icons.beach_access_outlined,
              color: TheWeColor.blue300,
            ),
            label: '휴가',
          ),
        ),
      const (
        'logout',
        NavigationDestination(
          icon: Icon(Icons.logout_outlined),
          selectedIcon: Icon(Icons.logout_outlined, color: TheWeColor.blue300),
          label: '로그아웃',
        ),
      ),
    ];
    final path = GoRouterState.of(context).uri.path;
    final selectedId = path == AppRoutePath.absence
        ? PortalAppId.attendance
        : path == AppRoutePath.leave
        ? PortalAppId.leave
        : path.contains('/approval/')
        ? PortalAppId.approval
        : 'home';
    final routeIndex = destinations.indexWhere((item) => item.$1 == selectedId);
    final selectedIndex = routeIndex >= 0
        ? routeIndex
        : currentIndex.clamp(0, destinations.length - 1);

    return NavigationBar(
      selectedIndex: selectedIndex,
      backgroundColor: TheWeColor.white,
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
      onDestinationSelected: (index) async {
        switch (destinations[index].$1) {
          case 'home':
            context.goNamed(AppRouteName.home);
          case PortalAppId.approval:
            context.goNamed(AppRouteName.box, pathParameters: {'kind': 'all'});
          case PortalAppId.attendance:
            context.goNamed(AppRouteName.absence);
          case PortalAppId.leave:
            context.goNamed(AppRouteName.leave);
          case 'logout':
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => TheWeConfirmDialog(
                title: '로그아웃할까요?',
                message: '현재 계정에서 로그아웃됩니다.',
                primaryLabel: '로그아웃',
                secondaryLabel: '취소',
                primaryColor: TheWeColor.danger,
                onPrimaryPressed: () => Navigator.of(context).pop(true),
                onSecondaryPressed: () => Navigator.of(context).pop(false),
              ),
            );
            if (confirmed != true || !context.mounted) {
              return;
            }
            ref.read(approvalDashboardControllerProvider.notifier).logout();
            context.goNamed(AppRouteName.home);
        }
      },
      destinations: destinations.map((item) => item.$2).toList(),
    );
  }
}
