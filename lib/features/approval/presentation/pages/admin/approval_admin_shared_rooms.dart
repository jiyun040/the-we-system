import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:the_we_system/common/components/the_we_dropdown.dart';
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
  String? department;
  String? user;
  bool saving = false;
  List<Map<String, dynamic>> rooms = [];
  @override void initState() { super.initState(); _loadRooms(); }
  Future<void> _loadRooms() async {
    try {
      final response = await ref.read<Dio>(dioProvider).get<Map<String, dynamic>>('/board/rooms');
      if (mounted) setState(() => rooms = (response.data?['rooms'] as List<dynamic>? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList());
    } catch (_) {}
  }
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> create() async {
    if (name.text.trim().isEmpty || (department == null && user == null))
      return;
    setState(() => saving = true);
    try {
      await ref
          .read<Dio>(dioProvider)
          .post(
            '/board/rooms',
            data: {
              'name': name.text.trim(),
              if (department != null) 'department': department,
              if (user != null) 'userIds': [user],
            },
          );
      if (mounted) {
        name.clear();
        setState(() {
          department = null;
          user = null;
        });
        await _loadRooms();
      }
    } on DioException {
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _editRoom(Map<String, dynamic> room) async {
    final controller = TextEditingController(text: room['name']?.toString() ?? '');
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('자료공유 방 수정'),
      content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: '방 이름')),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('저장'))],
    ));
    if (confirmed != true || controller.text.trim().isEmpty) return;
    await ref.read<Dio>(dioProvider).patch('/board/rooms/${room['id']}', data: {'name': controller.text.trim()});
    await _loadRooms();
  }

  Future<void> _deleteRoom(Map<String, dynamic> room) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('자료공유 방 삭제'), content: Text('“${room['name']}” 방을 삭제하시겠습니까?'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제'))],
    ));
    if (confirmed != true) return;
    await ref.read<Dio>(dioProvider).delete('/board/rooms/${room['id']}');
    await _loadRooms();
  }

  @override
  Widget build(BuildContext context) => Card(
    color: TheWeColor.white,
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('자료공유 방 생성', style: TheWeTextStyle.title),
          const SizedBox(height: 8),
          Text(
            '부서 전체 또는 특정 직원을 선택해 자료공유 방을 만듭니다.',
            style: TheWeTextStyle.caption,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: '방 이름'),
          ),
          const SizedBox(height: 14),
          TheWeDropdown<String>(
            value: department,
            items: widget.state.departments,
            labelBuilder: (v) => '부서 · $v',
            hintText: '부서 선택',
            onChanged: (v) => setState(() {
              department = v;
              user = null;
            }),
          ),
          const SizedBox(height: 12),
          TheWeDropdown<String>(
            value: user,
            items: widget.state.accounts.map((e) => e.id).toList(),
            labelBuilder: (id) =>
                widget.state.accounts.firstWhere((e) => e.id == id).name,
            hintText: '직원 선택',
            onChanged: (v) => setState(() {
              user = v;
              department = null;
            }),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: saving ? null : create,
            icon: const Icon(Icons.add),
            label: const Text('방 생성'),
          ),
          const SizedBox(height: 28),
          Text('생성된 자료공유 방', style: TheWeTextStyle.subtitle),
          const SizedBox(height: 8),
          for (final room in rooms)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.folder_shared_outlined),
              title: Text(room['name']?.toString() ?? ''),
              trailing: Wrap(spacing: 4, children: [
                IconButton(tooltip: '수정', onPressed: () => _editRoom(room), icon: const Icon(Icons.edit_outlined)),
                IconButton(tooltip: '삭제', onPressed: () => _deleteRoom(room), icon: const Icon(Icons.delete_outline)),
              ]),
            ),
        ],
      ),
    ),
  );
}
