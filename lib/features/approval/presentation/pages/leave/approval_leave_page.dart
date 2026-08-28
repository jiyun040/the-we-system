import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_we_system/common/components/mobile_navigation.dart';
import 'package:the_we_system/common/components/side_bar.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';

import 'approval_leave_content.dart';

class ApprovalLeavePage extends ConsumerWidget {
  const ApprovalLeavePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(approvalDashboardControllerProvider);
    return Scaffold(
      backgroundColor: TheWeColor.white,
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 520
          ? const MobileNavigationBar(currentIndex: 3)
          : null,
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, stackTrace) =>
            const Center(child: Text('휴가 정보를 불러오지 못했습니다.')),
        data: (state) {
          final dashboard = state.dashboard;
          final sidebar = SideBar(
            frequentForms: dashboard.frequentForms,
            pendingDocument: dashboard.pendingCount,
            receiveDocument: dashboard.receivedCount,
            openPendingDocument: dashboard.referenceCount,
            scheduledDocument: dashboard.scheduledCount,
          );
          final content = ApprovalLeaveContent(state: state);
          if (MediaQuery.sizeOf(context).width < 520) return content;
          return Row(
            children: [
              sidebar,
              const VerticalDivider(width: 1),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}
