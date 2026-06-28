import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/domain/entities/approval_form.dart';

class SideBar extends StatelessWidget {
  final List<ApprovalForm> frequentForms;
  final int pendingDocument;
  final int receiveDocument;
  final int openPendingDocument;
  final int scheduledDocument;

  const SideBar({
    super.key,
    required this.frequentForms,
    required this.pendingDocument,
    required this.receiveDocument,
    required this.openPendingDocument,
    required this.scheduledDocument,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 900;
    final isPhone = screenWidth < 520;
    final sideBarWidth = isPhone ? 64.0 : (isCompact ? 88.0 : 276.0);

    return Container(
      width: sideBarWidth,
      color: TheWeColor.white,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isPhone ? 8 : (isCompact ? 12 : 20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Brand(isCompact: isCompact),
              const SizedBox(height: 20),
              _NewApprovalButton(isCompact: isCompact),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            selected: true,
                            isCompact: isCompact,
                            onTap: () => context.goNamed(AppRouteName.home),
                          ),
                          _SideMenuItem(
                            icon: Icons.mark_email_unread_outlined,
                            label: '결재수신문서',
                            count: receiveDocument,
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
                            isCompact: isCompact,
                            onTap: () => context.goNamed(
                              AppRouteName.box,
                              pathParameters: {'kind': 'drafts'},
                            ),
                          ),
                          _SideMenuItem(
                            icon: Icons.drafts_outlined,
                            label: '임시 저장함',
                            isCompact: isCompact,
                            onTap: () => context.goNamed(AppRouteName.draft),
                          ),
                          _SideMenuItem(
                            icon: Icons.archive_outlined,
                            label: '결재 문서함',
                            isCompact: isCompact,
                            onTap: () => context.goNamed(
                              AppRouteName.box,
                              pathParameters: {'kind': 'all'},
                            ),
                          ),
                          _SideMenuItem(
                            icon: Icons.groups_outlined,
                            label: '팀 휴가 결재',
                            isCompact: isCompact,
                            onTap: () => context.goNamed(
                              AppRouteName.formBox,
                              pathParameters: {'formId': 'vacation'},
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).width < 520;

    return Row(
      children: [
        Container(
          width: isPhone ? 32 : 36,
          height: isPhone ? 32 : 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: TheWeColor.blue300,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'W',
            style: TheWeTextStyle.subtitle.copyWith(color: TheWeColor.white),
          ),
        ),
        if (!isCompact) ...[
          const SizedBox(width: 10),
          Text('전자결재', style: TheWeTextStyle.title),
        ],
      ],
    );
  }
}

class _NewApprovalButton extends StatelessWidget {
  const _NewApprovalButton({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return SizedBox(
        width: double.infinity,
        height: 42,
        child: IconButton.filled(
          onPressed: () => context.goNamed(AppRouteName.draft),
          icon: const Icon(Icons.add, size: 18),
          tooltip: '새 결재 진행',
          style: IconButton.styleFrom(
            backgroundColor: TheWeColor.black900,
            foregroundColor: TheWeColor.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 42,
      child: FilledButton.icon(
        onPressed: () => context.goNamed(AppRouteName.draft),
        icon: const Icon(Icons.add, size: 18),
        label: isCompact ? const SizedBox.shrink() : const Text('새 결재 진행'),
        style: FilledButton.styleFrom(
          backgroundColor: TheWeColor.black900,
          foregroundColor: TheWeColor.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: TheWeTextStyle.makeApproval,
        ),
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: isPhone ? 34 : 38,
          margin: const EdgeInsets.only(bottom: 4),
          padding: EdgeInsets.symmetric(
            horizontal: isPhone ? 6 : (isCompact ? 10 : 12),
          ),
          decoration: BoxDecoration(
            color: selected
                ? TheWeColor.blue100.withValues(alpha: 0.45)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
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
