import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_we_system/common/components/side_bar.dart';
import 'package:the_we_system/common/components/the_we_logo.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';

class MobileNavigationAppBar extends ConsumerWidget
    implements PreferredSizeWidget {
  const MobileNavigationAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(54);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(approvalDashboardControllerProvider).asData?.value;
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: TheWeColor.white,
      surfaceTintColor: TheWeColor.white,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          key: const ValueKey('mobile-navigation-menu-button'),
          tooltip: '메뉴 열기',
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: const Icon(Icons.menu_rounded),
        ),
      ),
      titleSpacing: 2,
      title: Row(
        children: [
          TheWeLogo(height: 27, bytes: state?.customLogoBytes),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              state?.portalName ?? '우리기술 전자결재',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TheWeTextStyle.subtitle.copyWith(fontSize: 16),
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          color: TheWeColor.black300.withValues(alpha: .22),
        ),
      ),
    );
  }
}

class MobileNavigationDrawer extends ConsumerWidget {
  const MobileNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(approvalDashboardControllerProvider).asData?.value;
    final dashboard = state?.dashboard;
    return Drawer(
      key: const ValueKey('mobile-navigation-drawer'),
      width: math.min(MediaQuery.sizeOf(context).width * .88, 340),
      backgroundColor: const Color(0xFFFCFCFD),
      surfaceTintColor: const Color(0xFFFCFCFD),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: Builder(
        builder: (drawerContext) => SideBar(
          forceExpanded: true,
          onNavigate: () => Navigator.of(drawerContext).pop(),
          frequentForms: dashboard?.frequentForms ?? const [],
          pendingDocument: dashboard?.pendingCount ?? 0,
          receiveDocument: dashboard?.receivedCount ?? 0,
          openPendingDocument: dashboard?.referenceCount ?? 0,
          scheduledDocument: dashboard?.scheduledCount ?? 0,
        ),
      ),
    );
  }
}
