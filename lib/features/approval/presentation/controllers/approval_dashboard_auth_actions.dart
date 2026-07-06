part of 'approval_providers.dart';

extension ApprovalDashboardAuthActions on ApprovalDashboardController {
  void updateKeyword(String keyword) {
    _setDashboardState(this, (current) => current.copyWith(keyword: keyword));
  }

  Future<void> refresh() async {
    _setDashboardState(this, (current) => current);
  }

  Future<bool> login(String id, String password) async {
    final current = _currentState;
    if (current == null) {
      return false;
    }

    final account = current.accounts
        .where((item) => item.id == id && item.password == password)
        .firstOrNull;
    if (account == null) {
      _setDashboardState(
        this,
        (value) => value.copyWith(loginError: '아이디 또는 비밀번호를 확인해 주세요.'),
      );
      return false;
    }

    _setDashboardState(
      this,
      (value) => value.copyWith(
        currentUser: account,
        loginError: '',
        keyword: '',
        selectedOrgDepartment: account.department,
        selectedOrgUserId: account.id,
      ),
    );
    return true;
  }

  Future<String?> registerAccount({
    required String id,
    required String password,
    required String name,
    required String department,
    required String position,
    required String email,
    required bool isAdmin,
  }) async {
    final current = _currentState;
    if (current == null) {
      return '회원가입 상태를 불러오지 못했습니다.';
    }

    final normalizedId = id.trim();
    final normalizedEmail = email.trim().toLowerCase();
    if (current.accounts.any((item) => item.id == normalizedId)) {
      return '이미 사용 중인 아이디입니다.';
    }
    if (current.accounts.any(
      (item) => item.email.toLowerCase() == normalizedEmail,
    )) {
      return '이미 사용 중인 이메일입니다.';
    }

    final newAccount = EmployeeAccount(
      id: normalizedId,
      password: password,
      name: name.trim(),
      department: department.trim(),
      position: position.trim(),
      email: normalizedEmail,
      isAdmin: isAdmin,
    );

    final accounts = [...current.accounts, newAccount]
      ..sort((a, b) => a.name.compareTo(b.name));

    _setDashboardState(
      this,
      (value) => value.copyWith(
        accounts: accounts,
        loginError: '',
        selectedOrgDepartment: value.selectedOrgDepartment.isEmpty
            ? newAccount.department
            : value.selectedOrgDepartment,
        selectedOrgUserId: value.selectedOrgUserId ?? newAccount.id,
      ),
    );
    return null;
  }

  void logout() {
    _setDashboardState(
      this,
      (current) => current.copyWith(
        clearCurrentUser: true,
        loginError: '',
        keyword: '',
        selectedOrgDepartment: current.accounts.first.department,
        selectedOrgUserId: current.accounts.first.id,
      ),
    );
  }

  void clearLoginError() {
    _setDashboardState(this, (current) => current.copyWith(loginError: ''));
  }

  void adjustZoom(double delta) {
    _setDashboardState(this, (current) {
      final next = (current.zoom + delta).clamp(0.85, 1.55);
      return current.copyWith(zoom: next);
    });
  }

  void setDepartment(String department) {
    _setDashboardState(this, (current) {
      final members =
          current.accounts
              .where((account) => account.department == department)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      return current.copyWith(
        selectedOrgDepartment: department,
        selectedOrgUserId: members.firstOrNull?.id,
      );
    });
  }

  void setOrgMember(String userId) {
    _setDashboardState(
      this,
      (current) => current.copyWith(selectedOrgUserId: userId),
    );
  }
}
