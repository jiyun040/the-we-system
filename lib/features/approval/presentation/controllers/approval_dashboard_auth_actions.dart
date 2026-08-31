import 'package:the_we_system/core/network/api_exception.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_provider_helpers.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';

extension ApprovalDashboardAuthActions on ApprovalDashboardController {
  void updateKeyword(String keyword) {
    setApprovalDashboardState(
      this,
      (current) => current.copyWith(keyword: keyword),
    );
  }

  Future<void> refresh() async {
    await refreshRemoteState();
  }

  Future<bool> login(String id, String password) async {
    try {
      await api.login(id.trim(), password);
      await reloadRemoteState();
      return true;
    } on ApiException catch (error) {
      setApprovalDashboardState(
        this,
        (value) => value.copyWith(loginError: error.message),
      );
      return false;
    } catch (error) {
      setApprovalDashboardState(
        this,
        (value) => value.copyWith(loginError: userFacingErrorMessage(error)),
      );
      return false;
    }
  }

  Future<String?> registerAccount({
    required String id,
    required String password,
    required String name,
    required String department,
    required String position,
  }) async {
    try {
      await api.register(
        id: id.trim(),
        password: password,
        name: name.trim(),
        department: department.trim(),
        position: position.trim(),
      );
      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (error) {
      return userFacingErrorMessage(error);
    }
  }

  Future<void> logout() async {
    await api.logout();
    emitDashboardState(signedOutApprovalState);
  }

  void clearLoginError() {
    setApprovalDashboardState(
      this,
      (current) => current.copyWith(loginError: ''),
    );
  }

  void setLoginError(String message) {
    setApprovalDashboardState(
      this,
      (current) => current.copyWith(loginError: message),
    );
  }

  void adjustZoom(double delta) {
    setApprovalDashboardState(this, (current) {
      final next = (current.zoom + delta).clamp(0.85, 1.55);
      return current.copyWith(zoom: next);
    });
  }

  void setDepartment(String department) {
    setApprovalDashboardState(this, (current) {
      final members =
          current.accounts
              .where((account) => account.department == department)
              .toList()
            ..sort(compareEmployeeOrganizationOrder);
      return current.copyWith(
        selectedOrgDepartment: department,
        selectedOrgUserId: members.firstOrNull?.id,
      );
    });
  }

  void setOrgMember(String userId) {
    setApprovalDashboardState(
      this,
      (current) => current.copyWith(selectedOrgUserId: userId),
    );
  }
}
