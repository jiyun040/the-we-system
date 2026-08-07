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
    expect(notifier.hasValidAdminCredentials('edu_teacher', '1234'), isFalse);
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

  test('임시저장 문서와 보안 문서는 부서 비결재자에게 노출되지 않는다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(approvalDashboardControllerProvider.future);
    final notifier = container.read(
      approvalDashboardControllerProvider.notifier,
    );

    await notifier.login('edu_teacher', '1234');
    final draftId = await notifier.saveDraft(
      formId: 'business-draft',
      title: '작성 중 문서',
      content: '아직 상신하지 않은 내용',
      linkedDocuments: const [],
      departmentVisible: false,
      formFields: const {},
      lineItems: const [],
    );
    expect(draftId, isNotNull);

    notifier.logout();
    await notifier.login('edu_manager', '1234');
    notifier.leaveAdminMode();
    final coworkerState = container
        .read(approvalDashboardControllerProvider)
        .requireValue;
    expect(
      coworkerState.departmentDocuments.any(
        (document) => document.id == draftId,
      ),
      isFalse,
    );
    expect(
      coworkerState.visibleDocuments.any((document) => document.id == draftId),
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

  test('결재 구분별 일부 사용자 문서함 접근 권한을 저장한다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(approvalDashboardControllerProvider.future);
    final notifier = container.read(
      approvalDashboardControllerProvider.notifier,
    );
    var state = container
        .read(approvalDashboardControllerProvider)
        .requireValue;
    expect(
      state.organizationWideDocumentCategories,
      containsAll(const ['지원', '회계', '근태', '급여']),
    );

    notifier.updateDocumentCategoryAccess(
      category: '회계',
      organizationWide: false,
      userIds: const {'jiyun'},
    );
    state = container.read(approvalDashboardControllerProvider).requireValue;
    expect(state.documentCategoryViewerIds['회계'], contains('jiyun'));

    notifier.updateDocumentCategoryAccess(
      category: '근태',
      organizationWide: true,
      userIds: const {},
    );
    state = container.read(approvalDashboardControllerProvider).requireValue;
    expect(state.organizationWideDocumentCategories, contains('근태'));
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
    expect(
      notifier.updateAnnualLeavePolicies(policy, monthlyLeavePerMonth: 2),
      isNull,
    );
    expect(
      container
          .read(approvalDashboardControllerProvider)
          .requireValue
          .monthlyLeavePerMonth,
      2,
    );
    expect(notifier.updateAnnualLeavePolicies({...policy, 3: 0}), isNotNull);
  });

  test('1년 미만 직원은 근속월에 따라 월차가 발생한다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(approvalDashboardControllerProvider.future);
    final notifier = container.read(
      approvalDashboardControllerProvider.notifier,
    );
    final now = DateTime.now();
    final hireDate = DateTime(now.year, now.month - 3, 1);
    final hireDateText =
        '${hireDate.year.toString().padLeft(4, '0')}-${hireDate.month.toString().padLeft(2, '0')}-${hireDate.day.toString().padLeft(2, '0')}';

    expect(
      notifier.addEmployee(
        id: 'monthly_employee',
        password: '1234',
        name: '월차직원',
        department: '교육관리팀',
        position: '사원',
        email: 'monthly@thewe.co.kr',
        hireDate: hireDateText,
        isAdmin: false,
      ),
      isNull,
    );

    final state = container
        .read(approvalDashboardControllerProvider)
        .requireValue;
    final employee = state.accounts.firstWhere(
      (account) => account.id == 'monthly_employee',
    );
    expect(state.isUnderOneYear(employee), isTrue);
    expect(state.completedServiceMonthsFor(employee), 3);
    expect(state.totalAnnualLeaveFor(employee), 3);
    expect(state.leaveEntitlementLabelFor(employee), '발생 월차');
  });

  test('관리자 직접 휴가 등록은 승인 없이 즉시 차감되고 사유가 남는다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(approvalDashboardControllerProvider.future);
    final notifier = container.read(
      approvalDashboardControllerProvider.notifier,
    );
    expect(await notifier.login('edu_manager', '1234'), isTrue);
    expect(notifier.enterAdminMode('123456'), isTrue);

    final before = container
        .read(approvalDashboardControllerProvider)
        .requireValue;
    final employee = before.accounts.firstWhere(
      (account) => account.id == 'edu_teacher',
    );
    final remainingBefore = before.remainingAnnualLeaveFor(employee);

    expect(
      notifier.addLeaveForEmployee(
        userId: employee.id,
        type: '연차',
        startDate: '2026-08-03',
        endDate: '2026-08-03',
        days: 1,
        reason: '결재 시스템 미사용분 관리자 반영',
      ),
      isNull,
    );
    final updated = container
        .read(approvalDashboardControllerProvider)
        .requireValue;
    final registered = updated.leaveRequests.first;
    expect(registered.status, '승인완료');
    expect(registered.directEntry, isTrue);
    expect(registered.registeredBy, '교육관리자');
    expect(registered.reason, '결재 시스템 미사용분 관리자 반영');
    expect(updated.remainingAnnualLeaveFor(employee), remainingBefore - 1);
    expect(
      notifier.addLeaveForEmployee(
        userId: employee.id,
        type: '연차',
        startDate: '2026-08-04',
        endDate: '2026-08-04',
        days: 1,
        reason: '  ',
      ),
      isNotNull,
    );
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

  test('휴가는 이사 단계를 거치지 않고 대표에게 바로 전달된다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(approvalDashboardControllerProvider.future);
    final notifier = container.read(
      approvalDashboardControllerProvider.notifier,
    );

    await notifier.login('edu_teacher', '1234');
    notifier.requestLeave(
      type: '연차',
      startDate: '2026-08-10',
      endDate: '2026-08-10',
      days: 1,
      reason: '개인 일정',
    );
    var state = container
        .read(approvalDashboardControllerProvider)
        .requireValue;
    final requestId = state.currentUserLeaveRequests.first.id;
    expect(state.currentUserLeaveRequests.first.ceoStatus, '진행중');
    final leaveDocumentId = 'LEAVE-DOC-$requestId';
    expect(
      state.dashboard.processingDocuments.any(
        (document) => document.id == leaveDocumentId,
      ),
      isTrue,
    );

    notifier.logout();
    await notifier.login('director', '1234');
    expect(
      container
          .read(approvalDashboardControllerProvider)
          .requireValue
          .waitingDocuments
          .any((document) => document.id == leaveDocumentId),
      isFalse,
    );
    expect(notifier.actOnLeave(requestId, approve: true), isFalse);

    notifier.logout();
    await notifier.login('ceo', '1234');
    expect(
      container
          .read(approvalDashboardControllerProvider)
          .requireValue
          .waitingDocuments
          .any((document) => document.id == leaveDocumentId),
      isTrue,
    );
    expect(notifier.actOnLeave(requestId, approve: true), isTrue);
    state = container.read(approvalDashboardControllerProvider).requireValue;
    final request = state.leaveRequests
        .where((item) => item.id == requestId)
        .first;
    expect(request.status, '승인완료');
    expect(request.ceoStatus, '완료');
    expect(state.unacknowledgedApprovedLeaveRequests, contains(request));

    notifier.logout();
    await notifier.login('edu_manager', '1234');
    expect(notifier.enterAdminMode('123456'), isTrue);
    notifier.acknowledgeApprovedLeaves([requestId]);
    state = container.read(approvalDashboardControllerProvider).requireValue;
    expect(state.unacknowledgedApprovedLeaveRequests, isEmpty);
  });

  test('관리자 계정은 edu_manager 하나만 유지된다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(approvalDashboardControllerProvider.future);
    final notifier = container.read(
      approvalDashboardControllerProvider.notifier,
    );

    final state = container
        .read(approvalDashboardControllerProvider)
        .requireValue;
    expect(
      state.accounts.where((account) => account.isAdmin).single.id,
      'edu_manager',
    );
    expect(notifier.setAdminPermission('edu_manager', true), isNull);
    expect(notifier.setAdminPermission('edu_teacher', true), isNotNull);
    expect(await notifier.login('edu_manager', '1234'), isTrue);
    expect(
      container
          .read(approvalDashboardControllerProvider)
          .requireValue
          .adminMode,
      isFalse,
    );
  });

  test('edu_manager만 OTP로 관리자 모드를 사용한다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(approvalDashboardControllerProvider.future);
    final notifier = container.read(
      approvalDashboardControllerProvider.notifier,
    );

    expect(await notifier.login('edu_teacher', '1234'), isTrue);
    expect(notifier.enterAdminMode('123456'), isFalse);
    notifier.logout();
    expect(await notifier.login('edu_manager', '1234'), isTrue);
    expect(notifier.enterAdminMode('123456'), isTrue);
    var state = container
        .read(approvalDashboardControllerProvider)
        .requireValue;
    expect(state.isAdminMode, isTrue);
    expect(state.currentUser?.id, 'edu_manager');

    notifier.leaveAdminMode();
    state = container.read(approvalDashboardControllerProvider).requireValue;
    expect(state.isAdminMode, isFalse);
    expect(state.currentUser?.id, 'edu_manager');
  });

  test('기업업무추진비만 수기 기안일을 저장하고 PDF 양식은 확장된 행을 사용한다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(approvalDashboardControllerProvider.future);
    final notifier = container.read(
      approvalDashboardControllerProvider.notifier,
    );
    await notifier.login('edu_teacher', '1234');

    final hospitality = notifier.buildDraftDocument('hospitality-expense');
    final expense = notifier.buildDraftDocument('expense-slip');
    final purchase = notifier.buildDraftDocument('purchase-request');
    expect(hospitality.lineItems, hasLength(24));
    expect(expense.lineItems, hasLength(32));
    expect(purchase.lineItems, hasLength(16));

    final id = await notifier.requestApproval(
      draft: const ApprovalRequestDraft(
        formId: 'hospitality-expense',
        title: '기업업무추진비',
        content: '',
        urgent: false,
        linkedDocuments: [],
        documentLayout: ApprovalDocumentLayout.hospitality,
        formFields: {'draftedAt': '2026-07-15'},
      ),
    );
    final document = container
        .read(approvalDashboardControllerProvider)
        .requireValue
        .documents
        .firstWhere((document) => document.id == id);
    expect(document.draftedAt, '2026-07-15');
  });

  test('PDF형 결재 문서는 상신취소와 반려 후에도 입력 내용을 유지한다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(approvalDashboardControllerProvider.future);
    final notifier = container.read(
      approvalDashboardControllerProvider.notifier,
    );

    await notifier.login('edu_teacher', '1234');
    const draft = ApprovalRequestDraft(
      formId: 'expense-slip',
      title: '교육비 지출결의',
      content: '교육비 지급을 요청합니다.',
      urgent: false,
      linkedDocuments: ['[첨부] 거래명세서.pdf'],
      documentLayout: ApprovalDocumentLayout.expense,
      formFields: {'note': '교육 운영비'},
      lineItems: [
        {
          'date': '2026-08-01',
          'item': '교육비',
          'purpose': '직무교육',
          'amount': '300000',
        },
      ],
    );
    final documentId = await notifier.requestApproval(draft: draft);
    expect(documentId, isNotNull);

    await notifier.cancelSubmission(documentId!);
    var state = container
        .read(approvalDashboardControllerProvider)
        .requireValue;
    var document = state.documents.where((item) => item.id == documentId).first;
    expect(document.status, '작성중');
    expect(document.content, draft.content);
    expect(document.lineItems.first['amount'], '300000');
    expect(document.linkedDocuments, contains('[첨부] 거래명세서.pdf'));

    await notifier.requestApproval(documentId: documentId, draft: draft);
    notifier.logout();
    await notifier.login('lee_jaeo', '1234');
    await notifier.approveDocument(documentId, action: '반려', opinion: '증빙 보완');
    state = container.read(approvalDashboardControllerProvider).requireValue;
    document = state.documents.where((item) => item.id == documentId).first;
    expect(document.status, '반려');
    expect(document.steps.any((step) => step.status == '반려'), isTrue);
    expect(document.formFields['note'], '교육 운영비');
  });
}
