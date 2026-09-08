import 'approval_document_sheet_dependencies.dart';

class ApprovalDocumentAttachmentArea extends StatelessWidget {
  const ApprovalDocumentAttachmentArea({super.key, required this.files});

  final List<ApprovalAttachment> files;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: TheWeColor.surfaceAlt,
          border: Border.all(color: TheWeColor.black300.withValues(alpha: .4)),
        ),
        child: Text('첨부파일 ${files.length}개', style: TheWeTextStyle.subtitle),
      ),
      ...files.map((attachment) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: TheWeColor.black300.withValues(alpha: .4),
              ),
              right: BorderSide(
                color: TheWeColor.black300.withValues(alpha: .4),
              ),
              bottom: BorderSide(
                color: TheWeColor.black300.withValues(alpha: .4),
              ),
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(
                Icons.picture_as_pdf_outlined,
                color: TheWeColor.danger,
                size: 20,
              ),
              Text(attachment.name, style: TheWeTextStyle.body),
              Text(
                '(${_formatFileSize(attachment.sizeBytes)})',
                style: TheWeTextStyle.caption.copyWith(
                  color: TheWeColor.black500,
                ),
              ),
              OutlinedButton(
                onPressed: () => _showAttachmentPreview(context, attachment),
                child: const Text('미리보기'),
              ),
              OutlinedButton(
                onPressed: () => _downloadAttachment(context, attachment),
                child: const Text('다운로드'),
              ),
            ],
          ),
        );
      }),
      const SizedBox(height: 12),
      TextField(
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: '댓글을 남겨보세요.',
          prefixIcon: const Icon(Icons.account_circle_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ],
  );
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  final kilobytes = bytes / 1024;
  if (kilobytes < 1024) {
    return '${kilobytes.toStringAsFixed(1)}KB';
  }
  return '${(kilobytes / 1024).toStringAsFixed(1)}MB';
}

Future<void> _showAttachmentPreview(
  BuildContext context,
  ApprovalAttachment attachment,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) =>
        _AttachmentPreviewDialog(attachment: attachment),
  );
}

class _AttachmentPreviewDialog extends StatefulWidget {
  const _AttachmentPreviewDialog({required this.attachment});

  final ApprovalAttachment attachment;

  @override
  State<_AttachmentPreviewDialog> createState() =>
      _AttachmentPreviewDialogState();
}

class _AttachmentPreviewDialogState extends State<_AttachmentPreviewDialog> {
  final PdfViewerController _controller = PdfViewerController();

  Future<void> _fitWidth() async {
    if (!_controller.isReady) return;
    await _controller.goTo(
      _controller.calcMatrixFitWidthForPage(
        pageNumber: _controller.pageNumber ?? 1,
      ),
    );
  }

  Future<void> _fitPage() async {
    if (!_controller.isReady) return;
    await _controller.goTo(
      _controller.calcMatrixForFit(pageNumber: _controller.pageNumber ?? 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 760;
    return Dialog(
      insetPadding: EdgeInsets.all(compact ? 8 : 24),
      clipBehavior: Clip.antiAlias,
      backgroundColor: TheWeColor.white,
      surfaceTintColor: TheWeColor.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: compact ? double.infinity : (size.width - 48).clamp(0.0, 1280.0),
        height: compact ? size.height * .94 : size.height * .92,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 12 : 20,
                10,
                compact ? 4 : 10,
                8,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: TheWeColor.danger,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.attachment.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TheWeTextStyle.subtitle,
                    ),
                  ),
                  if (!compact) ...[
                    TextButton.icon(
                      key: const ValueKey('attachment-preview-fit-width'),
                      onPressed: _fitWidth,
                      icon: const Icon(Icons.fit_screen_outlined, size: 18),
                      label: const Text('너비 맞춤'),
                    ),
                    TextButton.icon(
                      key: const ValueKey('attachment-preview-fit-page'),
                      onPressed: _fitPage,
                      icon: const Icon(Icons.fullscreen_outlined, size: 18),
                      label: const Text('한 페이지'),
                    ),
                  ],
                  IconButton(
                    tooltip: '축소',
                    onPressed: _controller.zoomDown,
                    icon: const Icon(Icons.zoom_out),
                  ),
                  IconButton(
                    tooltip: '확대',
                    onPressed: _controller.zoomUp,
                    icon: const Icon(Icons.zoom_in),
                  ),
                  IconButton(
                    tooltip: '닫기',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: TheWeColor.black300.withValues(alpha: .5),
            ),
            Expanded(
              child: ColoredBox(
                color: TheWeColor.background,
                child: PdfViewer.data(
                  widget.attachment.bytes,
                  sourceName:
                      '${widget.attachment.name}-${widget.attachment.base64Data.hashCode}',
                  controller: _controller,
                  params: PdfViewerParams(
                    margin: compact ? 8 : 20,
                    backgroundColor: TheWeColor.background,
                    pageAnchor: PdfPageAnchor.topCenter,
                    underflowAnchor: PdfPageAnchor.topCenter,
                    panAxis: PanAxis.free,
                    scrollByMouseWheel: .65,
                    interactionDelegateProvider:
                        const PdfViewerScrollInteractionDelegateProviderPhysics(
                          panFriction: 16,
                        ),
                    onViewerReady: (document, controller) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted || !controller.isReady) return;
                        controller.goTo(
                          controller.calcMatrixFitWidthForPage(pageNumber: 1),
                          duration: Duration.zero,
                        );
                      });
                    },
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

Future<void> _downloadAttachment(
  BuildContext context,
  ApprovalAttachment attachment,
) async {
  final dotIndex = attachment.name.lastIndexOf('.');
  final hasExtension = dotIndex > 0 && dotIndex < attachment.name.length - 1;
  final name = hasExtension
      ? attachment.name.substring(0, dotIndex)
      : attachment.name;
  final extension = hasExtension
      ? attachment.name.substring(dotIndex + 1)
      : 'pdf';

  try {
    await FileSaver.instance.saveFile(
      name: name,
      bytes: attachment.bytes,
      fileExtension: extension,
      mimeType: attachment.mimeType == 'application/pdf'
          ? MimeType.pdf
          : MimeType.custom,
      customMimeType: attachment.mimeType,
    );
    if (!context.mounted) {
      return;
    }
    showTheWeSnackBar(context, message: '${attachment.name} 파일을 저장했습니다.');
  } catch (_) {
    if (!context.mounted) {
      return;
    }
    showTheWeSnackBar(
      context,
      message: '파일을 저장하지 못했습니다. 다시 시도해 주세요.',
      type: TheWeSnackBarType.error,
    );
  }
}
