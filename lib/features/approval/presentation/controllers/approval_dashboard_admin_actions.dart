import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_controller_models.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_provider_helpers.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';

extension ApprovalDashboardAdminActions on ApprovalDashboardController {
  void syncRemote(Future<void> Function() operation) {
    if (!usesRemoteApi) return;
    unawaited(
      operation().then((_) => reloadRemoteState()).catchError((Object error) {
        debugPrint('서버 동기화 실패: $error');
      }),
    );
  }

  bool verifyAdminOtp(String otp) => otp.trim() == '123456';

  Future<bool> enterAdminMode(String otp) async {
    final current = currentDashboardState;
    if (current == null ||
        current.currentUser?.id != 'edu_manager' ||
        current.currentUser?.isAdmin != true ||
        (current.adminOtpEnabled &&
            (usesRemoteApi
                ? !await api.verifyAdminOtp(otp)
                : !verifyAdminOtp(otp)))) {
      return false;
    }
    setApprovalDashboardState(this, (value) => value.copyWith(adminMode: true));
    return true;
  }

  void leaveAdminMode() {
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(adminMode: false),
    );
  }

  Future<bool> verifyCurrentPassword(String password) async {
    if (usesRemoteApi) return api.verifyPassword(password);
    return currentDashboardState?.currentUser?.password == password;
  }

  void updateEmployee({
    required String userId,
    required String department,
    required String position,
    required String hireDate,
    String? password,
    bool? isAdmin,
  }) {
    setApprovalDashboardState(this, (value) {
      final accounts = value.accounts.map((account) {
        if (account.id != userId) return account;
        return account.copyWith(
          department: department.trim(),
          position: position.trim(),
          hireDate: hireDate.trim(),
          password: password?.trim().isEmpty == true ? null : password?.trim(),
          isAdmin: account.id == 'edu_manager',
        );
      }).toList();
      final currentUser = value.currentUser?.id == userId
          ? accounts.where((account) => account.id == userId).first
          : value.currentUser;
      return value.copyWith(accounts: accounts, currentUser: currentUser);
    });
    syncRemote(
      () => api.updateEmployee(userId, {
        'department': department.trim(),
        'position': position.trim(),
        'hireDate': hireDate.trim(),
        if (password?.trim().isNotEmpty == true) 'password': password!.trim(),
      }),
    );
  }

  String? addEmployee({
    required String id,
    required String password,
    required String name,
    required String department,
    required String position,
    required String email,
    required String hireDate,
    required bool isAdmin,
  }) {
    final current = currentDashboardState;
    if (current == null) return '직원 정보를 불러오지 못했습니다.';
    final normalizedId = id.trim();
    final normalizedEmail = email.trim();
    if ([
      normalizedId,
      password.trim(),
      name.trim(),
      department.trim(),
      position.trim(),
      normalizedEmail,
      hireDate.trim(),
    ].any((value) => value.isEmpty)) {
      return '모든 항목을 입력해 주세요.';
    }
    if (current.accounts.any((account) => account.id == normalizedId)) {
      return '이미 사용 중인 아이디입니다.';
    }
    if (current.accounts.any((account) => account.email == normalizedEmail)) {
      return '이미 사용 중인 이메일입니다.';
    }
    if (DateTime.tryParse(hireDate.trim()) == null) {
      return '입사일을 YYYY-MM-DD 형식으로 입력해 주세요.';
    }
    final account = EmployeeAccount(
      id: normalizedId,
      password: password.trim(),
      name: name.trim(),
      department: department.trim(),
      position: position.trim(),
      email: normalizedEmail,
      hireDate: hireDate.trim(),
      isAdmin: false,
    );
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(accounts: [...value.accounts, account]),
    );
    syncRemote(
      () => api.createEmployee({
        'id': normalizedId,
        'password': password.trim(),
        'name': name.trim(),
        'department': department.trim(),
        'position': position.trim(),
        'email': normalizedEmail,
        'hireDate': hireDate.trim(),
      }),
    );
    return null;
  }

  void toggleApp(String appId, bool enabled) {
    setApprovalDashboardState(this, (value) {
      final enabledIds = {...value.enabledAppIds};
      if (enabled) {
        enabledIds.add(appId);
      } else {
        enabledIds.remove(appId);
      }
      return value.copyWith(enabledAppIds: enabledIds);
    });
    final enabledIds = {...?currentDashboardState?.enabledAppIds};
    if (enabled) {
      enabledIds.add(appId);
    } else {
      enabledIds.remove(appId);
    }
    syncRemote(
      () => api.updateSettings({'enabledAppIds': enabledIds.toList()}),
    );
  }

  void toggleFormTemplate(String templateId, bool enabled) {
    setApprovalDashboardState(this, (value) {
      final disabledIds = {...value.disabledFormTemplateIds};
      if (enabled) {
        disabledIds.remove(templateId);
      } else {
        disabledIds.add(templateId);
      }
      return value.copyWith(disabledFormTemplateIds: disabledIds);
    });
    syncRemote(() => api.setFormEnabled(templateId, enabled));
  }

  String? saveFormTemplate({
    String? templateId,
    required String category,
    required String name,
    required String description,
    required String defaultTitle,
    required String defaultContent,
    String documentLayout = ApprovalDocumentLayout.basic,
    int lineItemRows = 8,
  }) {
    final current = currentDashboardState;
    if (current == null) return '양식 정보를 불러오지 못했습니다.';
    if ([
      category,
      name,
      description,
      defaultTitle,
      defaultContent,
    ].any((value) => value.trim().isEmpty)) {
      return '모든 항목을 입력해 주세요.';
    }

    final templates = [...current.formTemplates];
    if (templateId == null) {
      final nextId = 'custom-${DateTime.now().microsecondsSinceEpoch}';
      templates.add(
        ApprovalFormTemplate(
          id: nextId,
          category: category.trim(),
          name: name.trim(),
          description: description.trim(),
          defaultTitle: defaultTitle.trim(),
          defaultContent: defaultContent.trim(),
          receivers: const [],
          references: const [],
          viewers: const [],
          publicReceivers: const [],
          cooperationDepartment: '',
          agreement: '',
          documentLayout: documentLayout,
          lineItemRows: lineItemRows,
        ),
      );
    } else {
      final index = templates.indexWhere((item) => item.id == templateId);
      if (index < 0) return '수정할 양식을 찾지 못했습니다.';
      templates[index] = templates[index].copyWith(
        category: category.trim(),
        name: name.trim(),
        description: description.trim(),
        defaultTitle: defaultTitle.trim(),
        defaultContent: defaultContent.trim(),
        documentLayout: documentLayout,
        lineItemRows: lineItemRows,
      );
    }
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(formTemplates: templates),
    );
    final saved = currentDashboardState?.formTemplates
        .where(
          (item) =>
              item.id == templateId ||
              (templateId == null && item.name == name.trim()),
        )
        .lastOrNull;
    syncRemote(
      () => api.saveForm(
        id: templateId,
        data: {
          if (saved != null && templateId == null) 'id': saved.id,
          'category': category.trim(),
          'name': name.trim(),
          'description': description.trim(),
          'defaultTitle': defaultTitle.trim(),
          'defaultContent': defaultContent.trim(),
          'documentLayout': documentLayout,
          'lineItemRows': lineItemRows,
        },
      ),
    );
    return null;
  }

  void deleteFormTemplate(String templateId) {
    setApprovalDashboardState(this, (value) {
      final disabledIds = {...value.disabledFormTemplateIds}
        ..remove(templateId);
      return value.copyWith(
        formTemplates: value.formTemplates
            .where((template) => template.id != templateId)
            .toList(),
        frequentForms: value.frequentForms
            .where((form) => form.id != templateId)
            .toList(),
        disabledFormTemplateIds: disabledIds,
      );
    });
    syncRemote(() => api.deleteForm(templateId));
  }

  void updatePortalName(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) return;
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(portalName: normalized),
    );
    syncRemote(() => api.updateSettings({'portalName': normalized}));
  }

  String? updatePortalLogo(Uint8List bytes, String fileName) {
    if (bytes.isEmpty) return '선택한 로고 파일을 읽을 수 없습니다.';
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      return '로고 파일은 5MB 이하만 사용할 수 있습니다.';
    }
    setApprovalDashboardState(
      this,
      (value) =>
          value.copyWith(customLogoBytes: bytes, customLogoFileName: fileName),
    );
    syncRemote(
      () => api.updateSettings({
        'customLogoBase64': base64Encode(bytes),
        'customLogoFileName': fileName,
      }),
    );
    return null;
  }

  void resetPortalLogo() {
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(clearCustomLogo: true),
    );
    syncRemote(
      () => api.updateSettings({
        'customLogoBase64': '',
        'customLogoFileName': '',
      }),
    );
  }

  void updateSecurityPolicy({
    bool? adminOtpEnabled,
    bool? settingsPasswordEnabled,
    bool? adminDocumentAccessEnabled,
  }) {
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(
        adminOtpEnabled: adminOtpEnabled,
        settingsPasswordEnabled: settingsPasswordEnabled,
        adminDocumentAccessEnabled: adminDocumentAccessEnabled,
      ),
    );
    syncRemote(
      () => api.updateSettings({
        'adminOtpEnabled': ?adminOtpEnabled,
        'settingsPasswordEnabled': ?settingsPasswordEnabled,
        'adminDocumentAccessEnabled': ?adminDocumentAccessEnabled,
      }),
    );
  }

  void updateDocumentCategoryAccess({
    required String category,
    required bool organizationWide,
    required Set<String> userIds,
  }) {
    final current = currentDashboardState;
    if (current == null ||
        !current.formTemplates.any(
          (template) => template.category == category,
        )) {
      return;
    }
    setApprovalDashboardState(this, (value) {
      final wideCategories = {...value.organizationWideDocumentCategories};
      if (organizationWide) {
        wideCategories.add(category);
      } else {
        wideCategories.remove(category);
      }
      return value.copyWith(
        organizationWideDocumentCategories: wideCategories,
        documentCategoryViewerIds: {
          ...value.documentCategoryViewerIds,
          category: {...userIds},
        },
      );
    });
    final latest = currentDashboardState;
    final viewerIds =
        latest?.documentCategoryViewerIds ?? const <String, Set<String>>{};
    syncRemote(
      () => api.updateSettings({
        'organizationWideDocumentCategories':
            latest?.organizationWideDocumentCategories.toList() ?? const [],
        'documentCategoryViewerIds': {
          for (final entry in viewerIds.entries)
            entry.key: entry.value.toList(),
        },
      }),
    );
  }

  String? setAdminPermission(String userId, bool enabled) {
    return userId == 'edu_manager' && enabled
        ? null
        : '관리자 권한은 전용 관리자 계정에서만 사용할 수 있습니다.';
  }

  String? renameDepartment(String currentName, String nextName) {
    final normalized = nextName.trim();
    if (normalized.isEmpty) return '변경할 부서명을 입력해 주세요.';
    final current = currentDashboardState;
    if (current == null) return '조직 정보를 불러오지 못했습니다.';
    if (normalized != currentName &&
        current.accounts.any((account) => account.department == normalized)) {
      return '이미 사용 중인 부서명입니다.';
    }
    final accounts = current.accounts
        .map(
          (account) => account.department == currentName
              ? account.copyWith(department: normalized)
              : account,
        )
        .toList();
    final currentUser = current.currentUser == null
        ? null
        : accounts
              .where((account) => account.id == current.currentUser!.id)
              .first;
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(
        accounts: accounts,
        currentUser: currentUser,
        selectedOrgDepartment: value.selectedOrgDepartment == currentName
            ? normalized
            : value.selectedOrgDepartment,
      ),
    );
    syncRemote(() => api.renameDepartment(currentName, normalized));
    return null;
  }

  void updateAnnualLeavePolicy(int year, int days) {
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(
        annualLeaveByYear: {...value.annualLeaveByYear, year: days},
      ),
    );
    final policy =
        currentDashboardState?.annualLeaveByYear ?? const <int, int>{};
    syncRemote(
      () => api.updateSettings({
        'annualLeaveByYear': {
          for (final entry in policy.entries) '${entry.key}': entry.value,
        },
      }),
    );
  }

  String? updateAnnualLeavePolicies(
    Map<int, int> policies, {
    int? monthlyLeavePerMonth,
  }) {
    if (policies.isEmpty) return '저장할 연차 설정이 없습니다.';
    if (policies.values.any((days) => days < 1 || days > 365)) {
      return '연차 일수는 1일 이상 365일 이하로 입력해 주세요.';
    }
    if (monthlyLeavePerMonth != null &&
        (monthlyLeavePerMonth < 1 || monthlyLeavePerMonth > 31)) {
      return '월차 지급 일수는 1일 이상 31일 이하로 입력해 주세요.';
    }
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(
        annualLeaveByYear: {...policies},
        monthlyLeavePerMonth: monthlyLeavePerMonth,
      ),
    );
    syncRemote(
      () => api.updateSettings({
        'annualLeaveByYear': {
          for (final entry in policies.entries) '${entry.key}': entry.value,
        },
        'monthlyLeavePerMonth': ?monthlyLeavePerMonth,
      }),
    );
    return null;
  }

  String? addLeaveForEmployee({
    required String userId,
    required String type,
    required String startDate,
    required String endDate,
    required double days,
    required String reason,
  }) {
    final current = currentDashboardState;
    if (current == null || !current.isAdminMode) {
      return '관리자 모드에서만 휴가를 직접 등록할 수 있습니다.';
    }
    final account = current.accounts
        .where((item) => item.id == userId)
        .firstOrNull;
    if (account == null) return '직원 정보를 찾을 수 없습니다.';
    if (reason.trim().isEmpty) return '관리자 등록 사유를 입력해 주세요.';
    final parsedStart = DateTime.tryParse(startDate);
    final parsedEnd = DateTime.tryParse(endDate);
    if (parsedStart == null ||
        parsedEnd == null ||
        parsedEnd.isBefore(parsedStart)) {
      return '휴가 날짜를 확인해 주세요.';
    }
    if (days <= 0) return '사용 일수를 확인해 주세요.';
    final remaining = current.remainingAnnualLeaveFor(account);
    if (days > remaining) {
      return '잔여 휴가 ${remaining.toStringAsFixed(remaining == remaining.roundToDouble() ? 0 : 1)}일을 초과했습니다.';
    }
    final request = LeaveRequest(
      id: 'LEAVE-${DateTime.now().microsecondsSinceEpoch}',
      userId: userId,
      type: type,
      startDate: startDate,
      endDate: endDate,
      days: days,
      reason: reason.trim(),
      status: '승인완료',
      ceoStatus: '완료',
      directEntry: true,
      registeredBy: current.currentUser!.name,
    );
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(
        leaveRequests: [request, ...value.leaveRequests],
        acknowledgedLeaveRequestIds: {
          ...value.acknowledgedLeaveRequestIds,
          request.id,
        },
      ),
    );
    syncRemote(
      () => api.createLeave(
        userId: userId,
        type: type,
        startDate: startDate,
        endDate: endDate,
        days: days,
        reason: reason.trim(),
        directEntry: true,
      ),
    );
    return null;
  }

  void requestLeave({
    required String type,
    required String startDate,
    required String endDate,
    required double days,
    required String reason,
  }) {
    final current = currentDashboardState;
    final user = current?.currentUser;
    if (current == null || user == null) return;
    final request = LeaveRequest(
      id: 'LEAVE-${current.leaveRequests.length + 1}',
      userId: user.id,
      type: type,
      startDate: startDate,
      endDate: endDate,
      days: days,
      reason: reason,
    );
    final ceo = current.accounts
        .where((account) => account.id == 'ceo')
        .firstOrNull;
    final document = ApprovalDocument(
      id: 'LEAVE-DOC-${request.id}',
      title: '${user.name} $type 신청',
      drafter: user.name,
      department: user.department,
      form: '휴가 신청서',
      status: '결재대기',
      draftedAt: approvalToday(),
      dueDate: startDate,
      progress: 50,
      documentNo:
          'LEAVE-${approvalToday().replaceAll('-', '')}-${current.leaveRequests.length + 1}',
      effectiveDate: startDate,
      content:
          '휴가 종류: $type\n기간: $startDate ~ $endDate\n사용 일수: $days일\n신청 사유: $reason',
      receivedRequest: true,
      canCancel: false,
      canReuse: false,
      canEdit: false,
      receivers: const ['대표'],
      references: const ['경영관리팀'],
      steps: [
        ApprovalStep(
          name: user.name,
          department: user.department,
          type: '신청',
          role: user.position,
          status: '완료',
          approvedAt: '${approvalToday()} 09:00',
        ),
        ApprovalStep(
          name: ceo?.name ?? '조상훈',
          department: ceo?.department ?? '경영관리팀',
          type: '승인',
          role: ceo?.position ?? '대표',
          status: '진행중',
        ),
      ],
      histories: [
        ApprovalHistory(
          id: 'HIS-${request.id}',
          category: '휴가 신청',
          date: '${approvalToday()} 09:00',
          user: '${user.name} ${user.position}',
          description: '휴가 신청 결재 요청',
          snapshot: '$type · $startDate ~ $endDate',
        ),
      ],
    );
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(
        leaveRequests: [request, ...value.leaveRequests],
        documents: [document, ...value.documents],
      ),
    );
    syncRemote(
      () => api.createLeave(
        type: type,
        startDate: startDate,
        endDate: endDate,
        days: days,
        reason: reason,
      ),
    );
  }

  void updateLeaveStatus(String requestId, String status) {
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(
        leaveRequests: value.leaveRequests
            .map(
              (request) => request.id == requestId
                  ? request.copyWith(
                      status: status,
                      ceoStatus: status == '승인완료' ? '완료' : request.ceoStatus,
                    )
                  : request,
            )
            .toList(),
        documents: value.documents
            .map(
              (document) => document.id == 'LEAVE-DOC-$requestId'
                  ? _resolvedLeaveDocument(document, status)
                  : document,
            )
            .toList(),
      ),
    );
    if (status == '승인완료' || status == '반려') {
      syncRemote(() => api.actOnLeave(requestId, approve: status == '승인완료'));
    }
  }

  bool actOnLeave(String requestId, {required bool approve}) {
    final current = currentDashboardState;
    final user = current?.currentUser;
    if (current == null || user == null) return false;
    final request = current.leaveRequests
        .where((item) => item.id == requestId)
        .firstOrNull;
    if (request == null || !current.canActOnLeave(request)) return false;

    late LeaveRequest updated;
    if (!approve) {
      updated = request.copyWith(
        status: '반려',
        ceoStatus: request.ceoStatus == '진행중' ? '반려' : request.ceoStatus,
        rejectedBy: user.name,
      );
    } else {
      updated = request.copyWith(status: '승인완료', ceoStatus: '완료');
    }

    setApprovalDashboardState(
      this,
      (value) => value.copyWith(
        leaveRequests: value.leaveRequests
            .map((item) => item.id == requestId ? updated : item)
            .toList(),
        documents: value.documents
            .map(
              (document) => document.id == 'LEAVE-DOC-$requestId'
                  ? _resolvedLeaveDocument(document, approve ? '승인완료' : '반려')
                  : document,
            )
            .toList(),
      ),
    );
    syncRemote(() => api.actOnLeave(requestId, approve: approve));
    return true;
  }

  void acknowledgeApprovedLeaves([Iterable<String>? requestIds]) {
    final targets =
        requestIds?.toSet() ??
        currentDashboardState?.unacknowledgedApprovedLeaveRequests
            .map((request) => request.id)
            .toSet() ??
        const <String>{};
    setApprovalDashboardState(this, (value) {
      final targets =
          requestIds?.toSet() ??
          value.unacknowledgedApprovedLeaveRequests
              .map((request) => request.id)
              .toSet();
      return value.copyWith(
        acknowledgedLeaveRequestIds: {
          ...value.acknowledgedLeaveRequestIds,
          ...targets,
        },
      );
    });
    for (final id in targets) {
      syncRemote(() => api.acknowledgeLeave(id));
    }
  }
}

ApprovalDocument _resolvedLeaveDocument(
  ApprovalDocument document,
  String leaveStatus,
) {
  final approved = leaveStatus == '승인완료';
  final rejected = leaveStatus == '반려';
  if (!approved && !rejected) return document;
  final steps = document.steps
      .map(
        (step) => step.status == '진행중'
            ? step.copyWith(
                status: approved ? '완료' : '반려',
                approvedAt: '${approvalToday()} 09:30',
              )
            : step,
      )
      .toList();
  return document.copyWith(
    status: approved ? '완료' : '반려',
    progress: approved ? 100 : approvalProgressFor(steps),
    steps: steps,
  );
}
