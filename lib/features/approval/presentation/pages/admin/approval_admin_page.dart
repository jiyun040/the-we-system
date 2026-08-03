import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:the_we_system/common/components/the_we_data_table.dart';
import 'package:the_we_system/common/components/the_we_dropdown.dart';
import 'package:the_we_system/common/components/the_we_logo.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';

class ApprovalAdminPage extends ConsumerStatefulWidget {
  const ApprovalAdminPage({super.key});

  @override
  ConsumerState<ApprovalAdminPage> createState() => _ApprovalAdminPageState();
}

class _ApprovalAdminPageState extends ConsumerState<ApprovalAdminPage> {
  int selectedIndex = 0;
  bool settingsUnlocked = false;

  static const destinations = [
    (Icons.dashboard_outlined, '근태 관리'),
    (Icons.people_outline, '사원 관리'),
    (Icons.account_tree_outlined, '조직 관리'),
    (Icons.apps_outlined, 'APP 관리'),
    (Icons.tune_outlined, '통합 설정'),
  ];

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(approvalDashboardControllerProvider);
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      backgroundColor: TheWeColor.background,
      bottomNavigationBar: asyncState.maybeWhen(
        data: (state) => state.isAdminMode && mobile
            ? _AdminBottomNavigation(
                selectedIndex: selectedIndex,
                onSelected: (value) => setState(() => selectedIndex = value),
              )
            : null,
        orElse: () => null,
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, stackTrace) =>
            const Center(child: Text('관리자 정보를 불러오지 못했습니다.')),
        data: (state) {
          if (!state.isAdminMode) {
            return _AdminAccessGate(onVerified: () => setState(() {}));
          }
          final compact = MediaQuery.sizeOf(context).width < 900;
          return SafeArea(
            child: Row(
              children: [
                if (!compact)
                  _AdminNavigation(
                    selectedIndex: selectedIndex,
                    portalName: state.portalName,
                    logoBytes: state.customLogoBytes,
                    onSelected: (value) =>
                        setState(() => selectedIndex = value),
                    onLeave: _leaveAdmin,
                  ),
                Expanded(
                  child: ColoredBox(
                    color: TheWeColor.background,
                    child: Column(
                      children: [
                        if (compact)
                          _AdminHeader(
                            mobile: mobile,
                            onOpenMenu: !mobile
                                ? () => _showCompactMenu(state)
                                : null,
                            onLeave: _leaveAdmin,
                          ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(mobile ? 14 : 28),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 1320,
                                ),
                                child: switch (selectedIndex) {
                                  0 => _AdminDashboard(state: state),
                                  1 => _EmployeeManagement(state: state),
                                  2 => _OrganizationManagement(state: state),
                                  3 => _AppManagement(state: state),
                                  _ =>
                                    !state.settingsPasswordEnabled ||
                                            settingsUnlocked
                                        ? _IntegratedSettings(state: state)
                                        : _SettingsPasswordGate(
                                            onUnlocked: () => setState(
                                              () => settingsUnlocked = true,
                                            ),
                                          ),
                                },
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
        },
      ),
    );
  }

  void _leaveAdmin() {
    ref.read(approvalDashboardControllerProvider.notifier).leaveAdminMode();
    context.goNamed(AppRouteName.home);
  }

  Future<void> _showCompactMenu(ApprovalDashboardState state) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: destinations.length,
        itemBuilder: (context, index) => ListTile(
          selected: selectedIndex == index,
          leading: Icon(destinations[index].$1),
          title: Text(destinations[index].$2),
          onTap: () => Navigator.pop(context, index),
        ),
      ),
    );
    if (selected != null) setState(() => selectedIndex = selected);
  }
}

class _AdminAccessGate extends ConsumerWidget {
  const _AdminAccessGate({required this.onVerified});
  final VoidCallback onVerified;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final state = ref.watch(approvalDashboardControllerProvider).asData?.value;
    final otpEnabled = state?.adminOtpEnabled ?? true;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(mobile ? 18 : 0),
        child: Container(
          width: mobile ? double.infinity : 440,
          padding: EdgeInsets.all(mobile ? 20 : 32),
          decoration: _adminSurface(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                size: mobile ? 40 : 56,
                color: TheWeColor.blue300,
              ),
              SizedBox(height: mobile ? 12 : 18),
              Text(
                '관리자 인증이 필요합니다',
                style: mobile
                    ? TheWeTextStyle.title.copyWith(fontSize: 20)
                    : TheWeTextStyle.title,
              ),
              const SizedBox(height: 7),
              Text(
                otpEnabled
                    ? '관리자 권한 계정에서 OTP 인증 후 접근할 수 있습니다.'
                    : '관리자 권한이 확인되어 바로 관리자 화면으로 이동할 수 있습니다.',
                textAlign: TextAlign.center,
                style: TheWeTextStyle.caption.copyWith(
                  color: TheWeColor.black500,
                ),
              ),
              SizedBox(height: mobile ? 15 : 22),
              FilledButton(
                onPressed: () async {
                  var otp = '';
                  if (otpEnabled) {
                    final verified = await _requestOtp(context);
                    if (verified == null) return;
                    otp = verified;
                  }
                  final success = ref
                      .read(approvalDashboardControllerProvider.notifier)
                      .enterAdminMode(otp);
                  if (success) {
                    onVerified();
                  }
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('OTP 번호가 올바르지 않습니다.')),
                    );
                  }
                },
                child: Text(otpEnabled ? 'OTP 인증' : '관리자 화면 열기'),
              ),
              TextButton(
                onPressed: () => context.goNamed(AppRouteName.home),
                child: const Text('일반 화면으로 돌아가기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminNavigation extends StatelessWidget {
  const _AdminNavigation({
    required this.selectedIndex,
    required this.portalName,
    required this.logoBytes,
    required this.onSelected,
    required this.onLeave,
  });
  final int selectedIndex;
  final String portalName;
  final Uint8List? logoBytes;
  final ValueChanged<int> onSelected;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) => Container(
    width: 260,
    color: const Color(0xFFFCFCFD),
    padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
    foregroundDecoration: BoxDecoration(
      border: Border(
        right: BorderSide(color: TheWeColor.black300.withValues(alpha: .28)),
      ),
    ),
    child: Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TheWeLogo(bytes: logoBytes),
          const SizedBox(height: 8),
          Text(
            portalName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
          ),
          const SizedBox(height: 30),
          ...List.generate(_ApprovalAdminPageState.destinations.length, (
            index,
          ) {
            final item = _ApprovalAdminPageState.destinations[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                selected: selectedIndex == index,
                selectedTileColor: TheWeColor.blueSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Icon(item.$1),
                title: Text(item.$2),
                onTap: () => onSelected(index),
              ),
            );
          }),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: onLeave,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('일반 계정 화면'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
          ),
        ],
      ),
    ),
  );
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({
    required this.mobile,
    required this.onOpenMenu,
    required this.onLeave,
  });
  final bool mobile;
  final VoidCallback? onOpenMenu;
  final VoidCallback onLeave;
  @override
  Widget build(BuildContext context) => Container(
    height: mobile ? 46 : 56,
    padding: EdgeInsets.symmetric(horizontal: mobile ? 14 : 28),
    color: TheWeColor.background,
    child: Row(
      children: [
        if (onOpenMenu != null)
          IconButton(onPressed: onOpenMenu, icon: const Icon(Icons.menu)),
        const Spacer(),
        IconButton(
          onPressed: onLeave,
          tooltip: '일반 화면',
          icon: const Icon(Icons.swap_horiz),
        ),
      ],
    ),
  );
}

class _AdminBottomNavigation extends StatelessWidget {
  const _AdminBottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selectedIndex,
    backgroundColor: TheWeColor.background,
    indicatorColor: Colors.transparent,
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      return TheWeTextStyle.caption.copyWith(
        color: selected ? TheWeColor.blue300 : TheWeColor.black900,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      );
    }),
    overlayColor: WidgetStatePropertyAll(
      TheWeColor.blue100.withValues(alpha: 0.18),
    ),
    onDestinationSelected: onSelected,
    destinations: [
      for (final destination in _ApprovalAdminPageState.destinations)
        NavigationDestination(
          icon: Icon(destination.$1),
          selectedIcon: Icon(destination.$1, color: TheWeColor.blue300),
          label: destination.$2,
        ),
    ],
  );
}

class _AdminDashboard extends ConsumerWidget {
  const _AdminDashboard({required this.state});
  final ApprovalDashboardState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingLeaves = state.leaveRequests
        .where((item) => item.status == '승인대기')
        .toList();
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final currentUser = state.currentUser;
    final isLeaveDecisionAccount =
        currentUser?.id == 'director' ||
        currentUser?.id == 'ceo' ||
        currentUser?.position.contains('이사') == true ||
        currentUser?.position.contains('상무') == true ||
        currentUser?.position.contains('대표') == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '회사 운영 현황',
          style: mobile
              ? TheWeTextStyle.title.copyWith(fontSize: 19)
              : TheWeTextStyle.title,
        ),
        SizedBox(height: mobile ? 12 : 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth < 600
                ? (constraints.maxWidth - 10) / 2
                : constraints.maxWidth < 760
                ? constraints.maxWidth
                : (constraints.maxWidth - 36) / 4;
            return Wrap(
              spacing: mobile ? 10 : 12,
              runSpacing: mobile ? 10 : 12,
              children: [
                _AdminMetric(
                  width: width,
                  icon: Icons.people_outline,
                  label: '전체 직원',
                  value: '${state.accounts.length}명',
                  onTap: () => _showEmployeeLeaveDirectory(context, state),
                ),
                _AdminMetric(
                  width: width,
                  icon: Icons.account_tree_outlined,
                  label: '부서',
                  value: '${state.departments.length}개',
                ),
                _AdminMetric(
                  width: width,
                  icon: Icons.pending_actions_outlined,
                  label: '결재 대기',
                  value: '${state.waitingDocuments.length}건',
                ),
                _AdminMetric(
                  width: width,
                  icon: Icons.beach_access_outlined,
                  label: '휴가 승인 대기',
                  value: '${pendingLeaves.length}건',
                ),
              ],
            );
          },
        ),
        SizedBox(height: mobile ? 22 : 28),
        Text(
          '전자결재 문서 관리',
          style: mobile
              ? TheWeTextStyle.title.copyWith(fontSize: 19)
              : TheWeTextStyle.title,
        ),
        const SizedBox(height: 6),
        Text(
          '전체 결재 대기·완료·반려·작성 문서를 조회하고 현재 결재를 처리할 수 있습니다.',
          style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
        ),
        const SizedBox(height: 12),
        _AdminDocumentManagement(
          documents: state.hasAdminDocumentAccess
              ? state.documents
              : state.visibleDocuments,
        ),
        SizedBox(height: mobile ? 22 : 28),
        Text(
          '휴가 승인 관리',
          style: mobile
              ? TheWeTextStyle.title.copyWith(fontSize: 19)
              : TheWeTextStyle.title,
        ),
        const SizedBox(height: 12),
        if (pendingLeaves.isEmpty)
          Container(
            width: double.infinity,
            decoration: _adminSurface(),
            padding: EdgeInsets.all(mobile ? 22 : 40),
            child: const Center(child: Text('승인 대기 중인 휴가가 없습니다.')),
          )
        else if (mobile)
          ...pendingLeaves.map((request) {
            final employee = state.accounts
                .where((item) => item.id == request.userId)
                .firstOrNull;
            return _PendingLeaveCard(
              employee: employee,
              request: request,
              showDetails: isLeaveDecisionAccount,
              canAct: state.canActOnLeave(request),
              onReject: () => ref
                  .read(approvalDashboardControllerProvider.notifier)
                  .actOnLeave(request.id, approve: false),
              onApprove: () => ref
                  .read(approvalDashboardControllerProvider.notifier)
                  .actOnLeave(request.id, approve: true),
            );
          })
        else if (!isLeaveDecisionAccount)
          TheWeDataTable(
            headers: const ['신청 직원', '결재 상태'],
            columnFlexes: const [1.8, 1.2],
            minWidth: 620,
            rows: pendingLeaves.map((request) {
              final employee = state.accounts
                  .where((item) => item.id == request.userId)
                  .firstOrNull;
              return <Widget>[
                Text(
                  '${employee?.name ?? request.userId} · ${employee?.department ?? ''}',
                  textAlign: TextAlign.center,
                ),
                const Text('대표·이사 결재 진행중'),
              ];
            }).toList(),
          )
        else
          TheWeDataTable(
            headers: const ['직원', '종류', '기간', '일수', '처리'],
            columnFlexes: const [1.8, 1.05, 2.2, .7, 1.35],
            minWidth: 980,
            rows: pendingLeaves.map((request) {
              final employee = state.accounts
                  .where((item) => item.id == request.userId)
                  .firstOrNull;
              return <Widget>[
                Text(
                  '${employee?.name ?? request.userId} · ${employee?.department ?? ''}',
                ),
                Text(request.type),
                Text('${request.startDate} ~ ${request.endDate}'),
                Text('${request.days}일'),
                state.canActOnLeave(request)
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () => ref
                                .read(
                                  approvalDashboardControllerProvider.notifier,
                                )
                                .actOnLeave(request.id, approve: false),
                            child: const Text('반려'),
                          ),
                          const SizedBox(width: 6),
                          FilledButton(
                            onPressed: () => ref
                                .read(
                                  approvalDashboardControllerProvider.notifier,
                                )
                                .actOnLeave(request.id, approve: true),
                            child: const Text('승인'),
                          ),
                        ],
                      )
                    : const Text('다음 결재 대기'),
              ];
            }).toList(),
          ),
      ],
    );
  }
}

class _AdminDocumentManagement extends StatefulWidget {
  const _AdminDocumentManagement({required this.documents});

  final List<ApprovalDocument> documents;

  @override
  State<_AdminDocumentManagement> createState() =>
      _AdminDocumentManagementState();
}

class _AdminDocumentManagementState extends State<_AdminDocumentManagement> {
  String selectedStatus = '전체';

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 700;
    final sorted = [...widget.documents]
      ..sort((a, b) => b.draftedAt.compareTo(a.draftedAt));
    final visible = selectedStatus == '전체'
        ? sorted
        : sorted
              .where((document) => document.status == selectedStatus)
              .toList();
    final statuses = ['전체', '결재대기', '완료', '반려', '작성중'];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 14 : 18),
      decoration: _adminSurface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: statuses.map((status) {
              final count = status == '전체'
                  ? sorted.length
                  : sorted
                        .where((document) => document.status == status)
                        .length;
              return ChoiceChip(
                key: ValueKey('admin-document-filter-$status'),
                selected: selectedStatus == status,
                label: Text('${_adminDocumentStatusLabel(status)} $count'),
                onSelected: (_) => setState(() => selectedStatus = status),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  '해당 상태의 전자결재 문서가 없습니다.',
                  style: TheWeTextStyle.body.copyWith(
                    color: TheWeColor.black500,
                  ),
                ),
              ),
            )
          else if (mobile)
            ...visible.map((document) => _AdminDocumentCard(document: document))
          else
            TheWeDataTable(
              headers: const ['상태', '문서명', '기안자/부서', '양식', '기안일', '진행률', '관리'],
              columnFlexes: const [1, 2.6, 1.45, 1.4, 1.1, .8, 1],
              minWidth: 1080,
              rows: visible
                  .map(
                    (document) => <Widget>[
                      _AdminDocumentStatus(status: document.status),
                      Text(
                        document.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '${document.drafter}\n${document.department}',
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        document.form,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      Text(document.draftedAt),
                      Text('${document.progress}%'),
                      OutlinedButton(
                        onPressed: () => _openAdminDocument(context, document),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(76, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: const Text('상세', maxLines: 1, softWrap: false),
                      ),
                    ],
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _AdminDocumentCard extends StatelessWidget {
  const _AdminDocumentCard({required this.document});

  final ApprovalDocument document;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('admin-document-${document.id}'),
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: TheWeColor.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: TheWeColor.black300.withValues(alpha: .24)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _AdminDocumentStatus(status: document.status),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                document.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TheWeTextStyle.subtitle.copyWith(fontSize: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '${document.drafter} · ${document.department} · ${document.form}',
          style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: document.progress / 100,
                minHeight: 6,
                borderRadius: BorderRadius.circular(999),
                color: TheWeColor.blue300,
                backgroundColor: TheWeColor.blueSurface,
              ),
            ),
            const SizedBox(width: 10),
            Text('${document.progress}%'),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: () => _openAdminDocument(context, document),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(68, 38),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('상세', maxLines: 1, softWrap: false),
            ),
          ],
        ),
      ],
    ),
  );
}

class _AdminDocumentStatus extends StatelessWidget {
  const _AdminDocumentStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      '완료' => TheWeColor.green,
      '반려' => TheWeColor.danger,
      '작성중' => TheWeColor.black500,
      _ => TheWeColor.blue300,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Text(
        _adminDocumentStatusLabel(status),
        style: TheWeTextStyle.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _adminDocumentStatusLabel(String status) =>
    status == '결재대기' ? '결재 대기' : status;

void _openAdminDocument(BuildContext context, ApprovalDocument document) {
  context.pushNamed(AppRouteName.detail, pathParameters: {'id': document.id});
}

class _PendingLeaveCard extends StatelessWidget {
  const _PendingLeaveCard({
    required this.employee,
    required this.request,
    required this.showDetails,
    required this.canAct,
    required this.onReject,
    required this.onApprove,
  });

  final EmployeeAccount? employee;
  final LeaveRequest request;
  final bool showDetails;
  final bool canAct;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(13),
    decoration: _adminSurface(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${employee?.name ?? request.userId} · ${employee?.department ?? ''}',
                style: TheWeTextStyle.subtitle.copyWith(fontSize: 16),
              ),
            ),
            if (showDetails)
              Chip(
                label: Text(request.type),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          showDetails
              ? '${request.startDate} ~ ${request.endDate} · ${request.days}일'
              : '대표·이사 결재 진행중',
          style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
        ),
        if (canAct) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  child: const Text('반려'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onApprove,
                  child: const Text('승인'),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _EmployeeManagement extends ConsumerWidget {
  const _EmployeeManagement({required this.state});
  final ApprovalDashboardState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = MediaQuery.sizeOf(context).width < 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '전체 직원 사원관리',
                style: mobile
                    ? TheWeTextStyle.title.copyWith(fontSize: 19)
                    : TheWeTextStyle.title,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _addEmployee(context, ref),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('직원 추가'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (mobile)
          ...state.accounts.map(
            (account) => _EmployeeCard(
              account: account,
              onEdit: () => _editEmployee(context, ref, account),
            ),
          )
        else
          TheWeDataTable(
            headers: const ['이름/아이디', '부서', '직위', '입사일', '권한', '관리'],
            columnFlexes: const [1.65, 1.25, 1, 1.25, .9, .7],
            minWidth: 1050,
            rows: state.accounts
                .map(
                  (account) => <Widget>[
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(account.name),
                        const SizedBox(height: 3),
                        Text(
                          account.id,
                          style: TheWeTextStyle.caption.copyWith(
                            color: TheWeColor.black500,
                          ),
                        ),
                      ],
                    ),
                    Text(account.department),
                    Text(account.position),
                    Text(account.hireDate),
                    Align(
                      alignment: Alignment.center,
                      child: Chip(
                        backgroundColor: account.isAdmin
                            ? TheWeColor.blueSurface
                            : TheWeColor.background,
                        side: BorderSide(
                          color: TheWeColor.black300.withValues(alpha: .2),
                        ),
                        label: Text(account.isAdmin ? '관리자' : '일반'),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _editEmployee(context, ref, account),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: '계정 수정',
                    ),
                  ],
                )
                .toList(),
          ),
      ],
    );
  }

  Future<void> _addEmployee(BuildContext context, WidgetRef ref) async {
    final id = TextEditingController();
    final password = TextEditingController();
    final name = TextEditingController();
    final email = TextEditingController();
    final department = TextEditingController();
    final position = TextEditingController();
    final hireDate = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
    var isAdmin = false;
    var error = '';

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: TheWeColor.surfaceAlt,
          title: const Text('직원 추가'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: '이름'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: id,
                    decoration: const InputDecoration(labelText: '아이디'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: '초기 비밀번호'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: '이메일'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: department,
                    decoration: const InputDecoration(labelText: '부서'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: position,
                    decoration: const InputDecoration(labelText: '직위'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: hireDate,
                    readOnly: true,
                    onTap: () => _selectHireDate(context, hireDate),
                    decoration: const InputDecoration(
                      labelText: '입사일',
                      suffixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('관리자 권한'),
                    value: isAdmin,
                    onChanged: (value) => setDialogState(() => isAdmin = value),
                  ),
                  if (error.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        error,
                        style: TheWeTextStyle.caption.copyWith(
                          color: TheWeColor.danger,
                        ),
                      ),
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
              onPressed: () {
                final message = ref
                    .read(approvalDashboardControllerProvider.notifier)
                    .addEmployee(
                      id: id.text,
                      password: password.text,
                      name: name.text,
                      department: department.text,
                      position: position.text,
                      email: email.text,
                      hireDate: hireDate.text,
                      isAdmin: isAdmin,
                    );
                if (message != null) {
                  setDialogState(() => error = message);
                  return;
                }
                Navigator.pop(context);
              },
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editEmployee(
    BuildContext context,
    WidgetRef ref,
    EmployeeAccount account,
  ) async {
    final department = TextEditingController(text: account.department);
    final position = TextEditingController(text: account.position);
    final hireDate = TextEditingController(text: account.hireDate);
    final password = TextEditingController();
    var isAdmin = account.isAdmin;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: TheWeColor.surfaceAlt,
          title: Text('${account.name} 계정 수정'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: department,
                    decoration: const InputDecoration(labelText: '부서'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: position,
                    decoration: const InputDecoration(labelText: '직위'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: hireDate,
                    readOnly: true,
                    onTap: () => _selectHireDate(context, hireDate),
                    decoration: const InputDecoration(
                      labelText: '입사일',
                      suffixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '새 비밀번호',
                      hintText: '변경하지 않으면 비워두세요.',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('관리자 권한'),
                    value: isAdmin,
                    onChanged: (value) => setState(() => isAdmin = value),
                  ),
                ],
              ),
            ),
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
      ),
    );
    if (saved != true) return;
    ref
        .read(approvalDashboardControllerProvider.notifier)
        .updateEmployee(
          userId: account.id,
          department: department.text,
          position: position.text,
          hireDate: hireDate.text,
          password: password.text,
          isAdmin: isAdmin,
        );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.account, required this.onEdit});

  final EmployeeAccount account;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('employee-card-${account.id}'),
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: _adminSurface(),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: TheWeColor.blueSurface,
              child: Text(
                account.name.substring(0, 1),
                style: TheWeTextStyle.subtitle.copyWith(
                  color: TheWeColor.blue300,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: TheWeTextStyle.subtitle.copyWith(fontSize: 16),
                  ),
                  Text(
                    account.id,
                    style: TheWeTextStyle.caption.copyWith(
                      color: TheWeColor.black500,
                    ),
                  ),
                ],
              ),
            ),
            Chip(
              backgroundColor: account.isAdmin
                  ? TheWeColor.blueSurface
                  : TheWeColor.background,
              side: BorderSide(
                color: TheWeColor.black300.withValues(alpha: .2),
              ),
              label: Text(account.isAdmin ? '관리자' : '일반'),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: '계정 수정',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const Divider(height: 15),
        Row(
          children: [
            Expanded(
              child: _EmployeeInfo(label: '부서', value: account.department),
            ),
            Expanded(
              child: _EmployeeInfo(label: '직위', value: account.position),
            ),
            Expanded(
              child: _EmployeeInfo(label: '입사일', value: account.hireDate),
            ),
          ],
        ),
      ],
    ),
  );
}

class _EmployeeInfo extends StatelessWidget {
  const _EmployeeInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        label,
        style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TheWeTextStyle.body.copyWith(fontSize: 13),
      ),
    ],
  );
}

Future<void> _selectHireDate(
  BuildContext context,
  TextEditingController controller,
) async {
  final initialDate = DateTime.tryParse(controller.text) ?? DateTime.now();
  final selected = await _showHireDatePicker(context, initialDate);
  if (selected == null) return;
  controller.text = selected.toIso8601String().substring(0, 10);
}

Future<DateTime?> _showHireDatePicker(
  BuildContext context,
  DateTime initialDate,
) {
  var selectedDate = initialDate;
  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final compact = MediaQuery.sizeOf(context).width < 600;
        return Dialog(
          key: const ValueKey('hire-date-picker'),
          backgroundColor: TheWeColor.surfaceAlt,
          insetPadding: EdgeInsets.all(compact ? 16 : 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: SizedBox(
            width: 420,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 14 : 22,
                compact ? 16 : 20,
                compact ? 14 : 22,
                compact ? 14 : 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: TheWeColor.blueSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_month_outlined,
                          color: TheWeColor.blue300,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('입사일 선택', style: TheWeTextStyle.subtitle),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                        tooltip: '닫기',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 12 : 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: TheWeColor.blueSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatKoreanDate(selectedDate),
                      textAlign: TextAlign.center,
                      style: TheWeTextStyle.body.copyWith(
                        color: TheWeColor.blue300,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 4 : 8),
                  Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: TheWeColor.blue300,
                        onPrimary: Colors.white,
                        surface: TheWeColor.surfaceAlt,
                        onSurface: TheWeColor.black900,
                      ),
                    ),
                    child: CalendarDatePicker(
                      initialDate: initialDate,
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                      onDateChanged: (date) =>
                          setDialogState(() => selectedDate = date),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('취소'),
                      ),
                      SizedBox(width: compact ? 4 : 8),
                      FilledButton(
                        onPressed: () =>
                            Navigator.pop(dialogContext, selectedDate),
                        style: FilledButton.styleFrom(
                          backgroundColor: TheWeColor.black900,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 20 : 24,
                            vertical: 13,
                          ),
                        ),
                        child: const Text('선택'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

String _formatKoreanDate(DateTime date) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${date.year}년 ${date.month}월 ${date.day}일 '
      '(${weekdays[date.weekday - 1]})';
}

class _OrganizationManagement extends ConsumerWidget {
  const _OrganizationManagement({required this.state});
  final ApprovalDashboardState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('조직도 및 부서 관리', style: TheWeTextStyle.title),
      const SizedBox(height: 8),
      Text(
        '계정에 설정된 부서 기준으로 전자결재 부서 문서함이 자동 연결됩니다.',
        style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
      ),
      const SizedBox(height: 18),
      LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth < 680
              ? constraints.maxWidth
              : (constraints.maxWidth - 16) / 2;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: state.departments.map((department) {
              final members = state.accounts
                  .where((account) => account.department == department)
                  .toList();
              return Container(
                width: width,
                padding: const EdgeInsets.all(20),
                decoration: _adminSurface(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.folder_shared_outlined,
                          color: TheWeColor.blue300,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            department,
                            style: TheWeTextStyle.subtitle,
                          ),
                        ),
                        Chip(label: Text('${members.length}명')),
                        IconButton(
                          onPressed: () =>
                              _renameDepartment(context, ref, department),
                          icon: const Icon(Icons.edit_outlined, size: 19),
                          tooltip: '부서명 수정',
                        ),
                      ],
                    ),
                    const Divider(height: 26),
                    ...members.map(
                      (member) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: CircleAvatar(
                          child: Text(member.name.substring(0, 1)),
                        ),
                        title: Text(member.name),
                        subtitle: Text('${member.position} · ${member.id}'),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    ],
  );
}

Future<void> _renameDepartment(
  BuildContext context,
  WidgetRef ref,
  String department,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _RenameDepartmentDialog(
      department: department,
      onSave: (nextName) => ref
          .read(approvalDashboardControllerProvider.notifier)
          .renameDepartment(department, nextName),
    ),
  );
}

class _RenameDepartmentDialog extends StatefulWidget {
  const _RenameDepartmentDialog({
    required this.department,
    required this.onSave,
  });

  final String department;
  final String? Function(String nextName) onSave;

  @override
  State<_RenameDepartmentDialog> createState() =>
      _RenameDepartmentDialogState();
}

class _RenameDepartmentDialogState extends State<_RenameDepartmentDialog> {
  late final TextEditingController _controller;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.department);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: TheWeColor.surfaceAlt,
      title: const Text('부서명 수정'),
      content: SizedBox(
        width: 420,
        child: TextField(
          key: const ValueKey('department-name-field'),
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: '부서명',
            errorText: _error.isEmpty ? null : _error,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final message = widget.onSave(_controller.text);
            if (message != null) {
              setState(() => _error = message);
              return;
            }
            Navigator.pop(context);
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}

class _AppManagement extends ConsumerWidget {
  const _AppManagement({required this.state});
  final ApprovalDashboardState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '일반 계정 업무 APP 관리',
          style: mobile
              ? TheWeTextStyle.title.copyWith(fontSize: 19)
              : TheWeTextStyle.title,
        ),
        const SizedBox(height: 8),
        Text(
          '일반 계정 홈에 노출할 업무와 전자결재 양식을 관리합니다.',
          style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
        ),
        const SizedBox(height: 18),
        ...[
          (
            PortalAppId.approval,
            '전자결재',
            Icons.approval_outlined,
            '${state.activeFormTemplates.length}개 양식 사용 중',
          ),
          (
            PortalAppId.attendance,
            '근태',
            Icons.schedule_outlined,
            '출퇴근 및 근태 현황',
          ),
          (
            PortalAppId.leave,
            '휴가',
            Icons.beach_access_outlined,
            '휴가 신청 및 연차 현황',
          ),
        ].map(
          (app) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(mobile ? 15 : 18),
            decoration: _adminSurface(),
            child: mobile
                ? Column(
                    children: [
                      Row(
                        children: [
                          Icon(app.$3, color: TheWeColor.blue300),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AppDescription(
                              title: app.$2,
                              description: app.$4,
                            ),
                          ),
                          Switch(
                            key: ValueKey('app-switch-${app.$1}'),
                            value: state.isAppEnabled(app.$1),
                            onChanged: (enabled) => ref
                                .read(
                                  approvalDashboardControllerProvider.notifier,
                                )
                                .toggleApp(app.$1, enabled),
                          ),
                        ],
                      ),
                      if (app.$1 == PortalAppId.approval) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showFormManagementDialog(context, ref),
                            icon: const Icon(Icons.description_outlined),
                            label: const Text('양식 관리'),
                          ),
                        ),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      Icon(app.$3, color: TheWeColor.blue300),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _AppDescription(
                          title: app.$2,
                          description: app.$4,
                        ),
                      ),
                      Switch(
                        key: ValueKey('app-switch-${app.$1}'),
                        value: state.isAppEnabled(app.$1),
                        onChanged: (enabled) => ref
                            .read(approvalDashboardControllerProvider.notifier)
                            .toggleApp(app.$1, enabled),
                      ),
                      if (app.$1 == PortalAppId.approval) ...[
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () =>
                              _showFormManagementDialog(context, ref),
                          child: const Text('양식 관리'),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(mobile ? 15 : 18),
          decoration: _adminSurface(),
          child: Row(
            children: [
              const Icon(Icons.groups_outlined, color: TheWeColor.blue300),
              const SizedBox(width: 16),
              const Expanded(
                child: _AppDescription(
                  title: '인력현황',
                  description: '관리자 계정에서만 노출',
                ),
              ),
              const Chip(
                avatar: Icon(Icons.lock_outline, size: 16),
                label: Text('관리자 전용'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppDescription extends StatelessWidget {
  const _AppDescription({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: TheWeTextStyle.subtitle),
      Text(
        description,
        style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
      ),
    ],
  );
}

Future<void> _showFormManagementDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final mobile = MediaQuery.sizeOf(context).width < 600;
  if (mobile) {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: TheWeColor.background,
      builder: (sheetContext) => FractionallySizedBox(
        key: const ValueKey('mobile-form-management-sheet'),
        heightFactor: .72,
        child: _FormManagementContent(
          mobile: true,
          onClose: () => Navigator.pop(sheetContext),
        ),
      ),
    );
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: TheWeColor.background,
      child: SizedBox(
        width: 820,
        height: 640,
        child: _FormManagementContent(
          mobile: false,
          onClose: () => Navigator.pop(dialogContext),
        ),
      ),
    ),
  );
}

class _FormManagementContent extends ConsumerWidget {
  const _FormManagementContent({required this.mobile, required this.onClose});

  final bool mobile;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(approvalDashboardControllerProvider).asData?.value;
    if (state == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 16 : 24,
        mobile ? 4 : 24,
        mobile ? 16 : 24,
        mobile ? 16 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mobile) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '전자결재 양식 관리',
                    style: TheWeTextStyle.title.copyWith(fontSize: 20),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  tooltip: '닫기',
                ),
              ],
            ),
            Text(
              '사용하지 않는 양식은 일반 계정에서 바로 숨겨집니다.',
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showFormEditor(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('양식 추가'),
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('전자결재 양식 관리', style: TheWeTextStyle.title),
                      const SizedBox(height: 4),
                      Text(
                        '사용 여부를 끄면 일반 계정의 기안 양식에서 즉시 제외됩니다.',
                        style: TheWeTextStyle.caption.copyWith(
                          color: TheWeColor.black500,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showFormEditor(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('양식 추가'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  tooltip: '닫기',
                ),
              ],
            ),
          const SizedBox(height: 16),
          Expanded(
            child: state.formTemplates.isEmpty
                ? const Center(child: Text('등록된 양식이 없습니다.'))
                : ListView.separated(
                    itemCount: state.formTemplates.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final template = state.formTemplates[index];
                      final enabled = !state.disabledFormTemplateIds.contains(
                        template.id,
                      );
                      return _FormTemplateCard(
                        template: template,
                        enabled: enabled,
                        mobile: mobile,
                        onEnabledChanged: (value) => ref
                            .read(approvalDashboardControllerProvider.notifier)
                            .toggleFormTemplate(template.id, value),
                        onEdit: () =>
                            _showFormEditor(context, ref, template: template),
                        onDelete: () =>
                            _deleteFormTemplate(context, ref, template),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FormTemplateCard extends StatelessWidget {
  const _FormTemplateCard({
    required this.template,
    required this.enabled,
    required this.mobile,
    required this.onEnabledChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final ApprovalFormTemplate template;
  final bool enabled;
  final bool mobile;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(14, mobile ? 9 : 10, 7, mobile ? 9 : 10),
    decoration: BoxDecoration(
      color: TheWeColor.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: TheWeColor.black300.withValues(alpha: .18)),
    ),
    child: mobile
        ? Column(
            children: [
              Row(
                children: [
                  Expanded(child: _FormTemplateDescription(template: template)),
                  Switch(
                    key: ValueKey('form-switch-${template.id}'),
                    value: enabled,
                    onChanged: onEnabledChanged,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('수정'),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('삭제'),
                    style: TextButton.styleFrom(
                      foregroundColor: TheWeColor.danger,
                    ),
                  ),
                ],
              ),
            ],
          )
        : Row(
            children: [
              Expanded(child: _FormTemplateDescription(template: template)),
              Switch(
                key: ValueKey('form-switch-${template.id}'),
                value: enabled,
                onChanged: onEnabledChanged,
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: '양식 수정',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: TheWeColor.danger,
                tooltip: '양식 삭제',
              ),
            ],
          ),
  );
}

class _FormTemplateDescription extends StatelessWidget {
  const _FormTemplateDescription({required this.template});

  final ApprovalFormTemplate template;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(template.name, style: TheWeTextStyle.subtitle),
      const SizedBox(height: 3),
      Text(
        '${template.category} · ${ApprovalDocumentLayout.labels[template.documentLayout]} · ${template.description}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
      ),
    ],
  );
}

Future<void> _deleteFormTemplate(
  BuildContext context,
  WidgetRef ref,
  ApprovalFormTemplate template,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: TheWeColor.surfaceAlt,
      title: const Text('양식 삭제'),
      content: Text('${template.name} 양식을 삭제할까요?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: TheWeColor.danger),
          child: const Text('삭제'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    ref
        .read(approvalDashboardControllerProvider.notifier)
        .deleteFormTemplate(template.id);
  }
}

Future<void> _showFormEditor(
  BuildContext context,
  WidgetRef ref, {
  ApprovalFormTemplate? template,
}) async {
  final category = TextEditingController(text: template?.category);
  final name = TextEditingController(text: template?.name);
  final description = TextEditingController(text: template?.description);
  final defaultTitle = TextEditingController(text: template?.defaultTitle);
  final defaultContent = TextEditingController(text: template?.defaultContent);
  final lineItemRows = TextEditingController(
    text: '${template?.lineItemRows ?? 8}',
  );
  var documentLayout = template?.documentLayout ?? ApprovalDocumentLayout.basic;
  var error = '';

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: TheWeColor.surfaceAlt,
        title: Text(template == null ? '양식 추가' : '양식 수정'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: category,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: '분류'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: '양식명'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: description,
                  decoration: const InputDecoration(labelText: '설명'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: defaultTitle,
                  decoration: const InputDecoration(labelText: '기본 제목'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: defaultContent,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: '기본 본문'),
                ),
                const SizedBox(height: 10),
                TheWeDropdown<String>(
                  value: documentLayout,
                  width: double.infinity,
                  items: ApprovalDocumentLayout.labels.keys.toList(),
                  labelBuilder: (value) =>
                      ApprovalDocumentLayout.labels[value] ?? value,
                  onChanged: (value) => setDialogState(
                    () =>
                        documentLayout = value ?? ApprovalDocumentLayout.basic,
                  ),
                ),
                if (documentLayout != ApprovalDocumentLayout.basic &&
                    documentLayout != ApprovalDocumentLayout.payroll) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: lineItemRows,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '문서 표 입력 행 수',
                      helperText: 'PDF형 문서에 표시할 입력 행 수를 설정합니다.',
                    ),
                  ),
                ],
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      error,
                      style: TheWeTextStyle.caption.copyWith(
                        color: TheWeColor.danger,
                      ),
                    ),
                  ),
                ],
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
            onPressed: () {
              final message = ref
                  .read(approvalDashboardControllerProvider.notifier)
                  .saveFormTemplate(
                    templateId: template?.id,
                    category: category.text,
                    name: name.text,
                    description: description.text,
                    defaultTitle: defaultTitle.text,
                    defaultContent: defaultContent.text,
                    documentLayout: documentLayout,
                    lineItemRows:
                        int.tryParse(lineItemRows.text)?.clamp(1, 30) ?? 8,
                  );
              if (message != null) {
                setDialogState(() => error = message);
                return;
              }
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    ),
  );
}

class _SettingsPasswordGate extends ConsumerStatefulWidget {
  const _SettingsPasswordGate({required this.onUnlocked});
  final VoidCallback onUnlocked;
  @override
  ConsumerState<_SettingsPasswordGate> createState() =>
      _SettingsPasswordGateState();
}

class _SettingsPasswordGateState extends ConsumerState<_SettingsPasswordGate> {
  final controller = TextEditingController();
  String error = '';
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 460,
      padding: const EdgeInsets.all(30),
      decoration: _adminSurface(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 48),
          const SizedBox(height: 16),
          Text('통합설정 보안 확인', style: TheWeTextStyle.title),
          const SizedBox(height: 8),
          const Text('현재 계정 비밀번호를 다시 입력해 주세요.'),
          const SizedBox(height: 20),
          TextField(
            controller: controller,
            obscureText: true,
            onSubmitted: (_) => _verify(),
            decoration: InputDecoration(
              labelText: '비밀번호',
              errorText: error.isEmpty ? null : error,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: _verify, child: const Text('통합설정 열기')),
        ],
      ),
    ),
  );
  void _verify() {
    if (ref
        .read(approvalDashboardControllerProvider.notifier)
        .verifyCurrentPassword(controller.text)) {
      widget.onUnlocked();
    } else {
      setState(() => error = '비밀번호가 올바르지 않습니다.');
    }
  }
}

class _IntegratedSettings extends ConsumerWidget {
  const _IntegratedSettings({required this.state});
  final ApprovalDashboardState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('포털 및 로고', style: TheWeTextStyle.title),
        const SizedBox(height: 6),
        Text(
          '일반 계정과 관리자 계정에 공통으로 표시할 포털명과 로고를 관리합니다.',
          style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
        ),
        const SizedBox(height: 12),
        _BrandingSettingsCard(state: state),
        const SizedBox(height: 24),
        Text('조직도 설정', style: TheWeTextStyle.title),
        const SizedBox(height: 6),
        Text(
          '부서 구성과 소속 인원을 확인하고 부서명을 수정합니다.',
          style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
        ),
        const SizedBox(height: 12),
        _IntegratedOrganizationSettings(state: state),
        const SizedBox(height: 24),
        Text('APP 설정', style: TheWeTextStyle.title),
        const SizedBox(height: 6),
        Text(
          '일반 계정 홈과 메뉴에 표시할 업무 APP을 설정합니다.',
          style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
        ),
        const SizedBox(height: 12),
        _IntegratedAppSettings(state: state),
        const SizedBox(height: 24),
        Text('로그인·권한·2차 인증', style: TheWeTextStyle.title),
        const SizedBox(height: 6),
        Text(
          '관리자 로그인과 민감 설정, 전체 문서 접근 정책을 관리합니다.',
          style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: _adminSurface(),
          child: Column(
            children: [
              _SecurityPolicyTile(
                key: const ValueKey('security-admin-otp'),
                icon: Icons.phonelink_lock_outlined,
                title: '관리자 OTP 2차 인증',
                subtitle: '관리자 로그인 및 관리자 모드 전환 시 OTP 인증을 요구합니다.',
                value: state.adminOtpEnabled,
                onChanged: (value) => ref
                    .read(approvalDashboardControllerProvider.notifier)
                    .updateSecurityPolicy(adminOtpEnabled: value),
              ),
              const Divider(height: 1),
              _SecurityPolicyTile(
                key: const ValueKey('security-settings-password'),
                icon: Icons.password_outlined,
                title: '통합설정 비밀번호 재확인',
                subtitle: '통합설정 진입 전에 현재 계정 비밀번호를 다시 확인합니다.',
                value: state.settingsPasswordEnabled,
                onChanged: (value) => ref
                    .read(approvalDashboardControllerProvider.notifier)
                    .updateSecurityPolicy(settingsPasswordEnabled: value),
              ),
              const Divider(height: 1),
              _SecurityPolicyTile(
                key: const ValueKey('security-admin-documents'),
                icon: Icons.folder_shared_outlined,
                title: '관리자 전체 결재 문서 열람·처리',
                subtitle: '관리자가 모든 결재 대기·완료 문서를 조회하고 현재 결재를 처리합니다.',
                value: state.adminDocumentAccessEnabled,
                onChanged: (value) => ref
                    .read(approvalDashboardControllerProvider.notifier)
                    .updateSecurityPolicy(adminDocumentAccessEnabled: value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('관리자 권한 설정', style: TheWeTextStyle.title),
        const SizedBox(height: 6),
        Text(
          '관리자 모드와 통합설정에 접근할 계정을 지정합니다.',
          style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
        ),
        const SizedBox(height: 12),
        _AdminPermissionSettings(state: state),
        const SizedBox(height: 24),
        Text('근속연수별 연차 설정', style: TheWeTextStyle.title),
        const SizedBox(height: 12),
        _AnnualLeavePolicyEditor(
          policy: state.annualLeaveByYear,
          monthlyLeavePerMonth: state.monthlyLeavePerMonth,
        ),
      ],
    );
  }
}

class _IntegratedOrganizationSettings extends ConsumerWidget {
  const _IntegratedOrganizationSettings({required this.state});

  final ApprovalDashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    decoration: _adminSurface(),
    clipBehavior: Clip.antiAlias,
    child: Material(
      color: Colors.transparent,
      child: Column(
        children: [
          for (var index = 0; index < state.departments.length; index++) ...[
            Builder(
              builder: (context) {
                final department = state.departments[index];
                final members =
                    state.accounts
                        .where((account) => account.department == department)
                        .toList()
                      ..sort((a, b) => a.name.compareTo(b.name));
                return ExpansionTile(
                  key: PageStorageKey('organization-$department'),
                  tilePadding: const EdgeInsets.only(left: 12, right: 10),
                  childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  leading: const Icon(
                    Icons.folder_shared_outlined,
                    color: TheWeColor.blue300,
                  ),
                  title: Text(department, style: TheWeTextStyle.subtitle),
                  subtitle: Text('${members.length}명 소속 · 눌러서 구성원 확인'),
                  trailing: IconButton(
                    onPressed: () =>
                        _renameDepartment(context, ref, department),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: '부서명 수정',
                  ),
                  children: [
                    if (members.isEmpty)
                      const ListTile(
                        dense: true,
                        leading: Icon(Icons.person_off_outlined),
                        title: Text('소속 직원이 없습니다.'),
                      )
                    else
                      ...members.map(
                        (member) => Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Material(
                            color: TheWeColor.surfaceAlt,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: TheWeColor.black300.withValues(
                                  alpha: .3,
                                ),
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: TheWeColor.blueSurface,
                                child: Text(member.name.substring(0, 1)),
                              ),
                              title: Text(
                                member.name,
                                style: TheWeTextStyle.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${member.position} · ${member.id}',
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            if (index != state.departments.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    ),
  );
}

class _BrandingSettingsCard extends ConsumerStatefulWidget {
  const _BrandingSettingsCard({required this.state});

  final ApprovalDashboardState state;

  @override
  ConsumerState<_BrandingSettingsCard> createState() =>
      _BrandingSettingsCardState();
}

class _BrandingSettingsCardState extends ConsumerState<_BrandingSettingsCard> {
  late final TextEditingController portalNameController;

  @override
  void initState() {
    super.initState();
    portalNameController = TextEditingController(text: widget.state.portalName);
  }

  @override
  void didUpdateWidget(covariant _BrandingSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.portalName != widget.state.portalName &&
        portalNameController.text != widget.state.portalName) {
      portalNameController.text = widget.state.portalName;
    }
  }

  @override
  void dispose() {
    portalNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 15 : 22),
      decoration: _adminSurface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TheWeLogo(height: 66, bytes: widget.state.customLogoBytes),
                const SizedBox(height: 12),
                _logoActions(context),
              ],
            )
          else
            Row(
              children: [
                TheWeLogo(height: 76, bytes: widget.state.customLogoBytes),
                const SizedBox(width: 22),
                Expanded(
                  child: Text(
                    widget.state.customLogoFileName ?? '기본 프로젝트 로고 사용 중',
                    style: TheWeTextStyle.body.copyWith(
                      color: TheWeColor.black500,
                    ),
                  ),
                ),
                _logoActions(context),
              ],
            ),
          const SizedBox(height: 18),
          TextField(
            key: const ValueKey('portal-name-field'),
            controller: portalNameController,
            decoration: const InputDecoration(labelText: '임직원 포털 명'),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _savePortalName,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('포털 명 저장'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoActions(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      OutlinedButton.icon(
        key: const ValueKey('portal-logo-upload'),
        onPressed: _pickLogo,
        icon: const Icon(Icons.upload_file_outlined, size: 18),
        label: const Text('로고 변경'),
      ),
      TextButton(
        onPressed: widget.state.customLogoBytes == null
            ? null
            : () => ref
                  .read(approvalDashboardControllerProvider.notifier)
                  .resetPortalLogo(),
        child: const Text('기본 로고'),
      ),
    ],
  );

  Future<void> _pickLogo() async {
    const imageTypes = XTypeGroup(
      label: '로고 이미지',
      extensions: ['png', 'jpg', 'jpeg', 'webp'],
    );
    final file = await openFile(acceptedTypeGroups: [imageTypes]);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final message = ref
        .read(approvalDashboardControllerProvider.notifier)
        .updatePortalLogo(bytes, file.name);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message ?? '로고가 변경되었습니다.')));
  }

  void _savePortalName() {
    if (portalNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('포털 명을 입력해 주세요.')));
      return;
    }
    ref
        .read(approvalDashboardControllerProvider.notifier)
        .updatePortalName(portalNameController.text);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('포털 명이 저장되었습니다.')));
  }
}

class _IntegratedAppSettings extends ConsumerWidget {
  const _IntegratedAppSettings({required this.state});

  final ApprovalDashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const apps = [
      (PortalAppId.approval, '전자결재', Icons.approval_outlined),
      (PortalAppId.attendance, '근태', Icons.schedule_outlined),
      (PortalAppId.leave, '휴가', Icons.beach_access_outlined),
    ];
    return Container(
      decoration: _adminSurface(),
      child: Column(
        children: [
          for (var index = 0; index < apps.length; index++) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 5,
              ),
              leading: Icon(apps[index].$3, color: TheWeColor.blue300),
              title: Text(apps[index].$2, style: TheWeTextStyle.subtitle),
              subtitle: Text(
                apps[index].$1 == PortalAppId.approval
                    ? '${state.activeFormTemplates.length}개 양식 사용 중'
                    : '일반 계정 홈과 메뉴 노출',
              ),
              trailing: Switch(
                key: ValueKey('integrated-app-switch-${apps[index].$1}'),
                value: state.isAppEnabled(apps[index].$1),
                onChanged: (value) => ref
                    .read(approvalDashboardControllerProvider.notifier)
                    .toggleApp(apps[index].$1, value),
              ),
            ),
            if (apps[index].$1 == PortalAppId.approval)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => _showFormManagementDialog(context, ref),
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('전자결재 양식 관리'),
                  ),
                ),
              ),
            if (index != apps.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _SecurityPolicyTile extends StatelessWidget {
  const _SecurityPolicyTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    leading: Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: TheWeColor.blueSurface,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: TheWeColor.blue300),
    ),
    title: Text(title, style: TheWeTextStyle.subtitle),
    subtitle: Text(subtitle),
    trailing: Switch(value: value, onChanged: onChanged),
  );
}

class _AdminPermissionSettings extends ConsumerWidget {
  const _AdminPermissionSettings({required this.state});

  final ApprovalDashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    decoration: _adminSurface(),
    child: Column(
      children: [
        for (var index = 0; index < state.accounts.length; index++) ...[
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundColor: TheWeColor.blueSurface,
              child: Text(state.accounts[index].name.substring(0, 1)),
            ),
            title: Text(
              state.accounts[index].name,
              style: TheWeTextStyle.subtitle,
            ),
            subtitle: Text(
              '${state.accounts[index].department} · ${state.accounts[index].position} · ${state.accounts[index].id}',
            ),
            trailing: Switch(
              key: ValueKey('admin-permission-${state.accounts[index].id}'),
              value: state.accounts[index].isAdmin,
              onChanged:
                  state.currentUser?.id == state.accounts[index].id &&
                      state.accounts[index].isAdmin
                  ? null
                  : (value) {
                      final message = ref
                          .read(approvalDashboardControllerProvider.notifier)
                          .setAdminPermission(state.accounts[index].id, value);
                      if (message != null) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(message)));
                      }
                    },
            ),
          ),
          if (index != state.accounts.length - 1) const Divider(height: 1),
        ],
      ],
    ),
  );
}

class _AnnualLeavePolicyEditor extends ConsumerStatefulWidget {
  const _AnnualLeavePolicyEditor({
    required this.policy,
    required this.monthlyLeavePerMonth,
  });

  final Map<int, int> policy;
  final int monthlyLeavePerMonth;

  @override
  ConsumerState<_AnnualLeavePolicyEditor> createState() =>
      _AnnualLeavePolicyEditorState();
}

class _AnnualLeavePolicyEditorState
    extends ConsumerState<_AnnualLeavePolicyEditor> {
  late final Map<int, TextEditingController> controllers;
  late final TextEditingController monthlyLeaveController;
  bool dirty = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    controllers = {
      for (final entry in widget.policy.entries.where((item) => item.key <= 10))
        entry.key: TextEditingController(text: entry.value.toString()),
    };
    monthlyLeaveController = TextEditingController(
      text: widget.monthlyLeavePerMonth.toString(),
    );
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    monthlyLeaveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Container(
      padding: EdgeInsets.all(mobile ? 15 : 22),
      decoration: _adminSurface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mobile) ...[
            Text(
              '근속연수에 따라 지급할 연차 일수를 입력해 주세요.',
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: dirty ? _save : null,
                icon: const Icon(Icons.save_outlined),
                label: const Text('연차 설정 저장'),
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: Text(
                    '근속연수에 따라 지급할 연차 일수를 입력한 뒤 저장해 주세요.',
                    style: TheWeTextStyle.body.copyWith(
                      color: TheWeColor.black500,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: dirty ? _save : null,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('연차 설정 저장'),
                ),
              ],
            ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('monthly-leave-per-month'),
            controller: monthlyLeaveController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {
              dirty = true;
              error = '';
            }),
            decoration: const InputDecoration(
              labelText: '1년 미만 월차 (매월 지급)',
              suffixText: '일',
              helperText: '입사 후 완료된 근속월마다 설정한 일수가 발생합니다.',
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth < 600
                  ? (constraints.maxWidth - 8) / 2
                  : 150.0;
              return Wrap(
                spacing: mobile ? 8 : 12,
                runSpacing: mobile ? 8 : 12,
                children: controllers.entries
                    .map(
                      (entry) => SizedBox(
                        width: itemWidth,
                        child: TextField(
                          key: ValueKey('annual-leave-${entry.key}'),
                          controller: entry.value,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {
                            dirty = true;
                            error = '';
                          }),
                          decoration: InputDecoration(
                            labelText: '${entry.key}년차',
                            suffixText: '일',
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              error,
              style: TheWeTextStyle.caption.copyWith(color: TheWeColor.danger),
            ),
          ],
        ],
      ),
    );
  }

  void _save() {
    final monthlyDays = int.tryParse(monthlyLeaveController.text.trim());
    if (monthlyDays == null || monthlyDays < 1 || monthlyDays > 31) {
      setState(() => error = '1년 미만 직원의 월차 지급 일수를 확인해 주세요.');
      return;
    }
    final policy = <int, int>{};
    for (final entry in controllers.entries) {
      final days = int.tryParse(entry.value.text.trim());
      if (days == null || days < 1 || days > 365) {
        setState(() => error = '${entry.key}년차 연차 일수를 확인해 주세요.');
        return;
      }
      policy[entry.key] = days;
    }
    final message = ref
        .read(approvalDashboardControllerProvider.notifier)
        .updateAnnualLeavePolicies(policy, monthlyLeavePerMonth: monthlyDays);
    if (message != null) {
      setState(() => error = message);
      return;
    }
    setState(() {
      dirty = false;
      error = '';
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('연차 설정이 저장되었습니다.')));
  }
}

Future<void> _showEmployeeLeaveDirectory(
  BuildContext context,
  ApprovalDashboardState state,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => _EmployeeLeaveBrowserDialog(initialState: state),
  );
}

class _EmployeeLeaveBrowserDialog extends ConsumerStatefulWidget {
  const _EmployeeLeaveBrowserDialog({required this.initialState});

  final ApprovalDashboardState initialState;

  @override
  ConsumerState<_EmployeeLeaveBrowserDialog> createState() =>
      _EmployeeLeaveBrowserDialogState();
}

class _EmployeeLeaveBrowserDialogState
    extends ConsumerState<_EmployeeLeaveBrowserDialog> {
  EmployeeAccount? selected;

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(approvalDashboardControllerProvider).asData?.value ??
        widget.initialState;
    final account = selected;
    if (account == null) {
      return _EmployeeLeaveDirectoryDialog(
        state: state,
        onSelected: (value) => setState(() => selected = value),
      );
    }
    return _EmployeeLeaveOverviewDialog(
      state: state,
      account: account,
      onBack: () => setState(() => selected = null),
      onDirectLeave: () => _showAdminDirectLeaveDialog(context, ref, account),
    );
  }
}

class _EmployeeLeaveDirectoryDialog extends StatelessWidget {
  const _EmployeeLeaveDirectoryDialog({
    required this.state,
    required this.onSelected,
  });

  final ApprovalDashboardState state;
  final ValueChanged<EmployeeAccount> onSelected;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 700;
    return Dialog(
      backgroundColor: TheWeColor.surfaceAlt,
      insetPadding: EdgeInsets.all(mobile ? 12 : 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040, maxHeight: 720),
        child: Padding(
          padding: EdgeInsets.all(mobile ? 16 : 24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('전체 직원 연차 현황', style: TheWeTextStyle.title),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: '닫기',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: mobile
                    ? ListView.separated(
                        itemCount: state.accounts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final account = state.accounts[index];
                          return ListTile(
                            tileColor: TheWeColor.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: TheWeColor.black300.withValues(
                                  alpha: .25,
                                ),
                              ),
                            ),
                            title: Text(account.name),
                            subtitle: Text(
                              '${account.position} · ${account.department}',
                            ),
                            trailing: Text(
                              '${state.isUnderOneYear(account) ? '월차' : '연차'} 잔여 ${_leaveDays(state.remainingAnnualLeaveFor(account))}',
                            ),
                            onTap: () => onSelected(account),
                          );
                        },
                      )
                    : TheWeDataTable(
                        headers: const ['이름', '직급', '부서', '연차 현황'],
                        columnFlexes: const [1.4, 1.1, 1.5, 2.4],
                        minWidth: 860,
                        rows: state.accounts.map((account) {
                          final total = state.totalAnnualLeaveFor(account);
                          final used = state.usedAnnualLeaveFor(account.id);
                          final pending = state.pendingAnnualLeaveFor(
                            account.id,
                          );
                          return <Widget>[
                            TextButton(
                              onPressed: () => onSelected(account),
                              child: Text(account.name),
                            ),
                            Text(account.position),
                            Text(account.department),
                            Text(
                              '${state.isUnderOneYear(account) ? '월차' : '연차'} $total일 · 사용 ${_leaveDays(used)} · 대기 ${_leaveDays(pending)} · 잔여 ${_leaveDays(state.remainingAnnualLeaveFor(account))}',
                              textAlign: TextAlign.center,
                            ),
                          ];
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeeLeaveOverviewDialog extends StatelessWidget {
  const _EmployeeLeaveOverviewDialog({
    required this.state,
    required this.account,
    required this.onBack,
    required this.onDirectLeave,
  });

  final ApprovalDashboardState state;
  final EmployeeAccount account;
  final VoidCallback onBack;
  final VoidCallback onDirectLeave;

  @override
  Widget build(BuildContext context) {
    final requests = state.leaveRequestsFor(account.id);
    final total = state.totalAnnualLeaveFor(account);
    final used = state.usedAnnualLeaveFor(account.id);
    final pending = state.pendingAnnualLeaveFor(account.id);
    final remaining = state.remainingAnnualLeaveFor(account);
    final mobile = MediaQuery.sizeOf(context).width < 700;
    return Dialog(
      backgroundColor: TheWeColor.background,
      insetPadding: EdgeInsets.all(mobile ? 12 : 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1060, maxHeight: 760),
        child: Padding(
          padding: EdgeInsets.all(mobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    key: const ValueKey('employee-leave-back'),
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_ios_new),
                    tooltip: '전체 직원으로 돌아가기',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${account.name} 휴가 현황',
                          style: TheWeTextStyle.title,
                        ),
                        Text(
                          '${account.department} · ${account.position} · 입사일 ${account.hireDate}',
                          style: TheWeTextStyle.caption.copyWith(
                            color: TheWeColor.black500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: mobile ? double.infinity : null,
                child: FilledButton.icon(
                  key: const ValueKey('admin-direct-leave-button'),
                  onPressed: onDirectLeave,
                  icon: const Icon(Icons.event_available_outlined),
                  label: const Text('휴가 직접 등록'),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _EmployeeLeaveMetric(
                    label: state.leaveEntitlementLabelFor(account),
                    value: '$total일',
                  ),
                  _EmployeeLeaveMetric(
                    label: state.leaveUsedLabelFor(account),
                    value: _leaveDays(used),
                  ),
                  _EmployeeLeaveMetric(
                    label: state.leaveRemainingLabelFor(account),
                    value: _leaveDays(remaining),
                  ),
                  _EmployeeLeaveMetric(
                    label: '승인 대기',
                    value: _leaveDays(pending),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text('휴가 신청 내역', style: TheWeTextStyle.subtitle),
              const SizedBox(height: 10),
              Expanded(
                child: requests.isEmpty
                    ? const Center(child: Text('휴가 신청 내역이 없습니다.'))
                    : ListView.separated(
                        itemCount: requests.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final request = requests[index];
                          return Container(
                            padding: const EdgeInsets.all(13),
                            decoration: _adminSurface(),
                            child: Row(
                              children: [
                                Chip(
                                  label: Text(
                                    request.directEntry
                                        ? '관리자 등록'
                                        : request.status,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${request.type} · ${request.startDate} ~ ${request.endDate}\n${request.reason}${request.directEntry ? ' · 등록자 ${request.registeredBy}' : ''}',
                                  ),
                                ),
                                Text(_leaveDays(request.days)),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminDirectLeaveDraft {
  const _AdminDirectLeaveDraft({
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.reason,
  });

  final String type;
  final String startDate;
  final String endDate;
  final double days;
  final String reason;
}

Future<void> _showAdminDirectLeaveDialog(
  BuildContext context,
  WidgetRef ref,
  EmployeeAccount account,
) async {
  final current = ref.read(approvalDashboardControllerProvider).requireValue;
  final isMonthly = current.isUnderOneYear(account);
  final types = isMonthly
      ? const ['월차', '반차', '경조 휴가', '휴가']
      : const ['연차', '반차', '경조 휴가', '휴가'];
  var type = types.first;
  var start = DateTime.now();
  var end = start;
  var reason = '';
  var error = '';

  final draft = await showDialog<_AdminDirectLeaveDraft>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final halfDay = type == '반차';

        Future<void> pickDate(bool startDate) async {
          final picked = await showDatePicker(
            context: context,
            initialDate: startDate ? start : end,
            firstDate: DateTime(2000),
            lastDate: DateTime(DateTime.now().year + 2, 12, 31),
          );
          if (picked == null) return;
          setDialogState(() {
            error = '';
            if (startDate) {
              start = picked;
              if (end.isBefore(start) || halfDay) end = start;
            } else {
              end = picked;
            }
          });
        }

        return AlertDialog(
          backgroundColor: TheWeColor.surfaceAlt,
          title: Text('${account.name} 휴가 직접 등록'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '별도 결재 없이 즉시 승인 완료 처리되며 잔여 휴가에서 차감됩니다.',
                    style: TheWeTextStyle.caption.copyWith(
                      color: TheWeColor.black500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TheWeDropdown<String>(
                    value: type,
                    width: double.infinity,
                    items: types,
                    labelBuilder: (value) => value,
                    onChanged: (value) => setDialogState(() {
                      type = value ?? types.first;
                      if (type == '반차') end = start;
                      error = '';
                    }),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => pickDate(true),
                          icon: const Icon(Icons.event_outlined),
                          label: Text(DateFormat('yyyy-MM-dd').format(start)),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('~'),
                      ),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: halfDay ? null : () => pickDate(false),
                          icon: const Icon(Icons.event_outlined),
                          label: Text(DateFormat('yyyy-MM-dd').format(end)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('admin-direct-leave-reason'),
                    maxLines: 3,
                    onChanged: (value) {
                      reason = value;
                      if (error.isNotEmpty) {
                        setDialogState(() => error = '');
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: '관리자 등록 사유 (필수)',
                      hintText: '결재 없이 반영하는 사유를 입력하세요.',
                    ),
                  ),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      error,
                      style: TheWeTextStyle.caption.copyWith(
                        color: TheWeColor.danger,
                      ),
                    ),
                  ],
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
              key: const ValueKey('admin-direct-leave-submit'),
              onPressed: () {
                final days = halfDay ? .5 : end.difference(start).inDays + 1.0;
                if (reason.trim().isEmpty) {
                  setDialogState(() => error = '관리자 등록 사유를 입력해 주세요.');
                  return;
                }
                if (days > current.remainingAnnualLeaveFor(account)) {
                  setDialogState(
                    () => error =
                        '잔여 휴가 ${_leaveDays(current.remainingAnnualLeaveFor(account))}를 초과했습니다.',
                  );
                  return;
                }
                Navigator.pop(
                  context,
                  _AdminDirectLeaveDraft(
                    type: type,
                    startDate: DateFormat('yyyy-MM-dd').format(start),
                    endDate: DateFormat(
                      'yyyy-MM-dd',
                    ).format(halfDay ? start : end),
                    days: days,
                    reason: reason.trim(),
                  ),
                );
              },
              child: const Text('즉시 반영'),
            ),
          ],
        );
      },
    ),
  );
  if (draft == null || !context.mounted) return;
  final message = ref
      .read(approvalDashboardControllerProvider.notifier)
      .addLeaveForEmployee(
        userId: account.id,
        type: draft.type,
        startDate: draft.startDate,
        endDate: draft.endDate,
        days: draft.days,
        reason: draft.reason,
      );
  if (!context.mounted) return;
  if (message != null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${account.name}님의 휴가가 즉시 반영되었습니다.')),
    );
  }
}

class _EmployeeLeaveMetric extends StatelessWidget {
  const _EmployeeLeaveMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: 150,
    padding: const EdgeInsets.all(14),
    decoration: _adminSurface(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
        ),
        const SizedBox(height: 5),
        Text(value, style: TheWeTextStyle.subtitle),
      ],
    ),
  );
}

String _leaveDays(double value) => value == value.roundToDouble()
    ? '${value.toInt()}일'
    : '${value.toStringAsFixed(1)}일';

class _AdminMetric extends StatelessWidget {
  const _AdminMetric({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });
  final double width;
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final compact = width < 220;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: width,
          padding: EdgeInsets.all(compact ? 13 : 20),
          decoration: _adminSurface(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: TheWeColor.blue300,
                    size: compact ? 22 : 24,
                  ),
                  if (onTap != null) ...[
                    const Spacer(),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ],
              ),
              SizedBox(height: compact ? 9 : 16),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TheWeTextStyle.caption.copyWith(
                  color: TheWeColor.black500,
                  fontSize: compact ? 12 : null,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: compact
                    ? TheWeTextStyle.metric.copyWith(fontSize: 24)
                    : TheWeTextStyle.metric,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _adminSurface() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: TheWeColor.black300.withValues(alpha: .22)),
  boxShadow: const [
    BoxShadow(color: Color(0x08000000), blurRadius: 18, offset: Offset(0, 8)),
  ],
);

Future<String?> _requestOtp(BuildContext context) async {
  final controller = TextEditingController();
  final mobile = MediaQuery.sizeOf(context).width < 600;
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: mobile ? 22 : 40,
        vertical: 24,
      ),
      backgroundColor: Colors.white,
      title: const Text('OTP 2차 인증'),
      content: SizedBox(
        width: mobile ? double.maxFinite : 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('관리자 OTP 앱에 표시된 6자리 번호를 입력하세요.'),
            const SizedBox(height: 6),
            Text(
              '프로토타입 인증번호: 123456',
              style: TheWeTextStyle.caption.copyWith(color: TheWeColor.blue300),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'OTP 인증번호'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('인증'),
        ),
      ],
    ),
  );
}
