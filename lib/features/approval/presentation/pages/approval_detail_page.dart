import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/components/the_we_back_button.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/domain/entities/approval_document.dart';
import 'package:the_we_system/features/approval/domain/entities/approval_history.dart';
import 'package:the_we_system/features/approval/domain/entities/approval_step.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_dialogs.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_document_sheet.dart';

class ApprovalDetailPage extends ConsumerWidget {
  const ApprovalDetailPage({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(approvalDocumentProvider(documentId));

    return Scaffold(
      backgroundColor: TheWeColor.white,
      body: SafeArea(
        child: document.when(
          data: (value) => _DetailContent(document: value),
          error: (error, stackTrace) => Center(
            child: Text('문서를 찾을 수 없습니다.', style: TheWeTextStyle.subtitle),
          ),
          loading: () => Center(
            child: CircularProgressIndicator(color: TheWeColor.blue300),
          ),
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.document});

  final ApprovalDocument document;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DocumentToolbar(document: document),
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

class _DocumentToolbar extends StatelessWidget {
  const _DocumentToolbar({required this.document});

  final ApprovalDocument document;

  @override
  Widget build(BuildContext context) {
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
                _ToolbarButton(
                  icon: Icons.edit_note,
                  label: '결재',
                  highlighted: true,
                  onPressed: () => showApprovalDecisionDialog(
                    context,
                    document: document,
                    action: '승인',
                  ),
                ),
                _ToolbarButton(
                  icon: Icons.keyboard_return,
                  label: '반려',
                  onPressed: () => showApprovalDecisionDialog(
                    context,
                    document: document,
                    action: '반려',
                  ),
                ),
                _ToolbarButton(
                  icon: Icons.schedule,
                  label: '보류',
                  onPressed: () {},
                ),
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
                _ToolbarButton(
                  icon: Icons.mail_outline,
                  label: '메일발송',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return highlighted
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: FilledButton.styleFrom(
              backgroundColor: TheWeColor.blue100.withValues(alpha: 0.75),
              foregroundColor: TheWeColor.black900,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )
        : TextButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: TextButton.styleFrom(foregroundColor: TheWeColor.black900),
          );
  }
}

class _RightPanel extends StatelessWidget {
  const _RightPanel({required this.document});

  final ApprovalDocument document;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            labelColor: TheWeColor.black900,
            indicatorColor: TheWeColor.black900,
            tabs: const [
              Tab(text: '결재선'),
              Tab(text: '문서정보'),
              Tab(text: '변경이력'),
              Tab(text: '열람'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ApprovalLineTab(steps: document.steps),
                _DocumentInfoTab(document: document),
                _HistoryTab(histories: document.histories),
                _ViewerTab(document: document),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalLineTab extends StatelessWidget {
  const _ApprovalLineTab({required this.steps});

  final List<ApprovalStep> steps;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: steps.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final step = steps[index];
        final active = step.status == '진행중';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active
                ? TheWeColor.blue100.withValues(alpha: 0.4)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: active ? TheWeColor.blue300 : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: TheWeColor.black300.withValues(alpha: 0.18),
                child: Icon(Icons.person, color: TheWeColor.black500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${step.name} ${step.role}',
                      style: TheWeTextStyle.body,
                    ),
                    Text(step.department, style: TheWeTextStyle.caption),
                    if (step.delegatedBy != null)
                      Text(
                        '대결자 승인 후 원결재자(${step.delegatedBy}) 재승인 필요',
                        style: TheWeTextStyle.caption.copyWith(
                          color: TheWeColor.pink,
                        ),
                      ),
                  ],
                ),
              ),
              Text(step.status, style: TheWeTextStyle.caption),
            ],
          ),
        );
      },
    );
  }
}

class _DocumentInfoTab extends StatelessWidget {
  const _DocumentInfoTab({required this.document});

  final ApprovalDocument document;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoLine(label: '문서번호', value: document.documentNo),
        _InfoLine(label: '기안자', value: document.drafter),
        _InfoLine(label: '기안부서', value: document.department),
        _InfoLine(label: '수신자', value: document.receivers.join(', ')),
        _InfoLine(label: '참조자', value: document.references.join(', ')),
        _InfoLine(label: '열람자', value: document.viewers.join(', ')),
        _InfoLine(label: '공문서 수신처', value: document.publicReceivers.join(', ')),
        _InfoLine(label: '긴급문서', value: document.urgent ? '예' : '아니오'),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.histories});

  final List<ApprovalHistory> histories;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('결재선 변경', style: TheWeTextStyle.subtitle),
        const SizedBox(height: 8),
        ...histories
            .where((history) => history.category.contains('결재선'))
            .map((history) => _HistoryTile(history: history)),
        const SizedBox(height: 20),
        Text('결재문서 변경', style: TheWeTextStyle.subtitle),
        const SizedBox(height: 8),
        ...histories
            .where((history) => history.category.contains('문서'))
            .map((history) => _HistoryTile(history: history)),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.history});

  final ApprovalHistory history;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: TheWeColor.black300.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(history.date, style: TheWeTextStyle.caption),
                Text(history.user, style: TheWeTextStyle.body),
                Text(
                  history.description,
                  style: TheWeTextStyle.caption.copyWith(
                    color: TheWeColor.black500,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(history.category),
                content: Text(history.snapshot, style: TheWeTextStyle.body),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('닫기'),
                  ),
                ],
              ),
            ),
            child: const Text('보기'),
          ),
        ],
      ),
    );
  }
}

class _ViewerTab extends StatelessWidget {
  const _ViewerTab({required this.document});

  final ApprovalDocument document;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('참조자는 결재 중에도 열람 가능', style: TheWeTextStyle.subtitle),
        const SizedBox(height: 8),
        ...document.references.map((name) => _SimplePerson(name: name)),
        const SizedBox(height: 18),
        Text('열람자는 결재 완료 후 열람 가능', style: TheWeTextStyle.subtitle),
        const SizedBox(height: 8),
        ...document.viewers.map((name) => _SimplePerson(name: name)),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

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
          const SizedBox(height: 3),
          Text(value.isEmpty ? '-' : value, style: TheWeTextStyle.body),
        ],
      ),
    );
  }
}

class _SimplePerson extends StatelessWidget {
  const _SimplePerson({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.person_outline),
      title: Text(name, style: TheWeTextStyle.body),
    );
  }
}
