import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_we_system/common/components/mobile_navigation.dart';
import 'package:the_we_system/common/components/side_bar.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';

class ApprovalAbsencePage extends ConsumerWidget {
  const ApprovalAbsencePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(approvalDashboardControllerProvider);
    return Scaffold(
      backgroundColor: TheWeColor.white,
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 520
          ? const MobileNavigationBar(currentIndex: 2)
          : null,
      body: state.when(
        data: (value) {
          final content = Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_sync_outlined,
                      size: 44,
                      color: TheWeColor.black500,
                    ),
                    const SizedBox(height: 16),
                    Text('근태 데이터가 연결되지 않았습니다.', style: TheWeTextStyle.title),
                    const SizedBox(height: 8),
                    Text(
                      '서버에서 제공하는 실제 근태 데이터가 준비되면 이 화면에 표시됩니다.',
                      textAlign: TextAlign.center,
                      style: TheWeTextStyle.body.copyWith(
                        color: TheWeColor.black500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          if (MediaQuery.sizeOf(context).width < 520) {
            return Row(children: [content]);
          }
          return Row(
            children: [
              SideBar(
                frequentForms: value.dashboard.frequentForms,
                pendingDocument: value.dashboard.pendingCount,
                receiveDocument: value.dashboard.receivedCount,
                openPendingDocument: value.dashboard.referenceCount,
                scheduledDocument: value.dashboard.scheduledCount,
              ),
              const SideBarDivider(),
              content,
            ],
          );
        },
        error: (error, stackTrace) => Center(
          child: Text('서버 데이터를 불러오지 못했습니다.', style: TheWeTextStyle.subtitle),
        ),
        loading: () =>
            Center(child: CircularProgressIndicator(color: TheWeColor.blue300)),
      ),
    );
  }
}
