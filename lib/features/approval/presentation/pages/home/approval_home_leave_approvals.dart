part of 'approval_home_page.dart';

class _LeaveApprovalSection extends ConsumerWidget {
  const _LeaveApprovalSection({required this.state});

  final ApprovalDashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = state.actionableLeaveRequests;
    final mobile = MediaQuery.sizeOf(context).width < 700;

    Future<void> decide(LeaveRequest request, bool approve) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: TheWeColor.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(approve ? '휴가 승인' : '휴가 반려'),
          content: Text(approve ? '이 휴가 신청을 승인할까요?' : '이 휴가 신청을 반려할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: TheWeColor.black900,
                foregroundColor: TheWeColor.white,
              ),
              child: Text(approve ? '승인' : '반려'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      final result = ref
          .read(approvalDashboardControllerProvider.notifier)
          .actOnLeave(request.id, approve: approve);
      if (!context.mounted) return;
      showTheWeSnackBar(
        context,
        message: result ? '휴가 결재가 처리되었습니다.' : '휴가 결재를 처리하지 못했습니다.',
        type: result ? TheWeSnackBarType.success : TheWeSnackBarType.error,
      );
    }

    Widget card(LeaveRequest request) {
      final employee = state.accounts
          .where((account) => account.id == request.userId)
          .firstOrNull;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TheWeColor.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TheWeColor.black300.withValues(alpha: .28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${employee?.name ?? request.userId} · ${employee?.department ?? ''}',
              style: TheWeTextStyle.subtitle,
            ),
            const SizedBox(height: 10),
            Text('${request.type} · ${request.startDate} ~ ${request.endDate}'),
            const SizedBox(height: 5),
            Text('사유  ${request.reason}'),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => decide(request, false),
                  child: const Text('반려'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => decide(request, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: TheWeColor.black900,
                    foregroundColor: TheWeColor.white,
                  ),
                  child: const Text('승인'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('휴가 결재 대기', style: TheWeTextStyle.title),
        const SizedBox(height: 6),
        Text(
          '대표 계정에서 승인해야 하는 휴가만 표시됩니다.',
          style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
        ),
        const SizedBox(height: 14),
        if (mobile)
          ...requests.map(
            (request) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: card(request),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: requests
                .map((request) => SizedBox(width: 390, child: card(request)))
                .toList(),
          ),
      ],
    );
  }
}
