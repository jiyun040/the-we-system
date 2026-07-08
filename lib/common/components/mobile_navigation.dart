import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/components/the_we_modal.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';

class MobileNavigationBar extends ConsumerWidget {
  const MobileNavigationBar({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NavigationBar(
      selectedIndex: currentIndex,
      backgroundColor: TheWeColor.white,
      indicatorColor: TheWeColor.blue100.withValues(alpha: 0.7),
      labelTextStyle: WidgetStatePropertyAll(
        TheWeTextStyle.caption.copyWith(fontWeight: FontWeight.w700),
      ),
      onDestinationSelected: (index) async {
        switch (index) {
          case 0:
            context.goNamed(AppRouteName.home);
          case 1:
            context.goNamed(AppRouteName.box, pathParameters: {'kind': 'all'});
          case 2:
            context.goNamed(AppRouteName.absence);
          case 3:
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => TheWeConfirmDialog(
                title: '로그아웃할까요?',
                message: '현재 계정에서 로그아웃됩니다.',
                primaryLabel: '로그아웃',
                secondaryLabel: '취소',
                primaryColor: TheWeColor.green,
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
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          label: '결재',
        ),
        NavigationDestination(icon: Icon(Icons.schedule_outlined), label: '근태'),
        NavigationDestination(icon: Icon(Icons.logout_outlined), label: '로그아웃'),
      ],
    );
  }
}
