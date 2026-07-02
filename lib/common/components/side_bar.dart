import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/domain/entities/approval_form.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_dialogs.dart';

class SideBar extends ConsumerWidget {
  const SideBar({
    super.key,
    required this.frequentForms,
    required this.pendingDocument,
    required this.receiveDocument,
    required this.openPendingDocument,
    required this.scheduledDocument,
  });

  final List<ApprovalForm> frequentForms;
  final int pendingDocument;
  final int receiveDocument;
  final int openPendingDocument;
  final int scheduledDocument;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 900;
    final isPhone = screenWidth < 520;
    final sideBarWidth = isPhone ? 72.0 : (isCompact ? 96.0 : 320.0);
    final state = ref.watch(approvalDashboardControllerProvider).asData?.value;
    final currentUser = state?.currentUser;
    final currentPath = GoRouterState.of(context).uri.path;
    final onHomePage = currentPath == AppRoutePath.home;
    final attendanceSection =
        GoRouterState.of(context).uri.queryParameters['section'] ?? 'my-status';
    final attendanceView =
        GoRouterState.of(context).uri.queryParameters['view'] ?? 'weekly';
    final onAttendancePage = currentPath == AppRoutePath.absence;
    final onReceivedPage = currentPath.contains('/approval/box/received');
    final onSentPage = currentPath.contains('/approval/box/sent');
    final onDraftPage = currentPath.contains('/approval/box/drafts');
    final onArchivePage = currentPath.contains('/approval/box/all');

    void openAttendance(String section) {
      context.goNamed(
        AppRouteName.absence,
        queryParameters: {
          'section': section,
          if (section == 'my-status') 'view': attendanceView,
        },
      );
    }

    return Container(
      width: sideBarWidth,
      color: const Color(0xFFFCFCFD),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isPhone ? 10 : (isCompact ? 14 : 20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Brand(isCompact: isCompact, currentUser: currentUser),
              const SizedBox(height: 18),
              _NewApprovalButton(isCompact: isCompact),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SideMenuItem(
                        icon: Icons.home_outlined,
                        label: '홈',
                        selected: onHomePage,
                        isCompact: isCompact,
                        onTap: () => context.goNamed(AppRouteName.home),
                      ),
                      const SizedBox(height: 8),
                      _CategorySection(
                        title: '전자결재',
                        icon: Icons.approval_outlined,
                        isCompact: isCompact,
                        initiallyExpanded: !onAttendancePage && !onHomePage,
                        children: [
                          _MenuSection(
                            title: '자주 쓰는 양식',
                            isCompact: isCompact,
                            children: frequentForms
                                .map(
                                  (form) => _SideMenuItem(
                                    icon: Icons.description_outlined,
                                    label: form.name,
                                    count: form.recentCount,
                                    isCompact: isCompact,
                                    onTap: () => context.goNamed(
                                      AppRouteName.formBox,
                                      pathParameters: {'formId': form.id},
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 18),
                          _MenuSection(
                            title: '결재하기',
                            isCompact: isCompact,
                            children: [
                              _SideMenuItem(
                                icon: Icons.inbox_outlined,
                                label: '결재대기문서',
                                count: pendingDocument,
                                selected:
                                    !onHomePage &&
                                    !onAttendancePage &&
                                    !onReceivedPage &&
                                    !onSentPage &&
                                    !onDraftPage &&
                                    !onArchivePage,
                                isCompact: isCompact,
                                onTap: () => context.goNamed(AppRouteName.home),
                              ),
                              _SideMenuItem(
                                icon: Icons.mark_email_unread_outlined,
                                label: '결재수신문서',
                                count: receiveDocument,
                                selected: onReceivedPage,
                                isCompact: isCompact,
                                onTap: () => context.goNamed(
                                  AppRouteName.box,
                                  pathParameters: {'kind': 'received'},
                                ),
                              ),
                              _SideMenuItem(
                                icon: Icons.visibility_outlined,
                                label: '참조/열람 대기',
                                count: openPendingDocument,
                                selected: onArchivePage,
                                isCompact: isCompact,
                                onTap: () => context.goNamed(
                                  AppRouteName.box,
                                  pathParameters: {'kind': 'all'},
                                ),
                              ),
                              _SideMenuItem(
                                icon: Icons.event_available_outlined,
                                label: '결재예정문서',
                                count: scheduledDocument,
                                selected: onSentPage,
                                isCompact: isCompact,
                                onTap: () => context.goNamed(
                                  AppRouteName.box,
                                  pathParameters: {'kind': 'sent'},
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _MenuSection(
                            title: '개인문서함',
                            isCompact: isCompact,
                            children: [
                              _SideMenuItem(
                                icon: Icons.edit_document,
                                label: '기안 문서함',
                                selected: onDraftPage,
                                isCompact: isCompact,
                                onTap: () => context.goNamed(
                                  AppRouteName.box,
                                  pathParameters: {'kind': 'drafts'},
                                ),
                              ),
                              _SideMenuItem(
                                icon: Icons.drafts_outlined,
                                label: '임시 저장함',
                                selected: onDraftPage,
                                isCompact: isCompact,
                                onTap: () => context.goNamed(
                                  AppRouteName.box,
                                  pathParameters: {'kind': 'drafts'},
                                ),
                              ),
                              _SideMenuItem(
                                icon: Icons.archive_outlined,
                                label: '결재 문서함',
                                selected: onArchivePage,
                                isCompact: isCompact,
                                onTap: () => context.goNamed(
                                  AppRouteName.box,
                                  pathParameters: {'kind': 'all'},
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _CategorySection(
                        title: '근태관리',
                        icon: Icons.schedule_outlined,
                        isCompact: isCompact,
                        initiallyExpanded: onAttendancePage,
                        children: [
                          _MenuSection(
                            title: '근태',
                            isCompact: isCompact,
                            children: [
                              _SideMenuItem(
                                icon: Icons.schedule_outlined,
                                label: '내 근태현황',
                                selected:
                                    onAttendancePage &&
                                    attendanceSection == 'my-status',
                                isCompact: isCompact,
                                onTap: () => openAttendance('my-status'),
                              ),
                              _SideMenuItem(
                                icon: Icons.groups_outlined,
                                label: '전사 근태현황',
                                selected:
                                    onAttendancePage &&
                                    attendanceSection == 'company-status',
                                isCompact: isCompact,
                                onTap: () => openAttendance('company-status'),
                              ),
                              _SideMenuItem(
                                icon: Icons.work_outline_rounded,
                                label: '근무그룹 관리',
                                selected:
                                    onAttendancePage &&
                                    attendanceSection == 'work-group',
                                isCompact: isCompact,
                                onTap: () => openAttendance('work-group'),
                              ),
                              _SideMenuItem(
                                icon: Icons.history_toggle_off_outlined,
                                label: '보상휴가 관리',
                                selected:
                                    onAttendancePage &&
                                    attendanceSection == 'compensatory-leave',
                                isCompact: isCompact,
                                onTap: () =>
                                    openAttendance('compensatory-leave'),
                              ),
                              _SideMenuItem(
                                icon: Icons.event_repeat_outlined,
                                label: '휴일대체 관리',
                                selected:
                                    onAttendancePage &&
                                    attendanceSection == 'holiday-replacement',
                                isCompact: isCompact,
                                onTap: () =>
                                    openAttendance('holiday-replacement'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _MenuSection(
                            title: '휴가',
                            isCompact: isCompact,
                            children: [
                              _SideMenuItem(
                                icon: Icons.policy_outlined,
                                label: '연차정책 관리',
                                selected:
                                    onAttendancePage &&
                                    attendanceSection == 'leave-policy',
                                isCompact: isCompact,
                                onTap: () => openAttendance('leave-policy'),
                              ),
                              _SideMenuItem(
                                icon: Icons.campaign_outlined,
                                label: '연차촉진 현황',
                                selected:
                                    onAttendancePage &&
                                    attendanceSection == 'leave-promotion',
                                isCompact: isCompact,
                                onTap: () => openAttendance('leave-promotion'),
                              ),
                              _SideMenuItem(
                                icon: Icons.person_off_outlined,
                                label: '퇴사자 연차관리',
                                selected:
                                    onAttendancePage &&
                                    attendanceSection == 'retired-leave',
                                isCompact: isCompact,
                                onTap: () => openAttendance('retired-leave'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (!isPhone) ...[
                Divider(
                  height: 18,
                  color: TheWeColor.black300.withValues(alpha: 0.24),
                ),
                _OrgButton(isCompact: isCompact),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

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
        borderRadius: BorderRadius.circular(16),
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
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'W',
                style: TheWeTextStyle.subtitle.copyWith(color: Colors.white),
              ),
            ),
            if (!isCompact) ...[
              const SizedBox(width: 12),
              Expanded(child: Text('경영업무포털', style: TheWeTextStyle.title)),
            ],
          ],
        ),
        if (!isCompact && currentUser != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FC),
              borderRadius: BorderRadius.circular(14),
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
                      onPressed: () => ref
                          .read(approvalDashboardControllerProvider.notifier)
                          .logout(),
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

      context.goNamed(
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
              borderRadius: BorderRadius.circular(10),
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
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: TheWeTextStyle.makeApproval,
        ),
      ),
    );
  }
}

class _OrgButton extends ConsumerWidget {
  const _OrgButton({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: isCompact
          ? IconButton(
              onPressed: () => _showOrganizationDialog(context),
              icon: const Icon(Icons.account_tree_outlined),
              tooltip: '조직도',
            )
          : OutlinedButton.icon(
              onPressed: () => _showOrganizationDialog(context),
              icon: const Icon(Icons.account_tree_outlined, size: 18),
              label: const Text('조직도'),
            ),
    );
  }

  void _showOrganizationDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const _OrganizationDialog(),
    );
  }
}

class _OrganizationDialog extends ConsumerWidget {
  const _OrganizationDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(approvalDashboardControllerProvider).asData?.value;
    final departments = state?.departments ?? const [];
    final members = state?.selectedDepartmentMembers ?? const [];
    final selectedMember = state?.selectedOrgMember;

    return Dialog(
      backgroundColor: TheWeColor.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: 880,
        height: 620,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('조직도', style: TheWeTextStyle.title),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        itemCount: departments.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final department = departments[index];
                          final selected =
                              department == state?.selectedOrgDepartment;
                          return InkWell(
                            onTap: () => ref
                                .read(
                                  approvalDashboardControllerProvider.notifier,
                                )
                                .setDepartment(department),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: selected
                                    ? TheWeColor.blue100.withValues(alpha: 0.4)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.apartment_outlined,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      department,
                                      style: TheWeTextStyle.body.copyWith(
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('구성원', style: TheWeTextStyle.subtitle),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: members.length,
                                itemBuilder: (context, index) {
                                  final member = members[index];
                                  final selected =
                                      member.id == selectedMember?.id;
                                  return ListTile(
                                    onTap: () => ref
                                        .read(
                                          approvalDashboardControllerProvider
                                              .notifier,
                                        )
                                        .setOrgMember(member.id),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    selected: selected,
                                    selectedTileColor: TheWeColor.blue100
                                        .withValues(alpha: 0.45),
                                    title: Text(
                                      member.name,
                                      style: TheWeTextStyle.body,
                                    ),
                                    subtitle: Text(
                                      '${member.position}  |  ${member.id}',
                                      style: TheWeTextStyle.caption,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 5,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: TheWeColor.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: TheWeColor.black300.withValues(
                                    alpha: 0.22,
                                  ),
                                ),
                              ),
                              child: selectedMember == null
                                  ? Center(
                                      child: Text(
                                        '구성원을 선택해 주세요.',
                                        style: TheWeTextStyle.body,
                                      ),
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundColor: TheWeColor.blue100,
                                          child: Text(
                                            selectedMember
                                                .name
                                                .characters
                                                .first,
                                            style: TheWeTextStyle.title,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          '${selectedMember.name} ${selectedMember.position}',
                                          style: TheWeTextStyle.title,
                                        ),
                                        const SizedBox(height: 12),
                                        _ProfileLine(
                                          label: '부서',
                                          value: selectedMember.department,
                                        ),
                                        _ProfileLine(
                                          label: '아이디',
                                          value: selectedMember.id,
                                        ),
                                        _ProfileLine(
                                          label: '이메일',
                                          value: selectedMember.email,
                                        ),
                                        _ProfileLine(
                                          label: '권한',
                                          value: selectedMember.isAdmin
                                              ? '관리자'
                                              : '일반 직원',
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TheWeTextStyle.caption),
          const SizedBox(height: 4),
          Text(value, style: TheWeTextStyle.body),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({
    required this.title,
    required this.children,
    required this.isCompact,
  });

  final String title;
  final List<Widget> children;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCompact)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              title,
              style: TheWeTextStyle.section.copyWith(
                color: TheWeColor.black500,
              ),
            ),
          ),
        ...children,
      ],
    );
  }
}

class _SideMenuItem extends StatelessWidget {
  const _SideMenuItem({
    required this.icon,
    required this.label,
    required this.isCompact,
    this.count,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isCompact;
  final int? count;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? TheWeColor.blue300 : TheWeColor.black900;
    final isPhone = MediaQuery.sizeOf(context).width < 520;

    return Tooltip(
      message: isCompact ? label : '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: isPhone ? 38 : 42,
          margin: const EdgeInsets.only(bottom: 4),
          padding: EdgeInsets.symmetric(
            horizontal: isPhone ? 8 : (isCompact ? 10 : 12),
          ),
          decoration: BoxDecoration(
            color: selected
                ? TheWeColor.blue100.withValues(alpha: 0.45)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: isCompact
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: foreground),
              if (!isCompact) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TheWeTextStyle.body.copyWith(color: foreground),
                  ),
                ),
                if (count != null)
                  Text(
                    '$count',
                    style: TheWeTextStyle.caption.copyWith(
                      color: selected
                          ? TheWeColor.blue300
                          : TheWeColor.black500,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
