import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/pages/auth/approval_login_page.dart';

class ApprovalAuthGate extends ConsumerWidget {
  const ApprovalAuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(approvalDashboardControllerProvider);

    return state.when(
      data: (value) =>
          value.currentUser == null ? const ApprovalLoginPage() : child,
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_outlined, color: TheWeColor.black500),
                const SizedBox(height: 12),
                Text('서버에 연결할 수 없습니다.', style: TheWeTextStyle.subtitle),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(approvalDashboardControllerProvider),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      ),
      loading: () => Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: TheWeColor.blue300),
        ),
      ),
    );
  }
}
