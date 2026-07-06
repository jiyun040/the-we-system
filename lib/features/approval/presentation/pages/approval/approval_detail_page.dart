import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/common/components/the_we_back_button.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_history.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_step.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_dialogs.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_document_sheet.dart';

part 'approval_detail_panels.dart';

class ApprovalDetailPage extends ConsumerWidget {
  const ApprovalDetailPage({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(approvalDocumentProvider(documentId));
    final appState = ref
        .watch(approvalDashboardControllerProvider)
        .asData
        ?.value;

    if (document == null || appState == null) {
      return Scaffold(
        backgroundColor: TheWeColor.white,
        body: SafeArea(
          child: Center(
            child: Text('문서를 찾을 수 없습니다.', style: TheWeTextStyle.subtitle),
          ),
        ),
      );
    }

    final currentUser = appState.currentUser;
    final activeStep = document.steps
        .where((step) => step.status == '진행중')
        .firstOrNull;
    final canApprove =
        currentUser != null &&
        (currentUser.isAdmin || activeStep?.name == currentUser.name);
    final canCancel =
        currentUser != null &&
        (currentUser.isAdmin || document.drafter == currentUser.name) &&
        document.canCancel &&
        !document.steps.skip(1).any((step) => step.status == '완료');
    final canEdit =
        currentUser != null &&
        (currentUser.isAdmin || document.drafter == currentUser.name);

    return Scaffold(
      backgroundColor: TheWeColor.white,
      body: SafeArea(
        child: _DetailContent(
          document: document,
          canApprove: canApprove,
          canCancel: canCancel,
          canEdit: canEdit,
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.document,
    required this.canApprove,
    required this.canCancel,
    required this.canEdit,
  });

  final ApprovalDocument document;
  final bool canApprove;
  final bool canCancel;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DocumentToolbar(
          document: document,
          canApprove: canApprove,
          canCancel: canCancel,
          canEdit: canEdit,
        ),
        Divider(height: 1, color: TheWeColor.black300.withValues(alpha: 0.35)),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 940;
              final sheetBody = Padding(
                padding: EdgeInsets.all(isNarrow ? 16 : 28),
                child: Center(child: ApprovalDocumentSheet(document: document)),
              );
              final rightPanel = Container(
                width: isNarrow ? double.infinity : 330,
                decoration: BoxDecoration(
                  color: TheWeColor.white,
                  border: Border(
                    left: isNarrow
                        ? BorderSide.none
                        : BorderSide(
                            color: TheWeColor.black300.withValues(alpha: 0.35),
                          ),
                    top: isNarrow
                        ? BorderSide(
                            color: TheWeColor.black300.withValues(alpha: 0.35),
                          )
                        : BorderSide.none,
                  ),
                ),
                child: _RightPanel(document: document),
              );

              if (isNarrow) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      sheetBody,
                      SizedBox(
                        height: constraints.maxHeight.clamp(420.0, 560.0),
                        child: rightPanel,
                      ),
                    ],
                  ),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: SingleChildScrollView(child: sheetBody)),
                  SizedBox(height: double.infinity, child: rightPanel),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DocumentToolbar extends ConsumerWidget {
  const _DocumentToolbar({
    required this.document,
    required this.canApprove,
    required this.canCancel,
    required this.canEdit,
  });

  final ApprovalDocument document;
  final bool canApprove;
  final bool canCancel;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compact = MediaQuery.sizeOf(context).width < 640;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 24,
        18,
        compact ? 12 : 24,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TheWeBackButton(),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TheWeTextStyle.pageTitle,
                    children: [
                      TextSpan(text: document.title),
                      TextSpan(
                        text: '  in ${document.form}',
                        style: TheWeTextStyle.caption.copyWith(
                          color: TheWeColor.black500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (canApprove)
                  _ToolbarButton(
                    icon: Icons.edit_note,
                    label: '승인',
                    highlighted: true,
                    onPressed: () => showApprovalDecisionDialog(
                      context,
                      document: document,
                      action: '승인',
                      onConfirm: (opinion) => ref
                          .read(approvalDashboardControllerProvider.notifier)
                          .approveDocument(
                            document.id,
                            action: '승인',
                            opinion: opinion,
                          ),
                    ),
                  ),
                if (canApprove)
                  _ToolbarButton(
                    icon: Icons.keyboard_return,
                    label: '반려',
                    onPressed: () => showApprovalDecisionDialog(
                      context,
                      document: document,
                      action: '반려',
                      onConfirm: (opinion) => ref
                          .read(approvalDashboardControllerProvider.notifier)
                          .approveDocument(
                            document.id,
                            action: '반려',
                            opinion: opinion,
                          ),
                    ),
                  ),
                if (canCancel)
                  _ToolbarButton(
                    icon: Icons.undo,
                    label: '상신취소',
                    onPressed: () async {
                      await ref
                          .read(approvalDashboardControllerProvider.notifier)
                          .cancelSubmission(document.id);
                      if (context.mounted) {
                        context.goNamed(
                          AppRouteName.box,
                          pathParameters: {'kind': 'drafts'},
                        );
                      }
                    },
                  ),
                if (canEdit)
                  _ToolbarButton(
                    icon: Icons.edit_square,
                    label: '문서 수정',
                    onPressed: () => context.goNamed(
                      AppRouteName.draft,
                      queryParameters: {'reuse': document.id},
                    ),
                  ),
                _ToolbarButton(
                  icon: Icons.info_outline,
                  label: '결재 정보',
                  onPressed: () => showApprovalInfoDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
