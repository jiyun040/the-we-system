import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_we_system/core/config/app_env.dart';
import 'package:the_we_system/core/network/api_exception.dart';
import 'package:the_we_system/core/network/dio_provider.dart';
import 'package:the_we_system/features/approval/data/datasources/the_we_api_service.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_controller_models.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_dashboard_state.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_mock_documents.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_mock_forms.dart';

export 'approval_dashboard_admin_actions.dart';
export 'approval_dashboard_approval_actions.dart';
export 'approval_dashboard_auth_actions.dart';
export 'approval_dashboard_draft_actions.dart';
export 'approval_dashboard_state.dart';

final approvalDashboardControllerProvider =
    AsyncNotifierProvider<ApprovalDashboardController, ApprovalDashboardState>(
      ApprovalDashboardController.new,
    );

final theWeApiServiceProvider = Provider<TheWeApiService>((ref) {
  return TheWeApiService(
    ref.watch(dioProvider),
    ref.watch(authTokenStoreProvider),
  );
});

final approvalDocumentProvider = Provider.family<ApprovalDocument?, String>((
  ref,
  id,
) {
  final state = ref.watch(approvalDashboardControllerProvider).asData?.value;
  if (state == null) {
    return null;
  }

  return state.visibleDocuments
      .where((document) => document.id == id)
      .firstOrNull;
});

final approvalTemplateProvider = Provider.family<ApprovalFormTemplate?, String>(
  (ref, id) {
    final state = ref.watch(approvalDashboardControllerProvider).asData?.value;
    if (state == null) {
      return null;
    }

    return state.formTemplates
        .where((template) => template.id == id)
        .firstOrNull;
  },
);

class ApprovalDashboardController
    extends AsyncNotifier<ApprovalDashboardState> {
  String? sessionPassword;

  ApprovalDashboardState? get currentDashboardState => state.asData?.value;

  bool get usesRemoteApi => AppEnv.usesRemoteApi;

  TheWeApiService get api => ref.read(theWeApiServiceProvider);

  void emitDashboardState(ApprovalDashboardState nextState) {
    state = AsyncData(nextState);
  }

  Future<void> reloadRemoteState({bool? adminMode}) async {
    if (!usesRemoteApi) return;
    final remote = await api.fetchBootstrap();
    state = AsyncData(
      _remoteState(
        remote,
        adminMode: adminMode ?? currentDashboardState?.adminMode ?? false,
      ),
    );
  }

  @override
  Future<ApprovalDashboardState> build() async {
    if (usesRemoteApi) {
      if (!await api.hasStoredToken()) return _localState();
      try {
        return _remoteState(await api.fetchBootstrap());
      } on ApiException catch (error) {
        if (error.statusCode == 401) return _localState();
        rethrow;
      }
    }
    return _localState();
  }
}

ApprovalDashboardState _localState() {
  final accounts = [...approvalAccounts];
  return ApprovalDashboardState(
    accounts: accounts,
    frequentForms: approvalFrequentForms,
    formTemplates: [...approvalFormTemplates],
    documents: [...approvalSeedDocuments],
    leaveRequests: const [
      LeaveRequest(
        id: 'LEAVE-SEED-1',
        userId: 'edu_teacher',
        type: '연차',
        startDate: '2026-05-04',
        endDate: '2026-05-04',
        days: 1,
        reason: '개인 일정',
        status: '승인완료',
        ceoStatus: '완료',
      ),
      LeaveRequest(
        id: 'LEAVE-SEED-2',
        userId: 'edu_teacher',
        type: '연차',
        startDate: '2026-06-12',
        endDate: '2026-06-13',
        days: 2,
        reason: '가족 행사',
        status: '승인완료',
        ceoStatus: '완료',
      ),
    ],
    acknowledgedLeaveRequestIds: const {'LEAVE-SEED-1', 'LEAVE-SEED-2'},
    annualLeaveByYear: const {
      1: 15,
      2: 15,
      3: 16,
      4: 16,
      5: 17,
      6: 17,
      7: 18,
      8: 18,
      9: 19,
      10: 19,
    },
    selectedOrgDepartment: accounts.first.department,
    selectedOrgUserId: accounts.first.id,
  );
}

ApprovalDashboardState _remoteState(
  RemoteBootstrapData remote, {
  bool adminMode = false,
}) => ApprovalDashboardState(
  accounts: remote.accounts,
  frequentForms: remote.frequentForms,
  formTemplates: remote.formTemplates,
  documents: remote.documents,
  annualLeaveByYear: remote.annualLeaveByYear,
  monthlyLeavePerMonth: remote.monthlyLeavePerMonth,
  currentUser: remote.currentUser,
  selectedOrgDepartment: remote.currentUser.department,
  selectedOrgUserId: remote.currentUser.id,
  adminMode: adminMode,
  restrictedDocumentIds: remote.restrictedDocumentIds,
  leaveRequests: remote.leaveRequests,
  acknowledgedLeaveRequestIds: remote.acknowledgedLeaveRequestIds,
  portalName: remote.portalName,
  customLogoBytes: remote.customLogoBytes,
  customLogoFileName: remote.customLogoFileName,
  adminOtpEnabled: remote.adminOtpEnabled,
  settingsPasswordEnabled: remote.settingsPasswordEnabled,
  adminDocumentAccessEnabled: remote.adminDocumentAccessEnabled,
  enabledAppIds: remote.enabledAppIds,
  disabledFormTemplateIds: remote.formTemplates
      .where((form) => remote.disabledFormTemplateIds.contains(form.id))
      .map((form) => form.id)
      .toSet(),
  organizationWideDocumentCategories: remote.organizationWideDocumentCategories,
  documentCategoryViewerIds: remote.documentCategoryViewerIds,
);
