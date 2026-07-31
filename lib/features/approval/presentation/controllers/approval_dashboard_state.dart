part of 'approval_providers.dart';

class ApprovalDashboardState {
  const ApprovalDashboardState({
    required this.accounts,
    required this.frequentForms,
    required this.formTemplates,
    required this.documents,
    required this.annualLeaveByYear,
    this.currentUser,
    this.keyword = '',
    this.zoom = 1.0,
    this.loginError = '',
    this.selectedOrgDepartment = '',
    this.selectedOrgUserId,
    this.adminMode = false,
    this.restrictedDocumentIds = const <String>{},
    this.leaveRequests = const <LeaveRequest>[],
    this.portalName = '더우리기술 전자결재',
    this.enabledAppIds = const <String>{
      PortalAppId.approval,
      PortalAppId.attendance,
      PortalAppId.leave,
    },
    this.disabledFormTemplateIds = const <String>{},
  });

  final List<EmployeeAccount> accounts;
  final List<ApprovalForm> frequentForms;
  final List<ApprovalFormTemplate> formTemplates;
  final List<ApprovalDocument> documents;
  final Map<int, int> annualLeaveByYear;
  final EmployeeAccount? currentUser;
  final String keyword;
  final double zoom;
  final String loginError;
  final String selectedOrgDepartment;
  final String? selectedOrgUserId;
  final bool adminMode;
  final Set<String> restrictedDocumentIds;
  final List<LeaveRequest> leaveRequests;
  final String portalName;
  final Set<String> enabledAppIds;
  final Set<String> disabledFormTemplateIds;

  ApprovalDashboardState copyWith({
    List<EmployeeAccount>? accounts,
    List<ApprovalForm>? frequentForms,
    List<ApprovalFormTemplate>? formTemplates,
    List<ApprovalDocument>? documents,
    Map<int, int>? annualLeaveByYear,
    EmployeeAccount? currentUser,
    bool clearCurrentUser = false,
    String? keyword,
    double? zoom,
    String? loginError,
    String? selectedOrgDepartment,
    String? selectedOrgUserId,
    bool clearSelectedOrgUser = false,
    bool? adminMode,
    Set<String>? restrictedDocumentIds,
    List<LeaveRequest>? leaveRequests,
    String? portalName,
    Set<String>? enabledAppIds,
    Set<String>? disabledFormTemplateIds,
  }) {
    return ApprovalDashboardState(
      accounts: accounts ?? this.accounts,
      frequentForms: frequentForms ?? this.frequentForms,
      formTemplates: formTemplates ?? this.formTemplates,
      documents: documents ?? this.documents,
      annualLeaveByYear: annualLeaveByYear ?? this.annualLeaveByYear,
      currentUser: clearCurrentUser ? null : (currentUser ?? this.currentUser),
      keyword: keyword ?? this.keyword,
      zoom: zoom ?? this.zoom,
      loginError: loginError ?? this.loginError,
      selectedOrgDepartment:
          selectedOrgDepartment ?? this.selectedOrgDepartment,
      selectedOrgUserId: clearSelectedOrgUser
          ? null
          : (selectedOrgUserId ?? this.selectedOrgUserId),
      adminMode: adminMode ?? this.adminMode,
      restrictedDocumentIds:
          restrictedDocumentIds ?? this.restrictedDocumentIds,
      leaveRequests: leaveRequests ?? this.leaveRequests,
      portalName: portalName ?? this.portalName,
      enabledAppIds: enabledAppIds ?? this.enabledAppIds,
      disabledFormTemplateIds:
          disabledFormTemplateIds ?? this.disabledFormTemplateIds,
    );
  }

  bool get isAuthenticated => currentUser != null;

  bool get isAdmin => currentUser?.isAdmin ?? false;

  bool get isAdminMode => isAdmin && adminMode;

  bool isAppEnabled(String appId) => enabledAppIds.contains(appId);

  List<ApprovalFormTemplate> get activeFormTemplates => formTemplates
      .where((template) => !disabledFormTemplateIds.contains(template.id))
      .toList();

  List<ApprovalForm> get activeFrequentForms {
    if (!isAppEnabled(PortalAppId.approval)) return const [];
    final activeIds = activeFormTemplates
        .map((template) => template.id)
        .toSet();
    return frequentForms.where((form) => activeIds.contains(form.id)).toList();
  }

  List<ApprovalDocument> get visibleDocuments {
    final user = currentUser;
    if (user == null) {
      return const [];
    }

    if (isAdminMode) {
      return documents;
    }

    return documents.where((document) {
      final isDrafter = document.drafter == user.name;
      final isApprover = document.steps.any((step) => step.name == user.name);
      final isReader =
          document.references.contains(user.name) ||
          document.viewers.contains(user.name);
      final isDepartmentDocument = document.department == user.department;
      final isRestricted = restrictedDocumentIds.contains(document.id);
      return isDrafter ||
          isApprover ||
          isReader ||
          (isDepartmentDocument && !isRestricted);
    }).toList();
  }

  List<ApprovalDocument> get authoredDocuments {
    final user = currentUser;
    if (user == null) {
      return const [];
    }

    if (isAdminMode) {
      return documents;
    }

    return documents
        .where((document) => document.drafter == user.name)
        .toList();
  }

  List<ApprovalDocument> get sharedDraftDocuments {
    return [...documents]..sort((a, b) => b.draftedAt.compareTo(a.draftedAt));
  }

  List<ApprovalDocument> get departmentDocuments {
    final user = currentUser;
    if (user == null) return const [];
    final result = documents.where((document) {
      if (isAdminMode) return true;
      if (document.department != user.department) return false;
      if (!restrictedDocumentIds.contains(document.id)) return true;
      return document.drafter == user.name ||
          document.steps.any((step) => step.name == user.name);
    }).toList()..sort((a, b) => b.draftedAt.compareTo(a.draftedAt));
    return result;
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

      return isAdminMode ? true : activeStep.name == user.name;
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
      return isAdminMode ? document.status == '결재대기' : scheduled;
    }).toList();
  }

  List<ApprovalDocument> get referenceDocuments {
    final user = currentUser;
    if (user == null) {
      return const [];
    }

    if (isAdminMode) {
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

  List<ApprovalDocument> get receivedDocuments {
    return visibleDocuments
        .where((document) => document.receivedRequest)
        .toList()
      ..sort((a, b) => b.draftedAt.compareTo(a.draftedAt));
  }

  ApprovalDashboard get dashboard => ApprovalDashboard(
    pendingCount: waitingDocuments.length,
    receivedCount: receivedDocuments.length,
    referenceCount: referenceDocuments.length,
    scheduledCount: scheduledDocuments.length,
    frequentForms: activeFrequentForms,
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

  List<LeaveRequest> get currentUserLeaveRequests {
    final id = currentUser?.id;
    if (id == null) return const [];
    return leaveRequests.where((request) => request.userId == id).toList();
  }

  int get currentServiceYear {
    final hireDate = DateTime.tryParse(currentUser?.hireDate ?? '');
    if (hireDate == null) return 1;
    final now = DateTime.now();
    var years = now.year - hireDate.year;
    if (now.month < hireDate.month ||
        (now.month == hireDate.month && now.day < hireDate.day)) {
      years--;
    }
    return (years + 1).clamp(1, 99);
  }

  int get totalAnnualLeave =>
      annualLeaveByYear[currentServiceYear.clamp(1, 10)] ??
      annualLeaveByYear[10] ??
      19;

  double get usedAnnualLeave => currentUserLeaveRequests
      .where((request) => request.status == '승인완료')
      .fold(0, (sum, request) => sum + request.days);

  double get pendingAnnualLeave => currentUserLeaveRequests
      .where((request) => request.status == '승인대기')
      .fold(0, (sum, request) => sum + request.days);

  double get remainingAnnualLeave =>
      (totalAnnualLeave - usedAnnualLeave - pendingAnnualLeave)
          .clamp(0, totalAnnualLeave)
          .toDouble();
}
