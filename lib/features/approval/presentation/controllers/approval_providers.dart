import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_we_system/features/approval/domain/entities/approval_dashboard.dart';
import 'package:the_we_system/features/approval/domain/entities/approval_document.dart';
import 'package:the_we_system/features/approval/domain/entities/approval_form.dart';
import 'package:the_we_system/features/approval/domain/entities/approval_history.dart';
import 'package:the_we_system/features/approval/domain/entities/approval_step.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';

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

class ApprovalDashboardState {
  const ApprovalDashboardState({
    required this.accounts,
    required this.frequentForms,
    required this.formTemplates,
    required this.documents,
    this.currentUser,
    this.keyword = '',
    this.zoom = 1.0,
    this.loginError = '',
    this.selectedOrgDepartment = '',
    this.selectedOrgUserId,
  });

  final List<EmployeeAccount> accounts;
  final List<ApprovalForm> frequentForms;
  final List<ApprovalFormTemplate> formTemplates;
  final List<ApprovalDocument> documents;
  final EmployeeAccount? currentUser;
  final String keyword;
  final double zoom;
  final String loginError;
  final String selectedOrgDepartment;
  final String? selectedOrgUserId;

  ApprovalDashboardState copyWith({
    List<EmployeeAccount>? accounts,
    List<ApprovalForm>? frequentForms,
    List<ApprovalFormTemplate>? formTemplates,
    List<ApprovalDocument>? documents,
    EmployeeAccount? currentUser,
    bool clearCurrentUser = false,
    String? keyword,
    double? zoom,
    String? loginError,
    String? selectedOrgDepartment,
    String? selectedOrgUserId,
    bool clearSelectedOrgUser = false,
  }) {
    return ApprovalDashboardState(
      accounts: accounts ?? this.accounts,
      frequentForms: frequentForms ?? this.frequentForms,
      formTemplates: formTemplates ?? this.formTemplates,
      documents: documents ?? this.documents,
      currentUser: clearCurrentUser ? null : (currentUser ?? this.currentUser),
      keyword: keyword ?? this.keyword,
      zoom: zoom ?? this.zoom,
      loginError: loginError ?? this.loginError,
      selectedOrgDepartment:
          selectedOrgDepartment ?? this.selectedOrgDepartment,
      selectedOrgUserId: clearSelectedOrgUser
          ? null
          : (selectedOrgUserId ?? this.selectedOrgUserId),
    );
  }

  bool get isAuthenticated => currentUser != null;

  bool get isAdmin => currentUser?.isAdmin ?? false;

  List<ApprovalDocument> get visibleDocuments {
    final user = currentUser;
    if (user == null) {
      return const [];
    }

    if (user.isAdmin) {
      return documents;
    }

    return documents.where((document) {
      final isDrafter = document.drafter == user.name;
      final isApprover = document.steps.any((step) => step.name == user.name);
      final isReader =
          document.references.contains(user.name) ||
          document.viewers.contains(user.name);
      return isDrafter || isApprover || isReader;
    }).toList();
  }

  List<ApprovalDocument> get authoredDocuments {
    final user = currentUser;
    if (user == null) {
      return const [];
    }

    if (user.isAdmin) {
      return documents;
    }

    return documents
        .where((document) => document.drafter == user.name)
        .toList();
  }

  List<ApprovalDocument> get sharedDraftDocuments {
    return [...documents]..sort((a, b) => b.draftedAt.compareTo(a.draftedAt));
  }

  List<ApprovalDocument> get waitingDocuments {
    final user = currentUser;
    if (user == null) {
      return const [];
    }

    return visibleDocuments.where((document) {
      final activeStep = document.steps
          .where((step) => step.status == '진행중')
          .firstOrNull;
      if (activeStep == null) {
        return false;
      }

      return user.isAdmin ? true : activeStep.name == user.name;
    }).toList()..sort((a, b) {
      if (a.urgent != b.urgent) {
        return a.urgent ? -1 : 1;
      }
      return b.draftedAt.compareTo(a.draftedAt);
    });
  }

  List<ApprovalDocument> get scheduledDocuments {
    final user = currentUser;
    if (user == null) {
      return const [];
    }

    return visibleDocuments.where((document) {
      final scheduled = document.steps.any(
        (step) => step.name == user.name && step.status == '결재 예정',
      );
      return user.isAdmin ? document.status == '결재대기' : scheduled;
    }).toList();
  }

  List<ApprovalDocument> get referenceDocuments {
    final user = currentUser;
    if (user == null) {
      return const [];
    }

    if (user.isAdmin) {
      return documents;
    }

    return documents
        .where(
          (document) =>
              document.references.contains(user.name) ||
              document.viewers.contains(user.name),
        )
        .toList();
  }

  ApprovalDashboard get dashboard => ApprovalDashboard(
    pendingCount: waitingDocuments.length,
    receivedCount: waitingDocuments.length,
    referenceCount: referenceDocuments.length,
    scheduledCount: scheduledDocuments.length,
    frequentForms: frequentForms,
    processingDocuments:
        authoredDocuments.where((document) => document.status != '작성중').toList()
          ..sort((a, b) => b.draftedAt.compareTo(a.draftedAt)),
    waitingDocuments: waitingDocuments,
  );

  List<String> get departments {
    final values =
        accounts.map((account) => account.department).toSet().toList()..sort();
    return values;
  }

  List<EmployeeAccount> get selectedDepartmentMembers {
    if (selectedOrgDepartment.isEmpty) {
      return const [];
    }

    return accounts
        .where((account) => account.department == selectedOrgDepartment)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  EmployeeAccount? get selectedOrgMember {
    final members = selectedDepartmentMembers;
    if (members.isEmpty) {
      return null;
    }

    return members
            .where((account) => account.id == selectedOrgUserId)
            .firstOrNull ??
        members.first;
  }
}

class ApprovalDashboardController
    extends AsyncNotifier<ApprovalDashboardState> {
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

  void updateKeyword(String keyword) {
    _setState((current) => current.copyWith(keyword: keyword));
  }

  Future<void> refresh() async {
    _setState((current) => current);
  }

  Future<bool> login(String id, String password) async {
    final current = state.asData?.value;
    if (current == null) {
      return false;
    }

    final account = current.accounts
        .where((item) => item.id == id && item.password == password)
        .firstOrNull;
    if (account == null) {
      _setState((value) => value.copyWith(loginError: '아이디 또는 비밀번호를 확인해 주세요.'));
      return false;
    }

    _setState(
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
    final current = state.asData?.value;
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

    _setState(
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
    _setState(
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
    _setState((current) => current.copyWith(loginError: ''));
  }

  void adjustZoom(double delta) {
    _setState((current) {
      final next = (current.zoom + delta).clamp(0.85, 1.55);
      return current.copyWith(zoom: next);
    });
  }

  void setDepartment(String department) {
    _setState((current) {
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
    _setState((current) => current.copyWith(selectedOrgUserId: userId));
  }

  ApprovalDocument buildDraftDocument(String formId) {
    final current = state.asData?.value;
    final user = current?.currentUser;
    final template = current?.formTemplates
        .where((item) => item.id == formId)
        .firstOrNull;
    if (current == null || user == null || template == null) {
      return _fallbackDraft;
    }

    final now = _today();
    return ApprovalDocument(
      id: 'DRAFT-$formId',
      title: template.defaultTitle,
      drafter: user.name,
      department: user.department,
      form: template.name,
      status: '작성중',
      draftedAt: now,
      dueDate: now,
      progress: 0,
      documentNo: '임시저장 전',
      effectiveDate: now,
      cooperationDepartment: template.cooperationDepartment,
      agreement: template.agreement,
      content: template.defaultContent,
      urgent: false,
      receivers: template.receivers,
      references: template.references,
      viewers: template.viewers,
      publicReceivers: template.publicReceivers,
      linkedDocuments: const [],
      steps: _buildStepsFor(user, current.accounts),
      histories: [
        ApprovalHistory(
          id: 'HIS-DRAFT-$formId',
          category: '결재문서 변경',
          date: '$now 09:00',
          user: '${user.name} ${user.position}',
          description: '새 기안 문서를 작성 시작',
          snapshot: template.defaultTitle,
        ),
      ],
    );
  }

  Future<String?> saveDraft({
    required String formId,
    String? documentId,
    required String title,
    required String content,
    required List<String> linkedDocuments,
  }) async {
    final current = state.asData?.value;
    final user = current?.currentUser;
    final template = current?.formTemplates
        .where((item) => item.id == formId)
        .firstOrNull;
    if (current == null || user == null || template == null) {
      return null;
    }

    final currentDocument = documentId == null
        ? null
        : current.documents.where((item) => item.id == documentId).firstOrNull;
    final id = currentDocument?.status == '작성중'
        ? currentDocument!.id
        : _nextDraftId(current.documents);
    final now = _today();

    final draft = ApprovalDocument(
      id: id,
      title: title,
      drafter: user.name,
      department: user.department,
      form: template.name,
      status: '작성중',
      draftedAt: currentDocument?.draftedAt ?? now,
      dueDate: now,
      progress: 0,
      documentNo: '임시저장',
      effectiveDate: now,
      cooperationDepartment: template.cooperationDepartment,
      agreement: template.agreement,
      content: content,
      urgent: currentDocument?.urgent ?? false,
      canReuse: true,
      canEdit: true,
      receivers: template.receivers,
      references: template.references,
      viewers: template.viewers,
      publicReceivers: template.publicReceivers,
      linkedDocuments: linkedDocuments,
      steps: _buildStepsFor(user, current.accounts),
      histories: [
        ApprovalHistory(
          id: 'HIS-SAVE-$id',
          category: '결재문서 변경',
          date: '$now 09:10',
          user: '${user.name} ${user.position}',
          description: '임시 저장',
          snapshot: title,
        ),
      ],
    );

    _setState((value) {
      final documents = [
        ...value.documents.where((item) => item.id != id),
        draft,
      ]..sort((a, b) => b.draftedAt.compareTo(a.draftedAt));
      return value.copyWith(documents: documents);
    });
    return id;
  }

  Future<String?> requestApproval({
    String? documentId,
    required ApprovalRequestDraft draft,
  }) async {
    final current = state.asData?.value;
    final user = current?.currentUser;
    final template = current?.formTemplates
        .where((item) => item.id == draft.formId)
        .firstOrNull;
    if (current == null || user == null || template == null) {
      return null;
    }

    final sourceDocument = documentId == null
        ? null
        : current.documents.where((item) => item.id == documentId).firstOrNull;
    final isEditableDraft = sourceDocument?.status == '작성중';
    final id = isEditableDraft == true
        ? sourceDocument!.id
        : _nextApprovalId(current.documents);
    final today = _today();
    final steps = _submitSteps(user, current.accounts);
    final document = ApprovalDocument(
      id: id,
      title: draft.title,
      drafter: user.name,
      department: user.department,
      form: template.name,
      status: '결재대기',
      draftedAt: sourceDocument?.draftedAt ?? today,
      dueDate: _dueDate(days: 3),
      progress: _progressFor(steps),
      documentNo: id,
      effectiveDate: _dueDate(days: 3),
      cooperationDepartment: template.cooperationDepartment,
      agreement: template.agreement,
      content: draft.content,
      urgent: draft.urgent,
      receivedRequest: true,
      canCancel: true,
      canReuse: true,
      canEdit: false,
      receivers: template.receivers,
      references: template.references,
      viewers: template.viewers,
      publicReceivers: template.publicReceivers,
      linkedDocuments: draft.linkedDocuments,
      steps: steps,
      histories: [
        ApprovalHistory(
          id: 'HIS-REQ-$id',
          category: '결재문서 변경',
          date: '$today 09:20',
          user: '${user.name} ${user.position}',
          description: '결재 요청 상신',
          snapshot: draft.title,
        ),
      ],
    );

    _setState((value) {
      final documents = [
        ...value.documents.where((item) => item.id != document.id),
        document,
      ]..sort((a, b) => b.draftedAt.compareTo(a.draftedAt));
      return value.copyWith(documents: documents);
    });

    return id;
  }

  Future<void> approveDocument(
    String documentId, {
    required String action,
    required String opinion,
  }) async {
    final current = state.asData?.value;
    final user = current?.currentUser;
    if (current == null || user == null) {
      return;
    }

    final document = current.documents
        .where((item) => item.id == documentId)
        .firstOrNull;
    if (document == null) {
      return;
    }

    final activeIndex = document.steps.indexWhere(
      (step) => step.status == '진행중',
    );
    if (activeIndex == -1) {
      return;
    }

    final activeStep = document.steps[activeIndex];
    if (!user.isAdmin && activeStep.name != user.name) {
      return;
    }

    final today = _today();
    final updatedSteps = [...document.steps];
    if (action == '반려') {
      updatedSteps[activeIndex] = activeStep.copyWith(
        status: '반려',
        approvedAt: '$today 09:30',
      );
      final rejectedDocument = document.copyWith(
        status: '반려',
        canCancel: false,
        canEdit: true,
        progress: _progressFor(updatedSteps),
        steps: updatedSteps,
        histories: [
          ApprovalHistory(
            id: 'HIS-REJECT-${document.id}',
            category: '결재문서 변경',
            date: '$today 09:30',
            user: '${user.name} ${user.position}',
            description: opinion.isEmpty ? '반려' : '반려: $opinion',
            snapshot: document.title,
          ),
          ...document.histories,
        ],
      );
      _replaceDocument(rejectedDocument);
      return;
    }

    updatedSteps[activeIndex] = activeStep.copyWith(
      status: '완료',
      approvedAt: '$today 09:30',
    );

    final nextIndex = activeIndex + 1;
    var status = '완료';
    if (nextIndex < updatedSteps.length) {
      updatedSteps[nextIndex] = updatedSteps[nextIndex].copyWith(status: '진행중');
      status = '결재대기';
    }

    final completedAfterSubmit = updatedSteps
        .skip(1)
        .where((step) => step.status == '완료')
        .isNotEmpty;

    final approvedDocument = document.copyWith(
      status: status,
      canCancel: !completedAfterSubmit && status != '완료',
      canEdit: false,
      progress: _progressFor(updatedSteps),
      steps: updatedSteps,
      histories: [
        ApprovalHistory(
          id: 'HIS-APPROVE-${document.id}',
          category: '결재문서 변경',
          date: '$today 09:30',
          user: '${user.name} ${user.position}',
          description: opinion.isEmpty ? '승인' : '승인: $opinion',
          snapshot: document.title,
        ),
        ...document.histories,
      ],
    );

    _replaceDocument(approvedDocument);
  }

  Future<void> cancelSubmission(String documentId) async {
    final current = state.asData?.value;
    final user = current?.currentUser;
    if (current == null || user == null) {
      return;
    }

    final document = current.documents
        .where((item) => item.id == documentId)
        .firstOrNull;
    if (document == null) {
      return;
    }

    if (!user.isAdmin && document.drafter != user.name) {
      return;
    }

    if (!document.canCancel) {
      return;
    }

    final hasApprovedFollower = document.steps
        .skip(1)
        .any((step) => step.status == '완료');
    if (hasApprovedFollower) {
      return;
    }

    final reverted = document.copyWith(
      status: '작성중',
      progress: 0,
      receivedRequest: false,
      canCancel: false,
      canEdit: true,
      documentNo: '임시저장',
      steps: _buildStepsFor(
        current.accounts
            .where((account) => account.name == document.drafter)
            .first,
        current.accounts,
      ),
      histories: [
        ApprovalHistory(
          id: 'HIS-CANCEL-${document.id}',
          category: '결재문서 변경',
          date: '${_today()} 09:40',
          user: '${user.name} ${user.position}',
          description: '상신 취소',
          snapshot: document.title,
        ),
        ...document.histories,
      ],
    );
    _replaceDocument(reverted);
  }

  void _replaceDocument(ApprovalDocument document) {
    _setState((current) {
      final documents = [
        ...current.documents.where((item) => item.id != document.id),
        document,
      ]..sort((a, b) => b.draftedAt.compareTo(a.draftedAt));
      return current.copyWith(documents: documents);
    });
  }

  void _setState(
    ApprovalDashboardState Function(ApprovalDashboardState current) update,
  ) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    state = AsyncData(update(current));
  }

  List<ApprovalStep> _buildStepsFor(
    EmployeeAccount drafter,
    List<EmployeeAccount> accounts,
  ) {
    final chain = _approvalChain(drafter, accounts);
    return [
      ApprovalStep(
        name: drafter.name,
        department: drafter.department,
        type: '신청',
        role: drafter.position,
        status: '기안',
      ),
      ...chain.map(
        (account) => ApprovalStep(
          name: account.name,
          department: account.department,
          type: '승인',
          role: account.position,
          status: '결재 예정',
        ),
      ),
    ];
  }

  List<ApprovalStep> _submitSteps(
    EmployeeAccount drafter,
    List<EmployeeAccount> accounts,
  ) {
    final draftSteps = _buildStepsFor(drafter, accounts);
    if (draftSteps.isEmpty) {
      return draftSteps;
    }

    final steps = [...draftSteps];
    steps[0] = steps[0].copyWith(status: '완료', approvedAt: '${_today()} 09:20');
    if (steps.length > 1) {
      steps[1] = steps[1].copyWith(status: '진행중');
    }
    return steps;
  }

  List<EmployeeAccount> _approvalChain(
    EmployeeAccount drafter,
    List<EmployeeAccount> accounts,
  ) {
    final managerMap = <String, List<String>>{
      '교육관리팀': ['lee_jaeo', 'kim_kyunyoung'],
      '마케팅팀': ['kim_kyunyoung'],
      '개발팀': ['kim_kyunyoung'],
      '인사팀': ['kim_kyunyoung'],
      '기획팀': ['kim_kyunyoung'],
      '운영팀': ['kim_kyunyoung'],
      '경영관리팀': ['admin_master'],
    };
    final ids =
        managerMap[drafter.department] ??
        accounts
            .where((account) => account.isAdmin)
            .map((item) => item.id)
            .toList();
    final approvers = accounts
        .where(
          (account) => ids.contains(account.id) && account.id != drafter.id,
        )
        .toList();
    if (approvers.isNotEmpty) {
      return approvers;
    }

    return accounts
        .where((account) => account.id != drafter.id)
        .take(1)
        .toList();
  }

  int _progressFor(List<ApprovalStep> steps) {
    if (steps.isEmpty) {
      return 0;
    }

    final completed = steps.where((step) => step.status == '완료').length;
    return ((completed / steps.length) * 100).round();
  }
}

const _frequentForms = [
  ApprovalForm(
    id: 'team-vacation',
    name: '팀 휴가 결재서',
    description: '팀 단위 휴가 일정 승인',
    recentCount: 12,
  ),
  ApprovalForm(
    id: 'expense-slip',
    name: '지출 결의서(지급품의)',
    description: '비용 지급 승인',
    recentCount: 9,
  ),
  ApprovalForm(
    id: 'business-draft',
    name: '업무기안[기본양식]',
    description: '일반 기안 문서',
    recentCount: 15,
  ),
];

const _templates = [
  ApprovalFormTemplate(
    id: 'business-draft',
    category: '지원',
    name: '업무기안[기본양식]',
    description: '일반 기안 작성',
    defaultTitle: '정산을 위한 운영인력 충원의 건',
    defaultContent:
        '신규 콘텐츠 마케팅 진행에 따라 원활한 정산을 위한 운영 인력 채용 또는 내부 인력 배정을 요청드립니다.\n\n1. 요청 인원: 1명\n2. 필요 업무: 실시간 업무지원, 회계 처리, 세금계산서 대응\n3. 요청 사유: 캠페인 집행 증가에 따른 운영 부담 완화',
    receivers: ['경영관리팀'],
    references: ['부서장'],
    viewers: ['운영지원 담당자'],
    publicReceivers: ['다우기술'],
    cooperationDepartment: '경영관리팀',
    agreement: '순차합의',
  ),
  ApprovalFormTemplate(
    id: 'expense-slip',
    category: '회계',
    name: '지출 결의서(지급품의)',
    description: '비용 지급 승인',
    defaultTitle: '교육장 기자재 대여 비용 집행 요청',
    defaultContent:
        '교육장 실습 장비 대여 비용 집행 승인을 요청드립니다.\n\n1. 대여 장비: 노트북 12대, 프로젝터 2대\n2. 사용 일정: 2026-07-03 ~ 2026-07-05\n3. 요청 금액: 2,850,000원',
    receivers: ['재경팀'],
    references: ['교육관리팀 부장'],
    viewers: ['교육 대상자'],
    publicReceivers: ['다우기술'],
    cooperationDepartment: '재경팀',
    agreement: '예산 확인 후 지급',
  ),
  ApprovalFormTemplate(
    id: 'purchase-request',
    category: '지원',
    name: '구매 요청서',
    description: '비품 및 장비 구매 요청',
    defaultTitle: '업무용 PC 구매 예산 할당 요청',
    defaultContent:
        '업무용 PC 구매 예산 할당 요청 재가 바랍니다.\n\n1. 구매 목적: 노후 PC 교체 및 교육 실습 장비 확보\n2. 구매 품목: 데스크톱 PC 6대, 모니터 6대\n3. 예산 요청: 9,600,000원',
    receivers: ['재경팀'],
    references: ['교육관리팀 부장', '구매 담당자'],
    viewers: ['교육관리팀 구성원'],
    publicReceivers: ['다우기술'],
    cooperationDepartment: '재경팀',
    agreement: '합의 후 구매 진행',
  ),
  ApprovalFormTemplate(
    id: 'team-vacation',
    category: '근태',
    name: '팀 휴가 결재서',
    description: '팀 휴가 일정 승인',
    defaultTitle: '7월 교육관리팀 팀 휴가 일정 승인',
    defaultContent:
        '교육관리팀 7월 휴가 일정을 아래와 같이 상신합니다.\n\n1. 휴가 기간: 2026-07-08 ~ 2026-07-12\n2. 대상자: 교육강사, 교육관리자, 운영지원 담당자\n3. 업무 인수인계: 이재오 차장이 교육 문의 1차 대응\n4. 요청사항: 팀 휴가 일정 승인 및 인사관리팀 공유',
    receivers: ['인사관리팀'],
    references: ['교육관리팀 부장', '운영지원 담당자'],
    viewers: ['교육관리팀 구성원'],
    publicReceivers: ['다우기술'],
    cooperationDepartment: '인사관리팀',
    agreement: '팀 운영 일정 확인',
  ),
  ApprovalFormTemplate(
    id: 'cooperation-request',
    category: '협조',
    name: '업무협조[기본양식]',
    description: '타 부서 협조 요청',
    defaultTitle: '신규 교육 과정 운영 협조 요청',
    defaultContent:
        '신규 교육 과정 운영을 위한 부서 협조를 요청드립니다.\n\n1. 운영 일정: 2026-07-15 ~ 2026-07-30\n2. 협조 요청 부서: 운영팀, 재경팀\n3. 요청사항: 일정 공유 및 예산 집행 검토',
    receivers: ['운영팀'],
    references: ['교육관리팀 부장'],
    viewers: ['경영지원팀'],
    publicReceivers: ['다우기술'],
    cooperationDepartment: '운영팀',
    agreement: '협조 승인',
  ),
];

const _accounts = [
  EmployeeAccount(
    id: 'edu_teacher',
    password: '1234',
    name: '교육강사',
    department: '교육관리팀',
    position: '대리',
    email: 'edu_teacher@thewe.co.kr',
  ),
  EmployeeAccount(
    id: 'edu_manager',
    password: '1234',
    name: '교육관리자',
    department: '교육관리팀',
    position: '과장',
    email: 'edu_manager@thewe.co.kr',
  ),
  EmployeeAccount(
    id: 'lee_jaeo',
    password: '1234',
    name: '이재오',
    department: '교육관리팀',
    position: '차장',
    email: 'lee_jaeo@thewe.co.kr',
  ),
  EmployeeAccount(
    id: 'kim_kyunyoung',
    password: '1234',
    name: '김경영',
    department: '경영관리팀',
    position: '상무',
    email: 'kim_kyunyoung@thewe.co.kr',
  ),
  EmployeeAccount(
    id: 'jiyun',
    password: '1234',
    name: '정지윤',
    department: '마케팅팀',
    position: '대리',
    email: 'jiyun@thewe.co.kr',
  ),
  EmployeeAccount(
    id: 'han_dev',
    password: '1234',
    name: '한유진',
    department: '개발팀',
    position: '과장',
    email: 'han_dev@thewe.co.kr',
  ),
  EmployeeAccount(
    id: 'admin_master',
    password: 'admin1234',
    name: '시스템관리자',
    department: '경영관리팀',
    position: '관리자',
    email: 'admin@thewe.co.kr',
    isAdmin: true,
  ),
];

final _seedDocuments = [
  ApprovalDocument(
    id: 'APR-260629-001',
    title: '업무용 PC 구매 예산 할당 요청',
    drafter: '교육강사',
    department: '교육관리팀',
    form: '구매 요청서',
    status: '결재대기',
    draftedAt: '2026-06-29',
    dueDate: '2026-07-02',
    progress: 33,
    documentNo: 'APR-260629-001',
    effectiveDate: '2026-07-02',
    cooperationDepartment: '재경팀',
    agreement: '합의 후 구매 진행',
    content:
        '업무용 PC 구매 예산 할당 요청 재가 바랍니다.\n\n1. 구매 목적: 노후 PC 교체 및 교육 실습 장비 확보\n2. 구매 품목: 데스크톱 PC 6대, 모니터 6대\n3. 예산 요청: 9,600,000원',
    urgent: true,
    receivedRequest: true,
    canCancel: true,
    receivers: ['재경팀'],
    references: ['교육관리팀 부장', '구매 담당자'],
    viewers: ['교육관리팀 구성원'],
    publicReceivers: ['다우기술'],
    linkedDocuments: ['구매 사양서.pdf'],
    steps: [
      ApprovalStep(
        name: '교육강사',
        department: '교육관리팀',
        type: '신청',
        role: '대리',
        status: '완료',
        approvedAt: '2026-06-29 09:20',
      ),
      ApprovalStep(
        name: '이재오',
        department: '교육관리팀',
        type: '승인',
        role: '차장',
        status: '진행중',
      ),
      ApprovalStep(
        name: '김경영',
        department: '경영관리팀',
        type: '승인',
        role: '상무',
        status: '결재 예정',
      ),
    ],
    histories: [
      ApprovalHistory(
        id: 'HIS-260629-001',
        category: '결재문서 변경',
        date: '2026-06-29 09:20',
        user: '교육강사 대리',
        description: '결재 요청 상신',
        snapshot: '업무용 PC 구매 예산 할당 요청',
      ),
    ],
  ),
  ApprovalDocument(
    id: 'APR-260628-002',
    title: '지출결의서(지급품의) 6월 교육 기자재 대여비',
    drafter: '교육관리자',
    department: '교육관리팀',
    form: '지출 결의서(지급품의)',
    status: '결재대기',
    draftedAt: '2026-06-28',
    dueDate: '2026-07-01',
    progress: 67,
    documentNo: 'APR-260628-002',
    effectiveDate: '2026-07-01',
    cooperationDepartment: '재경팀',
    agreement: '예산 확인 후 지급',
    content:
        '교육 기자재 대여 비용에 대한 지급 승인을 요청드립니다.\n\n1. 대여처: 위드렌탈\n2. 사용 장비: 노트북 12대, 프로젝터 2대\n3. 지급 요청 금액: 2,850,000원',
    receivedRequest: true,
    canCancel: false,
    receivers: ['재경팀'],
    references: ['교육관리팀 부장'],
    viewers: ['교육 대상자'],
    publicReceivers: ['다우기술'],
    linkedDocuments: ['견적서.pdf', '계약서.pdf'],
    steps: [
      ApprovalStep(
        name: '교육관리자',
        department: '교육관리팀',
        type: '신청',
        role: '과장',
        status: '완료',
        approvedAt: '2026-06-28 13:00',
      ),
      ApprovalStep(
        name: '이재오',
        department: '교육관리팀',
        type: '승인',
        role: '차장',
        status: '완료',
        approvedAt: '2026-06-29 08:30',
      ),
      ApprovalStep(
        name: '김경영',
        department: '경영관리팀',
        type: '승인',
        role: '상무',
        status: '진행중',
      ),
    ],
    histories: [
      ApprovalHistory(
        id: 'HIS-260628-002',
        category: '결재문서 변경',
        date: '2026-06-29 08:30',
        user: '이재오 차장',
        description: '1차 승인 완료',
        snapshot: '지출결의서(지급품의) 6월 교육 기자재 대여비',
      ),
    ],
  ),
  ApprovalDocument(
    id: 'APR-260627-003',
    title: '6월 마케팅 캠페인 예산 승인',
    drafter: '정지윤',
    department: '마케팅팀',
    form: '지출 결의서(지급품의)',
    status: '완료',
    draftedAt: '2026-06-27',
    dueDate: '2026-06-29',
    progress: 100,
    documentNo: 'APR-260627-003',
    effectiveDate: '2026-06-29',
    cooperationDepartment: '재무팀',
    agreement: '예산 범위 내 집행',
    content: '6월 마케팅 캠페인 진행에 필요한 광고비와 운영비 집행 승인을 요청드립니다.',
    receivedRequest: true,
    canCancel: false,
    receivers: ['재무팀'],
    references: ['마케팅팀장'],
    viewers: ['시스템관리자'],
    publicReceivers: ['다우기술'],
    linkedDocuments: ['캠페인 운영안.pdf'],
    steps: [
      ApprovalStep(
        name: '정지윤',
        department: '마케팅팀',
        type: '신청',
        role: '대리',
        status: '완료',
        approvedAt: '2026-06-27 10:00',
      ),
      ApprovalStep(
        name: '김경영',
        department: '경영관리팀',
        type: '승인',
        role: '상무',
        status: '완료',
        approvedAt: '2026-06-28 09:10',
      ),
    ],
    histories: [
      ApprovalHistory(
        id: 'HIS-260627-003',
        category: '결재문서 변경',
        date: '2026-06-28 09:10',
        user: '김경영 상무',
        description: '최종 승인 완료',
        snapshot: '6월 마케팅 캠페인 예산 승인',
      ),
    ],
  ),
  ApprovalDocument(
    id: 'APR-260630-004',
    title: '운영지원 소모품 구매 승인 요청',
    drafter: '한유진',
    department: '개발팀',
    form: '구매 요청서',
    status: '결재대기',
    draftedAt: '2026-06-30',
    dueDate: '2026-07-03',
    progress: 50,
    documentNo: 'APR-260630-004',
    effectiveDate: '2026-07-03',
    cooperationDepartment: '경영관리팀',
    agreement: '구매 검토 후 진행',
    content:
        '운영지원에 필요한 소모품 구매 승인을 요청드립니다.\n\n1. 구매 품목: 회의실 소모품 및 케이블류\n2. 사용 부서: 개발팀, 교육관리팀\n3. 요청 금액: 680,000원',
    receivedRequest: true,
    canCancel: false,
    receivers: ['교육관리팀'],
    references: ['교육관리자'],
    viewers: ['교육강사'],
    publicReceivers: ['다우기술'],
    linkedDocuments: ['소모품 견적서.pdf'],
    steps: [
      ApprovalStep(
        name: '한유진',
        department: '개발팀',
        type: '신청',
        role: '과장',
        status: '완료',
        approvedAt: '2026-06-30 09:30',
      ),
      ApprovalStep(
        name: '교육강사',
        department: '교육관리팀',
        type: '승인',
        role: '대리',
        status: '진행중',
      ),
      ApprovalStep(
        name: '김경영',
        department: '경영관리팀',
        type: '승인',
        role: '상무',
        status: '결재 예정',
      ),
    ],
    histories: [
      ApprovalHistory(
        id: 'HIS-260630-004',
        category: '결재문서 변경',
        date: '2026-06-30 09:30',
        user: '한유진 과장',
        description: '결재 요청 상신',
        snapshot: '운영지원 소모품 구매 승인 요청',
      ),
    ],
  ),
  ApprovalDocument(
    id: 'APR-260630-005',
    title: '교육관리팀 외부 세미나 참석 계획',
    drafter: '이재오',
    department: '교육관리팀',
    form: '업무기안[기본양식]',
    status: '결재대기',
    draftedAt: '2026-06-30',
    dueDate: '2026-07-04',
    progress: 50,
    documentNo: 'APR-260630-005',
    effectiveDate: '2026-07-04',
    cooperationDepartment: '교육관리팀',
    agreement: '부서 일정 확인',
    content:
        '교육관리팀 외부 세미나 참석 계획을 공유하고 결재를 요청드립니다.\n\n1. 참석 일정: 2026-07-10\n2. 참석자: 교육강사, 교육관리자\n3. 목적: 신규 교육 과정 벤치마킹',
    receivedRequest: true,
    canCancel: false,
    receivers: ['경영관리팀'],
    references: ['교육강사'],
    viewers: ['교육관리자'],
    publicReceivers: ['다우기술'],
    linkedDocuments: ['세미나 안내문.pdf'],
    steps: [
      ApprovalStep(
        name: '이재오',
        department: '교육관리팀',
        type: '신청',
        role: '차장',
        status: '완료',
        approvedAt: '2026-06-30 10:10',
      ),
      ApprovalStep(
        name: '김경영',
        department: '경영관리팀',
        type: '승인',
        role: '상무',
        status: '진행중',
      ),
      ApprovalStep(
        name: '교육강사',
        department: '교육관리팀',
        type: '열람',
        role: '대리',
        status: '결재 예정',
      ),
    ],
    histories: [
      ApprovalHistory(
        id: 'HIS-260630-005',
        category: '결재문서 변경',
        date: '2026-06-30 10:10',
        user: '이재오 차장',
        description: '결재 요청 상신',
        snapshot: '교육관리팀 외부 세미나 참석 계획',
      ),
    ],
  ),
  ApprovalDocument(
    id: 'DRF-260629-001',
    title: '하반기 교육 커리큘럼 개편안',
    drafter: '교육강사',
    department: '교육관리팀',
    form: '업무기안[기본양식]',
    status: '작성중',
    draftedAt: '2026-06-29',
    dueDate: '2026-06-29',
    progress: 0,
    documentNo: '임시저장',
    effectiveDate: '2026-06-29',
    cooperationDepartment: '교육관리팀',
    agreement: '검토 후 진행',
    content:
        '하반기 교육 커리큘럼 개편안 초안을 작성 중입니다.\n\n1. 신규 과정 3종 추가\n2. 실습 비중 확대\n3. 사전 설문 반영',
    canEdit: true,
    receivers: ['교육관리팀'],
    references: ['이재오'],
    viewers: ['교육관리자'],
    publicReceivers: ['다우기술'],
    linkedDocuments: [],
    steps: [
      ApprovalStep(
        name: '교육강사',
        department: '교육관리팀',
        type: '신청',
        role: '대리',
        status: '기안',
      ),
      ApprovalStep(
        name: '이재오',
        department: '교육관리팀',
        type: '승인',
        role: '차장',
        status: '결재 예정',
      ),
      ApprovalStep(
        name: '김경영',
        department: '경영관리팀',
        type: '승인',
        role: '상무',
        status: '결재 예정',
      ),
    ],
  ),
];

const _fallbackDraft = ApprovalDocument(
  id: 'DRAFT-FALLBACK',
  title: '기안 문서',
  drafter: '사용자',
  department: '부서',
  form: '업무기안[기본양식]',
  status: '작성중',
  draftedAt: '2026-06-29',
  dueDate: '2026-06-29',
  progress: 0,
  documentNo: '임시저장 전',
  effectiveDate: '2026-06-29',
  content: '',
  steps: [],
);

String _today() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}

String _dueDate({required int days}) {
  final date = DateTime.now().add(Duration(days: days));
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _nextApprovalId(List<ApprovalDocument> documents) {
  final approvals = documents
      .where((document) => document.id.startsWith('APR-'))
      .length;
  final suffix = (approvals + 1).toString().padLeft(3, '0');
  return 'APR-${_today().replaceAll('-', '')}-$suffix';
}

String _nextDraftId(List<ApprovalDocument> documents) {
  final drafts = documents
      .where((document) => document.id.startsWith('DRF-'))
      .length;
  final suffix = (drafts + 1).toString().padLeft(3, '0');
  return 'DRF-${_today().replaceAll('-', '')}-$suffix';
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
