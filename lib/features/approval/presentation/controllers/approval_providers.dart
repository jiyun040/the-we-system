import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  void emitDashboardState(ApprovalDashboardState nextState) {
    state = AsyncData(nextState);
  }

  @override
  Future<ApprovalDashboardState> build() async {
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
}
