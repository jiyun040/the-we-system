import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/common/components/the_we_modal.dart';
import 'package:the_we_system/core/network/dio_provider.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';

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
  bool permissionMode = false;
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
          .get<Map<String, dynamic>>('/board/rooms', queryParameters: {'includeDepartments': true});
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
    final selectedUsers = <String>{
      for (final member in (room['members'] as List<dynamic>? ?? const []))
        if (member is Map && member['id'] != null) member['id'].toString(),
    };
    final selectedDepartments = <String>{
      for (final member in (room['members'] as List<dynamic>? ?? const []))
        if (member is Map && (member['department']?.toString() ?? '').isNotEmpty)
          member['department'].toString(),
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => TheWeModalSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TheWeModalHeader(
              title: '자료공유 방 수정',
              onClose: () => Navigator.pop(context, false),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: '방 이름'),
            ),
            const SizedBox(height: 14),
            Align(alignment: Alignment.centerLeft, child: Text('멤버 수정', style: TheWeTextStyle.caption)),
            StatefulBuilder(builder: (context, setModalState) => Wrap(
              spacing: 10,
              runSpacing: 14,
              children: [
                for (final department in widget.state.departments)
                  FilterChip(
                    label: Text('$department 전체'),
                    selected: selectedDepartments.contains(department),
                    onSelected: (_) => setModalState(() {
                      selectedDepartments.contains(department)
                          ? selectedDepartments.remove(department)
                          : selectedDepartments.add(department);
                    }),
                  ),
              ],
            )),
            const SizedBox(height: 10),
            StatefulBuilder(builder: (context, setModalState) => Wrap(
              spacing: 10,
              runSpacing: 14,
              children: [
                for (final account in widget.state.accounts)
                  FilterChip(
                    label: Text(account.name),
                    selected: selectedUsers.contains(account.id),
                    onSelected: (_) => setModalState(() {
                      selectedUsers.contains(account.id)
                          ? selectedUsers.remove(account.id)
                          : selectedUsers.add(account.id);
                    }),
                  ),
              ],
            )),
            const SizedBox(height: 20),
            TheWeModalActions(
              primaryLabel: '저장',
              secondaryLabel: '취소',
              onPrimaryPressed: () => Navigator.pop(context, true),
              onSecondaryPressed: () => Navigator.pop(context, false),
              centered: true,
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || controller.text.trim().isEmpty) return;
    await ref
        .read<Dio>(dioProvider)
        .patch(
          '/board/rooms/${room['id']}',
          data: {
            'name': controller.text.trim(),
            'departments': selectedDepartments.toList(),
            'userIds': selectedUsers.toList(),
          },
        );
    await _loadRooms();
  }

  Future<void> _deleteRoom(Map<String, dynamic> room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => TheWeConfirmDialog(
        title: '자료공유 방 삭제',
        message: '“${room['name']}” 방을 삭제하시겠습니까?',
        primaryLabel: '삭제',
        secondaryLabel: '취소',
        onPrimaryPressed: () => Navigator.of(context).pop(true),
        onSecondaryPressed: () => Navigator.of(context).pop(false),
      ),
    );
    if (confirmed != true) return;
    await ref.read<Dio>(dioProvider).delete('/board/rooms/${room['id']}');
    await _loadRooms();
  }

  Future<void> _openCreateDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => TheWeModalSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TheWeModalHeader(
              title: '자료공유 방 생성',
              onClose: () => Navigator.pop(context),
            ),
            SizedBox(
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
                  spacing: 14,
                  runSpacing: 12,
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
                  spacing: 14,
                  runSpacing: 12,
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
            const SizedBox(height: 20),
            TheWeModalActions(
              primaryLabel: '방 생성',
              secondaryLabel: '취소',
              onPrimaryPressed: () async {
                await create();
                if (mounted) Navigator.pop(context);
              },
              onSecondaryPressed: () => Navigator.pop(context),
              centered: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMembers(Map<String, dynamic> room) async {
    final members = (room['members'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((member) => Map<String, dynamic>.from(member))
        .toList();
    await showDialog<void>(
      context: context,
      builder: (_) => TheWeModalSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TheWeModalHeader(
              title: '${room['name']} 멤버',
              onClose: () => Navigator.pop(context),
            ),
            if (members.isEmpty)
              Text('등록된 멤버가 없습니다.', style: TheWeTextStyle.body)
            else
              ...members.map(
                (member) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    '${member['name'] ?? member['id']}${(member['department'] as String? ?? '').isEmpty ? '' : ' · ${member['department']}'}',
                    style: TheWeTextStyle.body,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (permissionMode) {
      return AdminSharedRoomPermissions(
        state: widget.state,
        initialRooms: const [],
        onBack: () => setState(() => permissionMode = false),
      );
    }
    return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text('생성된 자료공유 방', style: TheWeTextStyle.title)),
          OutlinedButton.icon(
            onPressed: () => setState(() => permissionMode = true),
            icon: const Icon(Icons.admin_panel_settings_outlined),
            label: const Text('권한 관리'),
          ),
          const SizedBox(width: 8),
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
              onTap: () => _showMembers(room),
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
}

class AdminSharedRoomPermissions extends ConsumerStatefulWidget {
  const AdminSharedRoomPermissions({super.key, required this.state, required this.onBack, this.initialRooms = const []});
  final ApprovalDashboardState state;
  final VoidCallback onBack;
  final List<Map<String, dynamic>> initialRooms;
  @override
  ConsumerState<AdminSharedRoomPermissions> createState() => _AdminSharedRoomPermissionsState();
}

class _AdminSharedRoomPermissionsState extends ConsumerState<AdminSharedRoomPermissions> {
  List<Map<String, dynamic>> rooms = [];
  bool loading = true;
  String? loadError;
  String? expandedGroup;
  @override
  void initState() {
    super.initState();
    rooms = List<Map<String, dynamic>>.from(widget.initialRooms);
    if (rooms.isEmpty) _load(); else loading = false;
  }
  Future<void> _load() async {
    try {
      final response = await ref.read<Dio>(dioProvider).get<Map<String, dynamic>>('/board/rooms');
      if (mounted) setState(() { rooms = (response.data?['rooms'] as List<dynamic>? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(); loading = false; });
    } catch (_) {
      if (mounted) setState(() { loading = false; loadError = '자료공유 방 목록을 불러오지 못했습니다.'; });
    }
  }
  bool _alwaysAllowed(EmployeeAccount account) =>
      account.isSystemAdministrator || account.isDesignatedAdministrator;

  bool _defaultDepartmentAccess(Map<String, dynamic> room, EmployeeAccount account) =>
      account.department.trim() == (room['name']?.toString() ?? '').trim();
  Future<void> _toggle(Map<String, dynamic> room, String userId, bool enabled) async {
    final members = (room['members'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => e['id'].toString())
        .toSet();
    enabled ? members.add(userId) : members.remove(userId);
    final isDepartmentGroup = widget.state.departments.contains(
      room['name']?.toString(),
    );
    if (isDepartmentGroup) {
      for (final account in widget.state.accounts) {
        if (_alwaysAllowed(account) || _defaultDepartmentAccess(room, account)) {
          members.add(account.id);
        }
      }
    }
    try {
      await ref.read<Dio>(dioProvider).patch(
        '/board/rooms/${room['id']}',
        data: {'userIds': members.toList()},
      );
      await _load();
    } catch (_) {
      if (mounted) setState(() => loadError = '권한을 저장하지 못했습니다.');
    }
  }
  List<Widget> _permissionGroups(List<EmployeeAccount> accounts) {
    final departmentGroups = widget.state.departments.map((name) {
      return rooms.firstWhere(
        (room) => room['name']?.toString() == name,
        orElse: () => <String, dynamic>{'id': 'department:$name', 'name': name, 'members': const []},
      );
    }).toList();
    final customRooms = rooms
        .where((room) => !widget.state.departments.contains(room['name']?.toString()))
        .toList();
    final groups = <Map<String, dynamic>>[...departmentGroups, ...customRooms];
    return [
      for (var index = 0; index < groups.length; index++) ...[
        if (index == departmentGroups.length && customRooms.isNotEmpty)
          const Divider(height: 28),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide.none,
          ),
          child: ExpansionTile(
            key: PageStorageKey(groups[index]['id']),
            initiallyExpanded: expandedGroup == groups[index]['id'],
            onExpansionChanged: (open) => setState(() => expandedGroup = open ? groups[index]['id'].toString() : null),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide.none,
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide.none,
            ),
            tilePadding: const EdgeInsets.symmetric(horizontal: 18),
            title: Text(groups[index]['name']?.toString() ?? '', style: TheWeTextStyle.subtitle),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            children: [Wrap(spacing: 8, runSpacing: 4, children: [for (final account in accounts) Builder(builder: (context) {
              final id = account.id;
              final members = (groups[index]['members'] as List<dynamic>? ?? const []).whereType<Map>().map((e) => e['id'].toString()).toSet();
              final isDepartmentGroup = widget.state.departments.contains(groups[index]['name']?.toString());
              final isVirtualGroup = groups[index]['id'].toString().startsWith('department:');
              final fixed = _alwaysAllowed(account) || (isDepartmentGroup && _defaultDepartmentAccess(groups[index], account));
              return FilterChip(label: Text(account.name), selected: fixed || members.contains(id), onSelected: fixed || isVirtualGroup ? null : (value) => _toggle(groups[index], id, value));
            })])],
          ),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final accounts = widget.state.accounts.where((a) => !a.isSystemAdministrator).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back), tooltip: '자료공유 방으로 돌아가기'),
        Expanded(child: Text('자료공유 권한 관리', style: TheWeTextStyle.title)),
      ]),
      const SizedBox(height: 8),
      Text('방별로 자료공유를 볼 수 있는 사원을 지정합니다. 대표와 관리자 계정은 모든 방을 볼 수 있습니다.', style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500)),
      const SizedBox(height: 18),
      if (loading) const Center(child: CircularProgressIndicator()),
      if (!loading && loadError != null) Text(loadError!, style: TheWeTextStyle.body.copyWith(color: TheWeColor.danger)),
      if (!loading && loadError == null && rooms.isEmpty) Text('생성된 자료공유 방이 없습니다. 먼저 방을 생성해 주세요.', style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500)),
      ..._permissionGroups(accounts),
    ]);
  }
}
