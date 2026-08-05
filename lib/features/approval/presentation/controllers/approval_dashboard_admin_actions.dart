part of 'approval_providers.dart';

extension ApprovalDashboardAdminActions on ApprovalDashboardController {
  bool verifyAdminOtp(String otp) => otp.trim() == '123456';

  bool enterAdminMode(String otp) {
    final current = _currentState;
    if (current == null ||
        current.currentUser?.id != 'edu_manager' ||
        current.currentUser?.isAdmin != true ||
        (current.adminOtpEnabled && !verifyAdminOtp(otp))) {
      return false;
    }
    _setDashboardState(this, (value) => value.copyWith(adminMode: true));
    return true;
  }

  void leaveAdminMode() {
    _setDashboardState(this, (value) => value.copyWith(adminMode: false));
  }

  bool verifyCurrentPassword(String password) {
    return _currentState?.currentUser?.password == password;
  }

  void updateEmployee({
    required String userId,
    required String department,
    required String position,
    required String hireDate,
    String? password,
    bool? isAdmin,
  }) {
    _setDashboardState(this, (value) {
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
    final current = _currentState;
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
    _setDashboardState(
      this,
      (value) => value.copyWith(accounts: [...value.accounts, account]),
    );
    return null;
  }

  void toggleApp(String appId, bool enabled) {
    _setDashboardState(this, (value) {
      final enabledIds = {...value.enabledAppIds};
      if (enabled) {
        enabledIds.add(appId);
      } else {
        enabledIds.remove(appId);
      }
      return value.copyWith(enabledAppIds: enabledIds);
    });
  }

  void toggleFormTemplate(String templateId, bool enabled) {
    _setDashboardState(this, (value) {
      final disabledIds = {...value.disabledFormTemplateIds};
      if (enabled) {
        disabledIds.remove(templateId);
      } else {
        disabledIds.add(templateId);
      }
      return value.copyWith(disabledFormTemplateIds: disabledIds);
    });
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
    final current = _currentState;
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
    _setDashboardState(
      this,
      (value) => value.copyWith(formTemplates: templates),
    );
    return null;
  }

  void deleteFormTemplate(String templateId) {
    _setDashboardState(this, (value) {
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
  }

  void updatePortalName(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) return;
    _setDashboardState(this, (value) => value.copyWith(portalName: normalized));
  }

  String? updatePortalLogo(Uint8List bytes, String fileName) {
    if (bytes.isEmpty) return '선택한 로고 파일을 읽을 수 없습니다.';
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      return '로고 파일은 5MB 이하만 사용할 수 있습니다.';
    }
    _setDashboardState(
      this,
      (value) =>
          value.copyWith(customLogoBytes: bytes, customLogoFileName: fileName),
    );
    return null;
  }

  void resetPortalLogo() {
    _setDashboardState(this, (value) => value.copyWith(clearCustomLogo: true));
  }

  void updateSecurityPolicy({
    bool? adminOtpEnabled,
    bool? settingsPasswordEnabled,
    bool? adminDocumentAccessEnabled,
  }) {
    _setDashboardState(
      this,
      (value) => value.copyWith(
        adminOtpEnabled: adminOtpEnabled,
        settingsPasswordEnabled: settingsPasswordEnabled,
        adminDocumentAccessEnabled: adminDocumentAccessEnabled,
      ),
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
    final current = _currentState;
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
    _setDashboardState(
      this,
      (value) => value.copyWith(
        accounts: accounts,
        currentUser: currentUser,
        selectedOrgDepartment: value.selectedOrgDepartment == currentName
            ? normalized
            : value.selectedOrgDepartment,
      ),
    );
    return null;
  }

  void updateAnnualLeavePolicy(int year, int days) {
    _setDashboardState(
      this,
      (value) => value.copyWith(
        annualLeaveByYear: {...value.annualLeaveByYear, year: days},
      ),
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
    _setDashboardState(
      this,
      (value) => value.copyWith(
        annualLeaveByYear: {...policies},
        monthlyLeavePerMonth: monthlyLeavePerMonth,
      ),
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
    final current = _currentState;
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
    _setDashboardState(
      this,
      (value) => value.copyWith(
        leaveRequests: [request, ...value.leaveRequests],
        acknowledgedLeaveRequestIds: {
          ...value.acknowledgedLeaveRequestIds,
          request.id,
        },
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
    final current = _currentState;
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
    _setDashboardState(
      this,
      (value) =>
          value.copyWith(leaveRequests: [request, ...value.leaveRequests]),
    );
  }

  void updateLeaveStatus(String requestId, String status) {
    _setDashboardState(
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
      ),
    );
  }

  bool actOnLeave(String requestId, {required bool approve}) {
    final current = _currentState;
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

    _setDashboardState(
      this,
      (value) => value.copyWith(
        leaveRequests: value.leaveRequests
            .map((item) => item.id == requestId ? updated : item)
            .toList(),
      ),
    );
    return true;
  }

  void acknowledgeApprovedLeaves([Iterable<String>? requestIds]) {
    _setDashboardState(this, (value) {
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
  }
}
