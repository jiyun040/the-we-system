import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_we_system/features/approval/domain/entities/dashboard/approval_dashboard.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:the_we_system/features/approval/domain/entities/form/approval_form.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_history.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_step.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';

part 'approval_dashboard_state.dart';
part 'approval_dashboard_auth_actions.dart';
part 'approval_dashboard_draft_actions.dart';
part 'approval_dashboard_approval_actions.dart';
part 'approval_mock_forms.dart';
part 'approval_mock_documents.dart';
part 'approval_provider_helpers.dart';

final approvalDashboardControllerProvider =
    AsyncNotifierProvider<ApprovalDashboardController, ApprovalDashboardState>(
      ApprovalDashboardController.new,
    );

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
  ApprovalDashboardState? get _currentState => state.asData?.value;

  void _emitState(ApprovalDashboardState nextState) {
    state = AsyncData(nextState);
  }

  @override
  Future<ApprovalDashboardState> build() async {
    final accounts = [..._accounts];
    return ApprovalDashboardState(
      accounts: accounts,
      frequentForms: _frequentForms,
      formTemplates: [..._templates],
      documents: [..._seedDocuments],
      selectedOrgDepartment: accounts.first.department,
      selectedOrgUserId: accounts.first.id,
    );
  }
}
