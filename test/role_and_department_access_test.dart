import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';

void main() {
  test('관리자 계정은 OTP 인증 후 관리자 모드로 동작한다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(approvalDashboardControllerProvider.future);
    final notifier = container.read(
      approvalDashboardControllerProvider.notifier,
    );

    expect(await notifier.login('edu_manager', '1234'), isTrue);
    expect(notifier.hasValidAdminCredentials('edu_manager', '1234'), isTrue);
    expect(
      container
          .read(approvalDashboardControllerProvider)
          .requireValue
          .adminMode,
      isFalse,
    );
    expect(notifier.enterAdminMode('000000'), isFalse);
    expect(notifier.enterAdminMode('123456'), isTrue);
    expect(
      container
          .read(approvalDashboardControllerProvider)
          .requireValue
          .isAdminMode,
      isTrue,
    );
  });

  test('보안 기안은 같은 부서의 비결재자에게 노출되지 않는다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(approvalDashboardControllerProvider.future);
    final notifier = container.read(
      approvalDashboardControllerProvider.notifier,
    );

    await notifier.login('edu_teacher', '1234');
    final restrictedId = await notifier.requestApproval(
      draft: const ApprovalRequestDraft(
        formId: 'business-draft',
        title: '보안 기안',
        content: '기안자와 결재자만 열람',
        urgent: false,
        linkedDocuments: [],
        departmentVisible: false,
      ),
    );
    expect(restrictedId, isNotNull);

    notifier.logout();
    await notifier.login('edu_manager', '1234');
    notifier.leaveAdminMode();
    final coworkerState = container
        .read(approvalDashboardControllerProvider)
        .requireValue;
    expect(
      coworkerState.departmentDocuments.any(
        (document) => document.id == restrictedId,
      ),
      isFalse,
    );
  });

  test('관리자는 직원을 추가하고 새 계정으로 로그인할 수 있다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(approvalDashboardControllerProvider.future);
    final notifier = container.read(
      approvalDashboardControllerProvider.notifier,
    );

    final error = notifier.addEmployee(
      id: 'new_employee',
      password: 'new1234',
      name: '신규직원',
      department: '개발팀',
      position: '사원',
      email: 'new_employee@thewe.co.kr',
      hireDate: '2026-07-31',
      isAdmin: false,
    );

    expect(error, isNull);
    expect(
      container
          .read(approvalDashboardControllerProvider)
          .requireValue
          .accounts
          .any((account) => account.id == 'new_employee'),
      isTrue,
    );
    expect(await notifier.login('new_employee', 'new1234'), isTrue);
  });

  test('APP 노출과 전자결재 양식 설정이 실제 상태에 반영된다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(approvalDashboardControllerProvider.future);
    final notifier = container.read(
      approvalDashboardControllerProvider.notifier,
    );

    notifier.toggleApp(PortalAppId.approval, false);
    var state = container
        .read(approvalDashboardControllerProvider)
        .requireValue;
    expect(state.isAppEnabled(PortalAppId.approval), isFalse);
    expect(state.dashboard.frequentForms, isEmpty);

    final templateId = state.formTemplates.first.id;
    notifier.toggleFormTemplate(templateId, false);
    state = container.read(approvalDashboardControllerProvider).requireValue;
    expect(
      state.activeFormTemplates.any((template) => template.id == templateId),
      isFalse,
    );

    final count = state.formTemplates.length;
    final error = notifier.saveFormTemplate(
      category: '인사',
      name: '신규 양식',
      description: '테스트 양식',
      defaultTitle: '신규 기안',
      defaultContent: '기안 내용을 입력하세요.',
    );
    state = container.read(approvalDashboardControllerProvider).requireValue;
    expect(error, isNull);
    expect(state.formTemplates.length, count + 1);
    expect(
      state.formTemplates.any((template) => template.name == '신규 양식'),
      isTrue,
    );
  });

  test('근속연수별 연차 설정을 한 번에 저장할 수 있다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(approvalDashboardControllerProvider.future);
    final notifier = container.read(
      approvalDashboardControllerProvider.notifier,
    );
    final current = container
        .read(approvalDashboardControllerProvider)
        .requireValue;
    final policy = {...current.annualLeaveByYear, 1: 18, 2: 19};

    expect(notifier.updateAnnualLeavePolicies(policy), isNull);
    final updated = container
        .read(approvalDashboardControllerProvider)
        .requireValue;
    expect(updated.annualLeaveByYear[1], 18);
    expect(updated.annualLeaveByYear[2], 19);
    expect(notifier.updateAnnualLeavePolicies({...policy, 3: 0}), isNotNull);
  });

  test('휴가 신청 즉시 잔여 연차가 차감되고 반려되면 복구된다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(approvalDashboardControllerProvider.future);
    final notifier = container.read(
      approvalDashboardControllerProvider.notifier,
    );
    await notifier.login('edu_teacher', '1234');

    final before = container
        .read(approvalDashboardControllerProvider)
        .requireValue;
    final remainingBefore = before.remainingAnnualLeave;
    expect(before.portalName, '더우리기술 전자결재');

    notifier.requestLeave(
      type: '반차',
      startDate: '2026-08-03',
      endDate: '2026-08-03',
      days: .5,
      reason: '병원 진료',
    );
    var state = container
        .read(approvalDashboardControllerProvider)
        .requireValue;
    expect(state.pendingAnnualLeave, .5);
    expect(state.remainingAnnualLeave, remainingBefore - .5);

    final requestId = state.currentUserLeaveRequests.first.id;
    notifier.updateLeaveStatus(requestId, '반려');
    state = container.read(approvalDashboardControllerProvider).requireValue;
    expect(state.pendingAnnualLeave, 0);
    expect(state.remainingAnnualLeave, remainingBefore);
  });
}
