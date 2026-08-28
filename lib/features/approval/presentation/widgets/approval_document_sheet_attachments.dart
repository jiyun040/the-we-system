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
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final compact = size.width < 520;
      return Dialog(
        insetPadding: EdgeInsets.all(compact ? 10 : 28),
        backgroundColor: TheWeColor.white,
        surfaceTintColor: TheWeColor.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: compact ? size.width : 1000,
          height: compact ? size.height * .88 : size.height * .9,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 14 : 22,
                  12,
                  compact ? 8 : 14,
                  10,
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
                        attachment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TheWeTextStyle.subtitle,
                      ),
                    ),
                    IconButton(
                      tooltip: '닫기',
                      onPressed: () => Navigator.of(dialogContext).pop(),
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
                    attachment.bytes,
                    sourceName:
                        '${attachment.name}-${attachment.base64Data.hashCode}',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
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
