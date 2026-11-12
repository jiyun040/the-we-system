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
          .read(dioProvider)
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
      }
    } on DioException {
    } finally {
      if (mounted) setState(() => saving = false);
    }
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
        ],
      ),
    ),
  );
}
