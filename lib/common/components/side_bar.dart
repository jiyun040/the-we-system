import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/components/the_we_modal.dart';
import 'package:the_we_system/common/components/the_we_logo.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/layout.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/domain/entities/form/approval_form.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_dialogs.dart';

part 'side_bar_sections.dart';
part 'side_bar_org.dart';
part 'side_bar_menu.dart';

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
    final approvalEnabled = state?.isAppEnabled(PortalAppId.approval) ?? true;
    final attendanceEnabled =
        state?.isAppEnabled(PortalAppId.attendance) ?? true;
    final leaveEnabled = state?.isAppEnabled(PortalAppId.leave) ?? true;
    final currentPath = GoRouterState.of(context).uri.path;
    final onHomePage = currentPath == AppRoutePath.home;
    final attendanceSection =
        GoRouterState.of(context).uri.queryParameters['section'] ?? 'my-status';
    final attendanceView =
        GoRouterState.of(context).uri.queryParameters['view'] ?? 'weekly';
    final onAttendancePage = currentPath == AppRoutePath.absence;
    final onLeavePage = currentPath == AppRoutePath.leave;
    final onReceivedPage = currentPath.contains('/approval/box/received');
    final onDraftPage = currentPath.contains('/approval/box/drafts');
    final onTemporaryPage = currentPath == AppRoutePath.temporaryBox;
    final onArchivePage = currentPath.contains('/approval/box/all');
    final onWaitingPage = currentPath.contains('/approval/box/waiting');
    final onReferencePage = currentPath.contains('/approval/box/reference');
    final onScheduledPage = currentPath.contains('/approval/box/scheduled');

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
              TheWeGaps.verticalXxl,
              if (approvalEnabled) ...[
                _NewApprovalButton(isCompact: isCompact),
                TheWeGaps.verticalXxl,
              ],
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
                      TheWeGaps.verticalSm,
                      if (approvalEnabled) ...[
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
                            TheWeGaps.verticalXxl,
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
                                      onWaitingPage,
                                  isCompact: isCompact,
                                  onTap: () => context.goNamed(
                                    AppRouteName.box,
                                    pathParameters: {'kind': 'waiting'},
                                  ),
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
                                  selected: onReferencePage,
                                  isCompact: isCompact,
                                  onTap: () => context.goNamed(
                                    AppRouteName.box,
                                    pathParameters: {'kind': 'reference'},
                                  ),
                                ),
                                _SideMenuItem(
                                  icon: Icons.event_available_outlined,
                                  label: '결재예정문서',
                                  count: scheduledDocument,
                                  selected: onScheduledPage,
                                  isCompact: isCompact,
                                  onTap: () => context.goNamed(
                                    AppRouteName.box,
                                    pathParameters: {'kind': 'scheduled'},
                                  ),
                                ),
                              ],
                            ),
                            TheWeGaps.verticalXxl,
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
                                  selected: onTemporaryPage,
                                  isCompact: isCompact,
                                  onTap: () => context.goNamed(
                                    AppRouteName.temporaryBox,
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
                            TheWeGaps.verticalXxl,
                            _MenuSection(
                              title: '부서 문서함',
                              isCompact: isCompact,
                              children: [
                                _SideMenuItem(
                                  icon: Icons.folder_shared_outlined,
                                  label: currentUser == null
                                      ? '부서 문서함'
                                      : '${currentUser.department} 문서함',
                                  selected: currentPath.contains(
                                    '/approval/box/department',
                                  ),
                                  isCompact: isCompact,
                                  onTap: () => context.goNamed(
                                    AppRouteName.box,
                                    pathParameters: {'kind': 'department'},
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        TheWeGaps.verticalXxl,
                      ],
                      if (attendanceEnabled) ...[
                        _SideMenuItem(
                          icon: Icons.schedule_outlined,
                          label: '근태 현황',
                          selected: onAttendancePage,
                          isCompact: isCompact,
                          onTap: () => openAttendance('my-status'),
                        ),
                        TheWeGaps.verticalXxl,
                      ],
                      if (leaveEnabled)
                        _SideMenuItem(
                          icon: Icons.beach_access_outlined,
                          label: '휴가 현황/신청',
                          selected: onLeavePage,
                          isCompact: isCompact,
                          onTap: () => context.goNamed(AppRouteName.leave),
                        ),
                      if (state?.isAdminMode == true && attendanceEnabled) ...[
                        TheWeGaps.verticalXxl,
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
                                      attendanceSection ==
                                          'holiday-replacement',
                                  isCompact: isCompact,
                                  onTap: () =>
                                      openAttendance('holiday-replacement'),
                                ),
                              ],
                            ),
                            TheWeGaps.verticalXxl,
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
                                  onTap: () =>
                                      openAttendance('leave-promotion'),
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
