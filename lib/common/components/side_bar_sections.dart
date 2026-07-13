part of 'side_bar.dart';

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.icon,
    required this.isCompact,
    required this.children,
    required this.initiallyExpanded,
  });

  final String title;
  final IconData icon;
  final bool isCompact;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Column(children: children);
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(TheWeRadius.xl),
        border: Border.all(color: TheWeColor.black300.withValues(alpha: 0.18)),
      ),
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            leading: Icon(icon, color: TheWeColor.black900),
            title: Text(title, style: TheWeTextStyle.subtitle),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _Brand extends ConsumerWidget {
  const _Brand({required this.isCompact, required this.currentUser});

  final bool isCompact;
  final EmployeeAccount? currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPhone = MediaQuery.sizeOf(context).width < 520;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: isPhone ? 36 : 40,
              height: isPhone ? 36 : 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TheWeColor.blue300,
                borderRadius: BorderRadius.circular(TheWeRadius.md),
              ),
              child: Text(
                'W',
                style: TheWeTextStyle.subtitle.copyWith(color: Colors.white),
              ),
            ),
            if (!isCompact) ...[
              TheWeGaps.horizontalLg,
              Expanded(child: Text('경영업무포털', style: TheWeTextStyle.title)),
            ],
          ],
        ),
        if (!isCompact && currentUser != null) ...[
          TheWeGaps.verticalXl,
          Container(
            width: double.infinity,
            padding: TheWeInsets.card,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FC),
              borderRadius: BorderRadius.circular(TheWeRadius.xl),
              border: Border.all(
                color: TheWeColor.blue100.withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${currentUser!.name} ${currentUser!.position}',
                        style: TheWeTextStyle.subtitle,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => TheWeConfirmDialog(
                            title: '로그아웃할까요?',
                            message: '현재 계정에서 로그아웃됩니다.',
                            primaryLabel: '로그아웃',
                            secondaryLabel: '취소',
                            primaryColor: TheWeColor.danger,
                            onPrimaryPressed: () =>
                                Navigator.of(context).pop(true),
                            onSecondaryPressed: () =>
                                Navigator.of(context).pop(false),
                          ),
                        );
                        if (confirmed != true) {
                          return;
                        }
                        ref
                            .read(approvalDashboardControllerProvider.notifier)
                            .logout();
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      tooltip: '로그아웃',
                    ),
                  ],
                ),
                Text(
                  '${currentUser!.department}  |  ${currentUser!.id}',
                  style: TheWeTextStyle.caption.copyWith(
                    color: TheWeColor.black500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser!.isAdmin
                      ? '전체 직원 문서 열람/관리 가능'
                      : currentUser!.email,
                  style: TheWeTextStyle.caption.copyWith(
                    color: currentUser!.isAdmin
                        ? TheWeColor.blue300
                        : TheWeColor.black500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _NewApprovalButton extends ConsumerWidget {
  const _NewApprovalButton({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> openFormPicker() async {
      final state = ref.read(approvalDashboardControllerProvider).asData?.value;
      if (state == null) {
        return;
      }

      final selected = await showDraftFormSelectionDialog(
        context,
        templates: state.formTemplates,
      );
      if (selected == null || !context.mounted) {
        return;
      }

      context.pushNamed(
        AppRouteName.draft,
        queryParameters: {'form': selected.id},
      );
    }

    if (isCompact) {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: IconButton.filled(
          onPressed: openFormPicker,
          icon: const Icon(Icons.add, size: 18),
          tooltip: '새 결재 진행',
          style: IconButton.styleFrom(
            backgroundColor: TheWeColor.black900,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TheWeRadius.md),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: FilledButton.icon(
        onPressed: openFormPicker,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('새 결재 진행'),
        style: FilledButton.styleFrom(
          backgroundColor: TheWeColor.black900,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TheWeRadius.md),
          ),
          textStyle: TheWeTextStyle.makeApproval,
        ),
      ),
    );
  }
}
