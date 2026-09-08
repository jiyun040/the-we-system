import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

final acknowledgedRejectedDocumentsProvider =
    AsyncNotifierProvider<AcknowledgedRejectedDocumentsController, Set<String>>(
      AcknowledgedRejectedDocumentsController.new,
    );

final dismissedRejectedApprovalAlertsProvider =
    AsyncNotifierProvider<
      DismissedRejectedApprovalAlertsController,
      Set<String>
    >(DismissedRejectedApprovalAlertsController.new);

abstract class _RejectedApprovalEventController
    extends AsyncNotifier<Set<String>> {
  String get preferencePrefix;

  @override
  Future<Set<String>> build() async {
    final userId = ref.watch(
      approvalDashboardControllerProvider.select(
        (dashboard) => dashboard.asData?.value.currentUser?.id,
      ),
    );
    if (userId == null || userId.isEmpty) return const {};
    final preferences = await SharedPreferences.getInstance();
    return {
      ...?preferences.getStringList(
        _rejectedApprovalPreferenceKey(preferencePrefix, userId),
      ),
    };
  }

  Future<void> acknowledge(ApprovalDocument document) async {
    final userId = ref
        .read(approvalDashboardControllerProvider)
        .asData
        ?.value
        .currentUser
        ?.id;
    if (userId == null || userId.isEmpty) return;
    final eventKey = rejectedApprovalEventKey(document);
    final updated = {...?state.asData?.value, eventKey};

    // 알림은 클릭 즉시 화면에서 제거하고, 영구 저장은 뒤에서 완료한다.
    state = AsyncData(updated);

    final preferences = await SharedPreferences.getInstance();
    final persisted = {
      ...?preferences.getStringList(
        _rejectedApprovalPreferenceKey(preferencePrefix, userId),
      ),
      ...updated,
    };
    await preferences.setStringList(
      _rejectedApprovalPreferenceKey(preferencePrefix, userId),
      persisted.toList(),
    );
  }
}

class AcknowledgedRejectedDocumentsController
    extends _RejectedApprovalEventController {
  @override
  String get preferencePrefix => 'acknowledged_rejected_documents';
}

class DismissedRejectedApprovalAlertsController
    extends _RejectedApprovalEventController {
  @override
  String get preferencePrefix => 'dismissed_rejected_approval_alerts';
}

String _rejectedApprovalPreferenceKey(String prefix, String userId) =>
    '${prefix}_$userId';

String rejectedApprovalEventKey(ApprovalDocument document) {
  final rejectedStep = document.steps
      .where((step) => step.status == '반려')
      .lastOrNull;
  final rejectionHistory = document.histories
      .where(
        (history) =>
            history.category.contains('반려') ||
            history.description.contains('반려'),
      )
      .lastOrNull;
  final eventId =
      rejectedStep?.approvedAt ?? rejectionHistory?.id ?? document.draftedAt;
  return '${document.id}:$eventId';
}

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

  Future<void> refreshInBackground() async {
    if (currentDashboardState?.isAuthenticated != true) return;
    try {
      final remote = await api.fetchBootstrap();
      final current = currentDashboardState;
      if (current == null || !current.isAuthenticated) return;
      final remoteDocumentIds = remote.documents
          .map((document) => document.id)
          .toSet();
      final documents = [
        ...remote.documents,
        ...current.documents.where(
          (document) => !remoteDocumentIds.contains(document.id),
        ),
      ]..sort((left, right) => right.draftedAt.compareTo(left.draftedAt));
      emitDashboardState(
        current.copyWith(
          documents: documents,
          restrictedDocumentIds: remote.restrictedDocumentIds,
        ),
      );
    } catch (_) {
      // A background notification check must not interrupt the active screen.
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
    leaveApprovalLines: remote.leaveApprovalLines,
  );
}
