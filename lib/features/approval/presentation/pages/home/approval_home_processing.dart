import 'approval_home_dependencies.dart';

class ApprovalHomeIconAction extends StatelessWidget {
  const ApprovalHomeIconAction({
    super.key,
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

class ApprovalProcessingSection extends StatelessWidget {
  const ApprovalProcessingSection({
    super.key,
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
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 520) {
              return Column(
                children: documents
                    .take(3)
                    .map(
                      (document) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ApprovalMobileDocumentCard(
                          document: document,
                          onTap: () => context.pushNamed(
                            AppRouteName.detail,
                            pathParameters: {'id': document.id},
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            }

            return Column(
              children: [
                SizedBox(
                  height: 296,
                  child: ListView.separated(
                    controller: controller,
                    scrollDirection: Axis.horizontal,
                    itemCount: documents.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final document = documents[index];
                      return ProcessingCard(
                        title: document.title,
                        drafter: document.drafter,
                        date: document.draftedAt,
                        form: document.form,
                        status: document.status,
                        progress: document.progress,
                        onTap: () => context.pushNamed(
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
          },
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

class ApprovalDraftProgressSection extends StatelessWidget {
  const ApprovalDraftProgressSection({
    super.key,
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
            if (constraints.maxWidth < 520) {
              return Column(
                children: documents
                    .take(4)
                    .map(
                      (document) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ApprovalMobileDocumentCard(
                          document: document,
                          onTap: () => context.pushNamed(
                            AppRouteName.detail,
                            pathParameters: {'id': document.id},
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            }

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
      onTap: () => context.pushNamed(
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

class ApprovalHomeLoadFailed extends StatelessWidget {
  const ApprovalHomeLoadFailed({super.key, required this.onRetry});

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
