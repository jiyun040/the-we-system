part of 'approval_providers.dart';

extension ApprovalDashboardAdminActions on ApprovalDashboardController {
  bool verifyAdminOtp(String otp) => otp.trim() == '123456';

  bool enterAdminMode(String otp) {
    final current = _currentState;
    if (current?.currentUser?.isAdmin != true || !verifyAdminOtp(otp)) {
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
          isAdmin: isAdmin,
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
      isAdmin: isAdmin,
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

  void updateAnnualLeavePolicy(int year, int days) {
    _setDashboardState(
      this,
      (value) => value.copyWith(
        annualLeaveByYear: {...value.annualLeaveByYear, year: days},
      ),
    );
  }

  String? updateAnnualLeavePolicies(Map<int, int> policies) {
    if (policies.isEmpty) return '저장할 연차 설정이 없습니다.';
    if (policies.values.any((days) => days < 1 || days > 365)) {
      return '연차 일수는 1일 이상 365일 이하로 입력해 주세요.';
    }
    _setDashboardState(
      this,
      (value) => value.copyWith(annualLeaveByYear: {...policies}),
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
                  ? request.copyWith(status: status)
                  : request,
            )
            .toList(),
      ),
    );
  }
}
