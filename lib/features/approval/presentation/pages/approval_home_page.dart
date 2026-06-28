import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/components/processing_card.dart';
import 'package:the_we_system/common/components/side_bar.dart';
import 'package:the_we_system/common/components/text_form_field.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/domain/entities/approval_document.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_empty_state.dart';

class ApprovalHomePage extends ConsumerStatefulWidget {
  const ApprovalHomePage({super.key});

  @override
  ConsumerState<ApprovalHomePage> createState() => _ApprovalHomePageState();
}

class _ApprovalHomePageState extends ConsumerState<ApprovalHomePage> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController waitingScrollController = ScrollController();

  @override
  void dispose() {
    searchController.dispose();
    waitingScrollController.dispose();
    super.dispose();
  }

  void _scrollWaitingDocuments(double delta) {
    if (!waitingScrollController.hasClients) {
      return;
    }

    final target = (waitingScrollController.offset + delta).clamp(
      0.0,
      waitingScrollController.position.maxScrollExtent,
    );

    waitingScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(approvalDashboardControllerProvider);

    return Scaffold(
      backgroundColor: TheWeColor.white,
      body: state.when(
        data: (approvalState) {
          final dashboard = approvalState.dashboard;
          final keyword = approvalState.keyword.trim();
          final waitingDocuments = _filterDocuments(
            dashboard.waitingDocuments,
            keyword,
          );

          return Row(
            children: [
              SideBar(
                frequentForms: dashboard.frequentForms,
                pendingDocument: dashboard.pendingCount,
                receiveDocument: dashboard.receivedCount,
                openPendingDocument: dashboard.referenceCount,
                scheduledDocument: dashboard.scheduledCount,
              ),
              VerticalDivider(
                width: 1,
                color: TheWeColor.black300.withValues(alpha: 0.32),
              ),
              Expanded(
                child: SafeArea(
                  child: RefreshIndicator(
                    color: TheWeColor.blue300,
                    onRefresh: () => ref
                        .read(approvalDashboardControllerProvider.notifier)
                        .refresh(),
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                          sliver: SliverToBoxAdapter(
                            child: _Header(
                              controller: searchController,
                              onChanged: ref
                                  .read(
                                    approvalDashboardControllerProvider
                                        .notifier,
                                  )
                                  .updateKeyword,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
                          sliver: SliverToBoxAdapter(
                            child: _ProcessingSection(
                              title: '결재 대기 문서',
                              documents: waitingDocuments,
                              controller: waitingScrollController,
                              onScrollLeft: () => _scrollWaitingDocuments(-300),
                              onScrollRight: () => _scrollWaitingDocuments(300),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                          sliver: SliverToBoxAdapter(
                            child: _DraftProgressSection(
                              documents: dashboard.processingDocuments
                                  .take(10)
                                  .toList(),
                              totalCount: dashboard.processingDocuments.length,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        error: (error, stackTrace) => _LoadFailed(
          onRetry: () =>
              ref.read(approvalDashboardControllerProvider.notifier).refresh(),
        ),
        loading: () =>
            Center(child: CircularProgressIndicator(color: TheWeColor.blue300)),
      ),
    );
  }

  List<ApprovalDocument> _filterDocuments(
    List<ApprovalDocument> documents,
    String keyword,
  ) {
    if (keyword.isEmpty) {
      return documents;
    }

    return documents.where((document) {
      return document.title.contains(keyword) ||
          document.drafter.contains(keyword) ||
          document.form.contains(keyword) ||
          document.department.contains(keyword);
    }).toList();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 760;

        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 16,
          children: [
            SizedBox(
              width: narrow ? constraints.maxWidth : 360,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('전자결재 홈', style: TheWeTextStyle.pageTitle),
                  const SizedBox(height: 6),
                  Text(
                    '오늘 처리할 문서와 진행 상황을 한 화면에서 확인하세요.',
                    style: TheWeTextStyle.body.copyWith(
                      color: TheWeColor.black500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: narrow ? constraints.maxWidth : 360,
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextFormField(
                      controller: controller,
                      height: 42,
                      onChanged: onChanged,
                      decoration: InputDecoration(
                        hintText: '문서명, 기안자, 양식 검색',
                        prefixIcon: Icon(
                          Icons.search,
                          color: TheWeColor.black500,
                          size: 18,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _IconAction(
                    icon: Icons.settings_outlined,
                    message: '설정',
                    onPressed: () => context.goNamed(AppRouteName.settings),
                  ),
                  const SizedBox(width: 6),
                  _IconAction(
                    icon: Icons.help_outline,
                    message: '도움말',
                    onPressed: () => context.goNamed(AppRouteName.help),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.message,
    required this.onPressed,
  });

  final IconData icon;
  final String message;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        color: TheWeColor.black900,
      ),
    );
  }
}

class _ProcessingSection extends StatelessWidget {
  const _ProcessingSection({
    required this.title,
    required this.documents,
    required this.controller,
    required this.onScrollLeft,
    required this.onScrollRight,
  });

  final String title;
  final List<ApprovalDocument> documents;
  final ScrollController controller;
  final VoidCallback onScrollLeft;
  final VoidCallback onScrollRight;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title, actionLabel: '0건'),
          const SizedBox(height: 12),
          const ApprovalEmptyState(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title, actionLabel: '${documents.length}건'),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: ListView.separated(
            controller: controller,
            scrollDirection: Axis.horizontal,
            itemCount: documents.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final document = documents[index];
              return ProcessingCard(
                title: document.title,
                drafter: document.drafter,
                date: document.draftedAt,
                form: document.form,
                status: document.status,
                progress: document.progress,
                onTap: () => context.goNamed(
                  AppRouteName.detail,
                  pathParameters: {'id': document.id},
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoundMoveButton(
              icon: Icons.chevron_left,
              tooltip: '이전 결재 대기 문서',
              onPressed: onScrollLeft,
            ),
            const SizedBox(width: 14),
            _RoundMoveButton(
              icon: Icons.chevron_right,
              tooltip: '다음 결재 대기 문서',
              onPressed: onScrollRight,
            ),
          ],
        ),
      ],
    );
  }
}

class _RoundMoveButton extends StatelessWidget {
  const _RoundMoveButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: TheWeColor.black900,
        style: IconButton.styleFrom(
          fixedSize: const Size(38, 38),
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}

class _DraftProgressSection extends StatelessWidget {
  const _DraftProgressSection({
    required this.documents,
    required this.totalCount,
  });

  final List<ApprovalDocument> documents;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('기안 진행 문서', style: TheWeTextStyle.title),
                const SizedBox(width: 6),
                Tooltip(
                  message: '내가 기안했고 아직 완료되지 않은 문서입니다.',
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: TheWeColor.black300,
                  ),
                ),
              ],
            ),
            OutlinedButton(
              onPressed: () => context.goNamed(
                AppRouteName.box,
                pathParameters: {'kind': 'sent'},
              ),
              child: Text('더보기 ($totalCount)', style: TheWeTextStyle.subtitle),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final tableWidth = constraints.maxWidth < 820
                ? 820.0
                : constraints.maxWidth;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: TheWeColor.white,
                    border: Border.all(
                      color: TheWeColor.black300.withValues(alpha: 0.35),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const _DraftProgressHeader(),
                      ...documents.map(
                        (document) => _DraftProgressRow(document: document),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DraftProgressHeader extends StatelessWidget {
  const _DraftProgressHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: TheWeColor.black300.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: const [
          _DraftProgressCell('기안일', flex: 2, header: true),
          _DraftProgressCell('결재양식', flex: 3, header: true),
          _DraftProgressCell('긴급', flex: 1, header: true),
          _DraftProgressCell('제목', flex: 6, header: true),
          _DraftProgressCell('첨부', flex: 1, header: true),
          _DraftProgressCell('결재상태', flex: 2, header: true),
        ],
      ),
    );
  }
}

class _DraftProgressRow extends StatelessWidget {
  const _DraftProgressRow({required this.document});

  final ApprovalDocument document;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.goNamed(
        AppRouteName.detail,
        pathParameters: {'id': document.id},
      ),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: TheWeColor.black300.withValues(alpha: 0.2)),
          ),
        ),
        child: Row(
          children: [
            _DraftProgressCell(document.draftedAt, flex: 2),
            _DraftProgressCell(document.form, flex: 3),
            _DraftProgressCell(document.urgent ? '긴급' : '-', flex: 1),
            Expanded(
              flex: 6,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TheWeTextStyle.body,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.open_in_new, size: 15, color: TheWeColor.black300),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Icon(
                Icons.attach_file,
                size: 16,
                color: document.linkedDocuments.isEmpty
                    ? TheWeColor.black300.withValues(alpha: 0.55)
                    : TheWeColor.black500,
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: TheWeColor.green.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    document.status,
                    style: TheWeTextStyle.caption.copyWith(
                      color: TheWeColor.green,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftProgressCell extends StatelessWidget {
  const _DraftProgressCell(
    this.text, {
    required this.flex,
    this.header = false,
  });

  final String text;
  final int flex;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: (header ? TheWeTextStyle.caption : TheWeTextStyle.body).copyWith(
          color: header ? TheWeColor.black500 : TheWeColor.black900,
          fontWeight: header ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.actionLabel});

  final String title;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: TheWeTextStyle.title),
        const Spacer(),
        Text(
          actionLabel,
          style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
        ),
      ],
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, color: TheWeColor.black500, size: 32),
          const SizedBox(height: 12),
          Text('결재 정보를 불러오지 못했습니다.', style: TheWeTextStyle.subtitle),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
