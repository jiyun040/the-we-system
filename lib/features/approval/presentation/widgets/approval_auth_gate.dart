import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_we_system/common/constants/color.dart';
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
          child: Icon(Icons.cloud_off_outlined, color: TheWeColor.black500),
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
