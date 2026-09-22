import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_saver/file_saver.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_we_system/common/components/mobile_navigation.dart';
import 'package:the_we_system/common/components/side_bar.dart';
import 'package:the_we_system/common/components/the_we_dropdown.dart';
import 'package:the_we_system/common/components/the_we_modal.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/network/dio_provider.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_attachment.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_document_sheet_attachments.dart';
import 'package:desktop_drop/desktop_drop.dart';

class ApprovalBoardPage extends ConsumerStatefulWidget {
  const ApprovalBoardPage({super.key, this.initialDepartment});
  final String? initialDepartment;

  @override
  ConsumerState<ApprovalBoardPage> createState() => _ApprovalBoardPageState();
}

class _ApprovalBoardPageState extends ConsumerState<ApprovalBoardPage> {
  List<Map<String, dynamic>> posts = [];
  String selectedDepartment = '';
  String? error;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    selectedDepartment = widget.initialDepartment ?? '';
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await ref
          .read(dioProvider)
          .get<Map<String, dynamic>>('/board/posts');
      if (!mounted) return;
      setState(() {
        posts = (response.data?['posts'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
        loading = false;
        error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error = '게시글을 불러오지 못했습니다.';
        });
      }
    }
  }

  Future<void> _edit([Map<String, dynamic>? post]) async {
    final state = ref.read(approvalDashboardControllerProvider).asData?.value;
    final title = TextEditingController(text: post?['title']?.toString() ?? '');
    final content = TextEditingController(
      text: post?['content']?.toString() ?? '',
    );
    var department = post?['department']?.toString() ?? selectedDepartment;
    var files = (post?['attachments'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              ApprovalAttachment.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    var message = '';
    var saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          backgroundColor: TheWeColor.surfaceAlt,
          title: Text(post == null ? '게시글 작성' : '게시글 수정'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TheWeDropdown<String>(
                    value: department,
                    items: ['', ...?state?.departments],
                    labelText: '게시판',
                    labelBuilder: (value) =>
                        value.isEmpty ? '전체게시판' : '$value 게시판',
                    onChanged: saving
                        ? (_) {}
                        : (value) => update(() => department = value ?? ''),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: title,
                    maxLength: 200,
                    decoration: const InputDecoration(labelText: '제목'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: content,
                    minLines: 5,
                    maxLines: 12,
                    decoration: const InputDecoration(labelText: '내용'),
                  ),
                  const SizedBox(height: 12),
                  DropTarget(
                    onDragDone: (details) async {
                      for (final file in details.files) {
                        if (files.length >= 5) break;
                        final bytes = await file.readAsBytes();
                        if (bytes.isNotEmpty &&
                            bytes.length <= 10 * 1024 * 1024) {
                          files.add(
                            ApprovalAttachment.fromBytes(
                              name: file.name,
                              mimeType:
                                  file.mimeType ?? 'application/octet-stream',
                              bytes: bytes,
                            ),
                          );
                        }
                      }
                      update(() {});
                    },
                    child: OutlinedButton.icon(
                      onPressed: saving || files.length >= 5
                          ? null
                          : () async {
                              final picked = await openFiles();
                              for (final file in picked) {
                                final bytes = await file.readAsBytes();
                                if (bytes.isEmpty ||
                                    bytes.length > 10 * 1024 * 1024) {
                                  update(
                                    () => message = '파일은 각 10MB 이하로 첨부해 주세요.',
                                  );
                                  continue;
                                }
                                if (files.length >= 5) break;
                                files.add(
                                  ApprovalAttachment.fromBytes(
                                    name: file.name,
                                    mimeType:
                                        file.mimeType ??
                                        'application/octet-stream',
                                    bytes: bytes,
                                  ),
                                );
                              }
                              update(() {});
                            },
                      icon: const Icon(Icons.attach_file),
                      label: const Text('자료 첨부 (최대 5개)'),
                    ),
                  ),
                  Text('파일을 이 영역에 끌어 놓아도 됩니다.', style: TheWeTextStyle.caption),
                  for (final file in files)
                    InputChip(
                      label: Text(file.name),
                      onDeleted: saving
                          ? null
                          : () => update(() => files.remove(file)),
                    ),
                  if (message.isNotEmpty)
                    Text(
                      message,
                      style: TheWeTextStyle.caption.copyWith(
                        color: TheWeColor.danger,
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (title.text.trim().isEmpty ||
                          content.text.trim().isEmpty) {
                        update(() => message = '제목과 내용을 입력해 주세요.');
                        return;
                      }
                      update(() {
                        saving = true;
                        message = '';
                      });
                      try {
                        final data = {
                          'title': title.text.trim(),
                          'content': content.text.trim(),
                          'department': department,
                          'attachments': files
                              .map((file) => file.toJson())
                              .toList(),
                        };
                        if (post == null) {
                          await ref
                              .read(dioProvider)
                              .post('/board/posts', data: data);
                        } else {
                          await ref
                              .read(dioProvider)
                              .patch('/board/posts/${post['id']}', data: data);
                        }
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        await _load();
                      } on DioException catch (cause) {
                        update(() {
                          saving = false;
                          message =
                              cause.response?.data?.toString() ??
                              '게시글을 저장하지 못했습니다.';
                        });
                      }
                    },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    content.dispose();
  }

  Future<void> _delete(Map<String, dynamic> post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => TheWeConfirmDialog(
        title: '게시글을 삭제할까요?',
        message: '삭제한 게시글은 복구할 수 없습니다.',
        primaryLabel: '삭제',
        secondaryLabel: '취소',
        primaryColor: TheWeColor.danger,
        onPrimaryPressed: () => Navigator.of(context).pop(true),
        onSecondaryPressed: () => Navigator.of(context).pop(false),
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(dioProvider).delete('/board/posts/${post['id']}');
      await _load();
    } catch (_) {
      if (mounted) setState(() => error = '게시글을 삭제하지 못했습니다.');
    }
  }

  Future<void> _openAttachment(ApprovalAttachment attachment) async {
    await showApprovalAttachmentPreview(context, attachment);
  }

  Future<void> _downloadAttachment(ApprovalAttachment attachment) async {
    final dot = attachment.name.lastIndexOf('.');
    await FileSaver.instance.saveFile(
      name: dot > 0 ? attachment.name.substring(0, dot) : attachment.name,
      bytes: Uint8List.fromList(attachment.bytes),
      fileExtension: dot > 0 ? attachment.name.substring(dot + 1) : 'bin',
      mimeType: MimeType.custom,
      customMimeType: attachment.mimeType,
    );
  }

  Future<void> _openPostDetail(Map<String, dynamic> post) async {
    final attachments = (post['attachments'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              ApprovalAttachment.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => TheWeModalSurface(
        maxWidth: 720,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TheWeModalHeader(
                title: post['title']?.toString() ?? '',
                onClose: () => Navigator.pop(dialogContext),
              ),
              Text(
                '${post['authorName'] ?? ''} · ${_formatCreatedAt(post['createdAt'])}',
                style: TheWeTextStyle.caption,
              ),
              const SizedBox(height: 18),
              SelectableText(
                post['content']?.toString() ?? '',
                style: TheWeTextStyle.body,
              ),
              if (attachments.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('첨부파일', style: TheWeTextStyle.subtitle),
                for (final attachment in attachments)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.attach_file),
                    title: Text(
                      attachment.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _openAttachment(attachment),
                    trailing: IconButton(
                      tooltip: '다운로드',
                      icon: const Icon(Icons.download_outlined),
                      onPressed: () => _downloadAttachment(attachment),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(approvalDashboardControllerProvider).asData?.value;
    final visible = posts
        .where(
          (post) =>
              (post['department']?.toString() ?? '') == selectedDepartment,
        )
        .toList();
    final mobile = MediaQuery.sizeOf(context).width < 700;
    return Scaffold(
      backgroundColor: TheWeColor.white,
      appBar: mobile ? const MobileNavigationAppBar() : null,
      drawer: mobile ? const MobileNavigationDrawer() : null,
      body: Row(
        children: [
          if (!mobile && state != null)
            SideBar(
              frequentForms: state.dashboard.frequentForms,
              pendingDocument: state.dashboard.pendingCount,
              receiveDocument: state.dashboard.receivedCount,
              openPendingDocument: state.dashboard.referenceCount,
              scheduledDocument: state.dashboard.scheduledCount,
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('자료공유', style: TheWeTextStyle.title),
                      ),
                      FilledButton.icon(
                        onPressed: () => _edit(),
                        icon: const Icon(Icons.edit),
                        label: const Text('글쓰기'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final department in ['', ...?state?.departments])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                department.isEmpty ? '전체게시판' : department,
                              ),
                              selected: selectedDepartment == department,
                              onSelected: (_) => setState(
                                () => selectedDepartment = department,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        error!,
                        style: TheWeTextStyle.body.copyWith(
                          color: TheWeColor.danger,
                        ),
                      ),
                    ),
                  if (loading) const Center(child: CircularProgressIndicator()),
                  if (!loading && visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('등록된 게시글이 없습니다.')),
                    ),
                  for (final post in visible)
                    Card(
                      color: TheWeColor.surfaceAlt,
                      child: InkWell(
                        onTap: () => _openPostDetail(post),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post['title']?.toString() ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TheWeTextStyle.subtitle,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${post['authorName'] ?? ''} · ${_formatCreatedAt(post['createdAt'])}',
                                style: TheWeTextStyle.caption,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                post['content']?.toString() ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TheWeTextStyle.body,
                              ),
                              const SizedBox(height: 8),
                              for (final raw
                                  in (post['attachments'] as List<dynamic>? ??
                                      const []))
                                if (raw is Map)
                                  TextButton.icon(
                                    onPressed: () => _openAttachment(
                                      ApprovalAttachment.fromJson(
                                        Map<String, dynamic>.from(raw),
                                      ),
                                    ),
                                    icon: const Icon(Icons.attach_file),
                                    label: Text(
                                      raw['name']?.toString() ?? '첨부파일',
                                    ),
                                  ),
                              if (post['authorId'] == state?.currentUser?.id ||
                                  state?.currentUser?.isAdmin == true)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => _edit(post),
                                      style: TextButton.styleFrom(
                                        foregroundColor: TheWeColor.blue300,
                                      ),
                                      child: const Text('수정'),
                                    ),
                                    TextButton(
                                      onPressed: () => _delete(post),
                                      style: TextButton.styleFrom(
                                        foregroundColor: TheWeColor.danger,
                                      ),
                                      child: const Text('삭제'),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCreatedAt(Object? raw) {
  final parsed = DateTime.tryParse(raw?.toString() ?? '');
  if (parsed == null) return raw?.toString() ?? '';
  final value = parsed.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}.${two(value.month)}.${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}';
}
