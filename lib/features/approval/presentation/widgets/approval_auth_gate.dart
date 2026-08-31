import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/pages/auth/approval_login_page.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_error_state.dart';

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
        backgroundColor: TheWeColor.white,
        body: ApprovalErrorState(
          error: error,
          title: '서버에 연결할 수 없습니다.',
          onRetry: () => ref.invalidate(approvalDashboardControllerProvider),
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
