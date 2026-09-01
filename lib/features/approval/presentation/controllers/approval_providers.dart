import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_we_system/core/network/api_exception.dart';
import 'package:the_we_system/core/network/dio_provider.dart';
import 'package:the_we_system/features/approval/data/datasources/the_we_api_service.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_controller_models.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_default_forms.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_dashboard_state.dart';

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

final approvalOperationErrorProvider =
    NotifierProvider<ApprovalOperationErrorController, String?>(
      ApprovalOperationErrorController.new,
    );

class ApprovalOperationErrorController extends Notifier<String?> {
  @override
  String? build() => null;

  void show(Object error, {String? fallback}) {
    state = userFacingErrorMessage(
      error,
      fallback: fallback ?? '요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.',
    );
  }

  void clear() => state = null;
}

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
  ApprovalDashboardState? get currentDashboardState => state.asData?.value;

  TheWeApiService get api => ref.read(theWeApiServiceProvider);

  void reportOperationError(Object error, {String? fallback}) {
    ref
        .read(approvalOperationErrorProvider.notifier)
        .show(error, fallback: fallback);
  }

  void emitDashboardState(ApprovalDashboardState nextState) {
    state = AsyncData(nextState);
  }

  Future<void> reloadRemoteState({bool? adminMode}) async {
    final remote = await api.fetchBootstrap();
    state = AsyncData(
      _remoteState(
        remote,
        adminMode: adminMode ?? currentDashboardState?.adminMode ?? false,
      ),
    );
  }

  Future<void> refreshRemoteState() async {
    final adminMode = currentDashboardState?.adminMode ?? false;
    state = const AsyncLoading();
    try {
      await reloadRemoteState(adminMode: adminMode);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  @override
  Future<ApprovalDashboardState> build() async {
    if (!await api.hasStoredToken()) return signedOutApprovalState;
    try {
      return _remoteState(await api.fetchBootstrap());
    } on ApiException catch (error) {
      if (error.statusCode == 401) return signedOutApprovalState;
      rethrow;
    }
  }
}

const signedOutApprovalState = ApprovalDashboardState(
  accounts: [],
  frequentForms: [],
  formTemplates: [],
  documents: [],
  annualLeaveByYear: {},
);

ApprovalDashboardState _remoteState(
  RemoteBootstrapData remote, {
  bool adminMode = false,
}) {
  final formTemplates = mergeApprovalFormTemplates(remote.formTemplates);
  return ApprovalDashboardState(
    accounts: remote.accounts
        .where((account) => !account.isSystemAdministrator)
        .toList(),
    organizationDepartments: remote.departments,
    frequentForms: remote.frequentForms,
    formTemplates: formTemplates,
    documents: remote.documents,
    annualLeaveByYear: remote.annualLeaveByYear,
    monthlyLeavePerMonth: remote.monthlyLeavePerMonth,
    currentUser: remote.currentUser,
    selectedOrgDepartment: remote.currentUser.department,
    selectedOrgUserId: remote.currentUser.id,
    adminMode: adminMode,
    restrictedDocumentIds: remote.restrictedDocumentIds,
    leaveRequests: remote.leaveRequests,
    notices: remote.notices,
    acknowledgedLeaveRequestIds: remote.acknowledgedLeaveRequestIds,
    portalName: remote.portalName,
    customLogoBytes: remote.customLogoBytes,
    customLogoFileName: remote.customLogoFileName,
    adminOtpEnabled: remote.adminOtpEnabled,
    settingsPasswordEnabled: remote.settingsPasswordEnabled,
    adminDocumentAccessEnabled: remote.adminDocumentAccessEnabled,
    enabledAppIds: remote.enabledAppIds,
    disabledFormTemplateIds: formTemplates
        .where((form) => remote.disabledFormTemplateIds.contains(form.id))
        .map((form) => form.id)
        .toSet(),
    organizationWideDocumentCategories:
        remote.organizationWideDocumentCategories,
    documentCategoryViewerIds: remote.documentCategoryViewerIds,
  );
}
