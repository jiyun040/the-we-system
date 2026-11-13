import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/network/dio_provider.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';

class AdminSharedRooms extends ConsumerStatefulWidget {
  const AdminSharedRooms({super.key, required this.state});
  final ApprovalDashboardState state;
  @override
  ConsumerState<AdminSharedRooms> createState() => _AdminSharedRoomsState();
}

class _AdminSharedRoomsState extends ConsumerState<AdminSharedRooms> {
  final name = TextEditingController();
  final departments = <String>{};
  final users = <String>{};
  bool saving = false;
  List<Map<String, dynamic>> rooms = [];
  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final response = await ref
          .read<Dio>(dioProvider)
          .get<Map<String, dynamic>>('/board/rooms');
      if (mounted)
        setState(
          () => rooms = (response.data?['rooms'] as List<dynamic>? ?? const [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
        );
    } catch (_) {}
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> create() async {
    if (name.text.trim().isEmpty || (departments.isEmpty && users.isEmpty))
      return;
    setState(() => saving = true);
    try {
      await ref
          .read<Dio>(dioProvider)
          .post(
            '/board/rooms',
            data: {
              'name': name.text.trim(),
              'departments': departments.toList(),
              'userIds': users.toList(),
            },
          );
      if (mounted) {
        name.clear();
        setState(() {
          departments.clear();
          users.clear();
        });
        await _loadRooms();
      }
    } on DioException {
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _editRoom(Map<String, dynamic> room) async {
    final controller = TextEditingController(
      text: room['name']?.toString() ?? '',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('자료공유 방 수정'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '방 이름'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (confirmed != true || controller.text.trim().isEmpty) return;
    await ref
        .read<Dio>(dioProvider)
        .patch(
          '/board/rooms/${room['id']}',
          data: {'name': controller.text.trim()},
        );
    await _loadRooms();
  }

  Future<void> _deleteRoom(Map<String, dynamic> room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('자료공유 방 삭제'),
        content: Text('“${room['name']}” 방을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read<Dio>(dioProvider).delete('/board/rooms/${room['id']}');
    await _loadRooms();
  }

  Future<void> _openCreateDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('자료공유 방 생성'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: '방 이름'),
                ),
                const SizedBox(height: 16),
                Text('부서 선택', style: TheWeTextStyle.caption),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final item in widget.state.departments)
                      FilterChip(
                        label: Text(item),
                        selected: departments.contains(item),
                        onSelected: (_) => setState(
                          () => departments.contains(item)
                              ? departments.remove(item)
                              : departments.add(item),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('직원 선택', style: TheWeTextStyle.caption),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final account in widget.state.accounts)
                      FilterChip(
                        label: Text(account.name),
                        selected: users.contains(account.id),
                        onSelected: (_) => setState(
                          () => users.contains(account.id)
                              ? users.remove(account.id)
                              : users.add(account.id),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              await create();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('방 생성'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text('생성된 자료공유 방', style: TheWeTextStyle.title)),
          FilledButton.icon(
            onPressed: _openCreateDialog,
            icon: const Icon(Icons.add),
            label: const Text('방 생성'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      for (final room in rooms)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: TheWeColor.black300.withValues(alpha: .35),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: const Icon(Icons.folder_shared_outlined),
              title: Text(room['name']?.toString() ?? ''),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: '수정',
                    onPressed: () => _editRoom(room),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: '삭제',
                    onPressed: () => _deleteRoom(room),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}
