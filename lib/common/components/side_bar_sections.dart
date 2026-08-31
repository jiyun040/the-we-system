import 'side_bar_dependencies.dart';

class SideBarCategorySection extends StatelessWidget {
  const SideBarCategorySection({
    super.key,
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

class SideBarBrand extends ConsumerWidget {
  const SideBarBrand({
    super.key,
    required this.isCompact,
    required this.currentUser,
  });

  final bool isCompact;
  final EmployeeAccount? currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPhone = MediaQuery.sizeOf(context).width < 520;
    final state = ref.watch(approvalDashboardControllerProvider).asData?.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TheWeLogo(height: isPhone ? 30 : 34, bytes: state?.customLogoBytes),
            if (!isCompact) ...[
              TheWeGaps.horizontalLg,
              Expanded(
                child: Text(
                  state?.portalName ?? '더우리기술 전자결재',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TheWeTextStyle.title,
                ),
              ),
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
                  state?.isAdminMode == true
                      ? '관리자 모드 · 전체 관리 가능'
                      : currentUser!.email,
                  style: TheWeTextStyle.caption.copyWith(
                    color: state?.isAdminMode == true
                        ? TheWeColor.blue300
                        : TheWeColor.black500,
                  ),
                ),
                if (currentUser!.canAccessAdminMode) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final notifier = ref.read(
                          approvalDashboardControllerProvider.notifier,
                        );
                        if (state?.isAdminMode == true) {
                          notifier.leaveAdminMode();
                          context.goNamed(AppRouteName.home);
                          return;
                        }
                        var otp = '';
                        if (state?.adminOtpEnabled ?? true) {
                          final verified = await _showAdminOtpDialog(context);
                          if (verified == null || !context.mounted) return;
                          otp = verified;
                        }
                        final entered = await notifier.enterAdminMode(otp);
                        if (!context.mounted) return;
                        if (entered) {
                          context.goNamed(AppRouteName.admin);
                          return;
                        }
                        showTheWeSnackBar(
                          context,
                          message: 'OTP 번호가 올바르지 않습니다.',
                          type: TheWeSnackBarType.error,
                        );
                      },
                      icon: Icon(
                        state?.isAdminMode == true
                            ? Icons.person_outline
                            : Icons.admin_panel_settings_outlined,
                        size: 18,
                      ),
                      label: Text(
                        state?.isAdminMode == true ? '일반 계정 화면' : '관리자 계정 전환',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

Future<String?> _showAdminOtpDialog(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('OTP 2차 인증'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('관리자 OTP 번호 6자리를 입력하세요.'),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'OTP 인증번호'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('인증'),
        ),
      ],
    ),
  );
}

class SideBarNewApprovalButton extends ConsumerWidget {
  const SideBarNewApprovalButton({super.key, required this.isCompact});

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
        templates: state.activeFormTemplates,
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
