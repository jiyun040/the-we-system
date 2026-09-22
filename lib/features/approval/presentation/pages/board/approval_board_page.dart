import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_saver/file_saver.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_we_system/common/components/mobile_navigation.dart';
import 'package:the_we_system/common/components/side_bar.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/network/dio_provider.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_attachment.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_document_sheet_attachments.dart';

class ApprovalBoardPage extends ConsumerStatefulWidget {
  const ApprovalBoardPage({super.key});

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
                  DropdownButtonFormField<String>(
                    initialValue: department,
                    decoration: const InputDecoration(labelText: '게시판'),
                    items: ['', ...?state?.departments]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.isEmpty ? '자유게시판' : '$value 게시판'),
                          ),
                        )
                        .toList(),
                    onChanged: saving
                        ? null
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
                  OutlinedButton.icon(
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
    try {
      await ref.read(dioProvider).delete('/board/posts/${post['id']}');
      await _load();
    } catch (_) {
      if (mounted) setState(() => error = '게시글을 삭제하지 못했습니다.');
    }
  }

  Future<void> _openAttachment(ApprovalAttachment attachment) async {
    if (attachment.mimeType == 'application/pdf' ||
        attachment.name.toLowerCase().endsWith('.pdf')) {
      await showApprovalAttachmentPreview(context, attachment);
      return;
    }
    final dot = attachment.name.lastIndexOf('.');
    await FileSaver.instance.saveFile(
      name: dot > 0 ? attachment.name.substring(0, dot) : attachment.name,
      bytes: Uint8List.fromList(attachment.bytes),
      fileExtension: dot > 0 ? attachment.name.substring(dot + 1) : 'bin',
      mimeType: MimeType.custom,
      customMimeType: attachment.mimeType,
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
                      Expanded(child: Text('게시판', style: TheWeTextStyle.title)),
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
                                department.isEmpty ? '자유게시판' : department,
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
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post['title']?.toString() ?? '',
                              style: TheWeTextStyle.subtitle,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${post['authorName'] ?? ''} · ${(post['createdAt']?.toString() ?? '').replaceFirst('T', ' ').split('.').first}',
                              style: TheWeTextStyle.caption,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              post['content']?.toString() ?? '',
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
                                    child: const Text('수정'),
                                  ),
                                  TextButton(
                                    onPressed: () => _delete(post),
                                    child: const Text('삭제'),
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
        ],
      ),
    );
  }
}
