import 'dart:typed_data';

import 'package:the_we_system/features/approval/presentation/controllers/approval_controller_models.dart';

class ApprovalDashboardState {
  const ApprovalDashboardState({
    required this.accounts,
    required this.frequentForms,
    required this.formTemplates,
    required this.documents,
    required this.annualLeaveByYear,
    this.notices = const <PortalNotice>[],
    this.organizationDepartments = const <String>[],
    this.monthlyLeavePerMonth = 1,
    this.currentUser,
    this.keyword = '',
    this.zoom = 1.0,
    this.loginError = '',
    this.selectedOrgDepartment = '',
    this.selectedOrgUserId,
    this.adminMode = false,
    this.restrictedDocumentIds = const <String>{},
    this.leaveRequests = const <LeaveRequest>[],
    this.acknowledgedLeaveRequestIds = const <String>{},
    this.portalName = '우리기술 전자결재',
    this.customLogoBytes,
    this.customLogoFileName,
    this.adminOtpEnabled = true,
    this.settingsPasswordEnabled = true,
    this.adminDocumentAccessEnabled = true,
    this.enabledAppIds = const <String>{
      PortalAppId.approval,
      PortalAppId.attendance,
      PortalAppId.leave,
    },
    this.disabledFormTemplateIds = const <String>{},
    this.organizationWideDocumentCategories = const <String>{
      '지원',
      '회계',
      '근태',
      '협조',
    },
    this.documentCategoryViewerIds = const <String, Set<String>>{},
    this.leaveApprovalLines = const <String, List<String>>{},
  });

  final List<EmployeeAccount> accounts;
  final List<ApprovalForm> frequentForms;
  final List<ApprovalFormTemplate> formTemplates;
  final List<ApprovalDocument> documents;
  final Map<int, int> annualLeaveByYear;
  final List<PortalNotice> notices;
  final List<String> organizationDepartments;
  final int monthlyLeavePerMonth;
  final EmployeeAccount? currentUser;
  final String keyword;
  final double zoom;
  final String loginError;
  final String selectedOrgDepartment;
  final String? selectedOrgUserId;
  final bool adminMode;
  final Set<String> restrictedDocumentIds;
  final List<LeaveRequest> leaveRequests;
  final Set<String> acknowledgedLeaveRequestIds;
  final String portalName;
  final Uint8List? customLogoBytes;
  final String? customLogoFileName;
  final bool adminOtpEnabled;
  final bool settingsPasswordEnabled;
  final bool adminDocumentAccessEnabled;
  final Set<String> enabledAppIds;
  final Set<String> disabledFormTemplateIds;
  final Set<String> organizationWideDocumentCategories;
  final Map<String, Set<String>> documentCategoryViewerIds;
  final Map<String, List<String>> leaveApprovalLines;

  ApprovalDashboardState copyWith({
    List<EmployeeAccount>? accounts,
    List<ApprovalForm>? frequentForms,
    List<ApprovalFormTemplate>? formTemplates,
    List<ApprovalDocument>? documents,
    Map<int, int>? annualLeaveByYear,
    List<PortalNotice>? notices,
    List<String>? organizationDepartments,
    int? monthlyLeavePerMonth,
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
    Set<String>? acknowledgedLeaveRequestIds,
    String? portalName,
    Uint8List? customLogoBytes,
    String? customLogoFileName,
    bool clearCustomLogo = false,
    bool? adminOtpEnabled,
    bool? settingsPasswordEnabled,
    bool? adminDocumentAccessEnabled,
    Set<String>? enabledAppIds,
    Set<String>? disabledFormTemplateIds,
    Set<String>? organizationWideDocumentCategories,
    Map<String, Set<String>>? documentCategoryViewerIds,
    Map<String, List<String>>? leaveApprovalLines,
  }) {
    return ApprovalDashboardState(
      accounts: accounts ?? this.accounts,
      frequentForms: frequentForms ?? this.frequentForms,
      formTemplates: formTemplates ?? this.formTemplates,
      documents: documents ?? this.documents,
      annualLeaveByYear: annualLeaveByYear ?? this.annualLeaveByYear,
      notices: notices ?? this.notices,
      organizationDepartments:
          organizationDepartments ?? this.organizationDepartments,
      monthlyLeavePerMonth: monthlyLeavePerMonth ?? this.monthlyLeavePerMonth,
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
      acknowledgedLeaveRequestIds:
          acknowledgedLeaveRequestIds ?? this.acknowledgedLeaveRequestIds,
      portalName: portalName ?? this.portalName,
      customLogoBytes: clearCustomLogo
          ? null
          : (customLogoBytes ?? this.customLogoBytes),
      customLogoFileName: clearCustomLogo
          ? null
          : (customLogoFileName ?? this.customLogoFileName),
      adminOtpEnabled: adminOtpEnabled ?? this.adminOtpEnabled,
      settingsPasswordEnabled:
          settingsPasswordEnabled ?? this.settingsPasswordEnabled,
      adminDocumentAccessEnabled:
          adminDocumentAccessEnabled ?? this.adminDocumentAccessEnabled,
      enabledAppIds: enabledAppIds ?? this.enabledAppIds,
      disabledFormTemplateIds:
          disabledFormTemplateIds ?? this.disabledFormTemplateIds,
      organizationWideDocumentCategories:
          organizationWideDocumentCategories ??
          this.organizationWideDocumentCategories,
      documentCategoryViewerIds:
          documentCategoryViewerIds ?? this.documentCategoryViewerIds,
      leaveApprovalLines: leaveApprovalLines ?? this.leaveApprovalLines,
    );
  }

  bool get isAuthenticated => currentUser != null;

  bool get isAdmin => currentUser?.canAccessAdminMode ?? false;

  bool get isAdminMode => isAdmin && adminMode;

  bool get hasAdminDocumentAccess => isAdminMode && adminDocumentAccessEnabled;

  bool get canManageNotices =>
      isAdminMode &&
      (currentUser?.canChangeAdminOtp == true ||
          currentUser?.isSystemAdministrator == true);

  bool isAppEnabled(String appId) => enabledAppIds.contains(appId);

  List<ApprovalFormTemplate> get activeFormTemplates => formTemplates
      .where((template) => !disabledFormTemplateIds.contains(template.id))
      .toList();

  List<ApprovalForm> get activeFrequentForms {
    if (!isAppEnabled(PortalAppId.approval)) return const [];
    final activeIds = activeFormTemplates
        .map((template) => template.id)
        .toSet();
    final forms =
        frequentForms
            .where(
              (form) => activeIds.contains(form.id) && form.recentCount > 0,
            )
            .toList()
          ..sort((left, right) {
            final countComparison = right.recentCount.compareTo(
              left.recentCount,
            );
            if (countComparison != 0) return countComparison;
            return left.name.compareTo(right.name);
          });
    return forms.take(5).toList();
  }

  List<ApprovalDocument> get visibleDocuments {
    final user = currentUser;
    if (user == null) {
      return const [];
    }

    return documents.where((document) {
      final isDrafter = document.drafter == user.name;
      final isApprover = document.steps.any((step) => step.name == user.name);
      if (document.status == '작성중') {
        return isDrafter;
      }
      final category = documentCategory(document);
      final hasCategoryAccess =
          isDocumentCategoryOrganizationWide(category) ||
          (documentCategoryViewerIds[category]?.contains(user.id) ?? false);
      final isRestricted = restrictedDocumentIds.contains(document.id);
      if (isRestricted) {
        return isDrafter || isApprover;
      }
      return isDrafter || isApprover || hasCategoryAccess;
    }).toList();
  }

  String documentCategory(ApprovalDocument document) {
    final template = formTemplates
        .where((item) => item.name == document.form)
        .firstOrNull;
    final category = template?.category ?? '';
    if (category.isNotEmpty) return category;
    if (document.documentLayout == ApprovalDocumentLayout.payroll ||
        document.documentLayout == ApprovalDocumentLayout.expense ||
        document.documentLayout == ApprovalDocumentLayout.hospitality) {
      return '회계';
    }
    if (document.form.contains('휴가')) return '근태';
    if (document.form.contains('협조')) return '협조';
    return '지원';
  }

  bool isDocumentCategoryOrganizationWide(String category) =>
      organizationWideDocumentCategories.contains(category) ||
      !documentCategoryViewerIds.containsKey(category);

  List<ApprovalDocument> get authoredDocuments {
    final user = currentUser;
    if (user == null) {
      return const [];
    }

    if (hasAdminDocumentAccess) {
      return documents;
    }

    return documents
        .where((document) => document.drafter == user.name)
        .toList();
  }

  List<ApprovalDocument> get sharedDraftDocuments {
    return [...visibleDocuments]
      ..sort((a, b) => b.draftedAt.compareTo(a.draftedAt));
  }

  List<ApprovalDocument> get departmentDocuments {
    final user = currentUser;
    if (user == null) return const [];
    final result = visibleDocuments.where((document) {
      if (document.department != user.department) return false;
      return true;
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

      return hasAdminDocumentAccess ? true : activeStep.name == user.name;
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
      return hasAdminDocumentAccess ? document.status == '결재대기' : scheduled;
    }).toList();
  }

  List<ApprovalDocument> get referenceDocuments {
    final user = currentUser;
    if (user == null) {
      return const [];
    }

    return visibleDocuments
        .where(
          (document) => _audienceIncludesCurrentUser([
            ...document.references,
            ...document.viewers,
          ], user),
        )
        .toList();
  }

  List<ApprovalDocument> get receivedDocuments {
    final user = currentUser;
    if (user == null) return const [];
    return visibleDocuments
        .where(
          (document) =>
              document.receivedRequest &&
              document.drafter != user.name &&
              _audienceIncludesCurrentUser(document.receivers, user),
        )
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
    final ordered = <String>[];
    for (final department in organizationDepartments) {
      final normalized = department.trim();
      if (normalized.isNotEmpty && !ordered.contains(normalized)) {
        ordered.add(normalized);
      }
    }
    final missing =
        accounts
            .where((account) => !account.isSystemAdministrator)
            .map((account) => account.department.trim())
            .where(
              (department) =>
                  department.isNotEmpty && !ordered.contains(department),
            )
            .toSet()
            .toList()
          ..sort(_compareDepartments);
    return [...ordered, ...missing];
  }

  List<EmployeeAccount> get selectedDepartmentMembers {
    if (selectedOrgDepartment.isEmpty) {
      return const [];
    }

    return accounts
        .where(
          (account) =>
              !account.isSystemAdministrator &&
              account.department.trim() == selectedOrgDepartment,
        )
        .toList()
      ..sort(compareEmployeeOrganizationOrder);
  }

  List<EmployeeAccount> get organizationOrderedAccounts {
    final departmentOrder = departments;
    return accounts.where((account) => !account.isSystemAdministrator).toList()
      ..sort((left, right) {
        final leftIndex = departmentOrder.indexOf(left.department.trim());
        final rightIndex = departmentOrder.indexOf(right.department.trim());
        final departmentComparison = leftIndex.compareTo(rightIndex);
        if (departmentComparison != 0) return departmentComparison;
        return compareEmployeeOrganizationOrder(left, right);
      });
  }

  List<String> reorderedDepartments(String department, int offset) {
    final ordered = departments;
    final currentIndex = ordered.indexOf(department);
    final targetIndex = currentIndex + offset;
    if (currentIndex < 0 || targetIndex < 0 || targetIndex >= ordered.length) {
      return ordered;
    }
    final reordered = [...ordered];
    final moved = reordered.removeAt(currentIndex);
    reordered.insert(targetIndex, moved);
    return reordered;
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

  List<LeaveRequest> get pendingLeaveRequests =>
      leaveRequests.where((request) => request.status == '승인대기').toList();

  List<LeaveRequest> get unacknowledgedApprovedLeaveRequests => leaveRequests
      .where(
        (request) =>
            request.status == '승인완료' &&
            !request.directEntry &&
            !acknowledgedLeaveRequestIds.contains(request.id),
      )
      .toList();

  List<LeaveRequest> get actionableLeaveRequests =>
      leaveRequests.where(canActOnLeave).toList();

  List<LeaveRequest> leaveRequestsFor(String userId) =>
      leaveRequests.where((request) => request.userId == userId).toList();

  int serviceYearFor(EmployeeAccount? account) {
    final hireDate = DateTime.tryParse(account?.hireDate ?? '');
    if (hireDate == null) return 1;
    final now = DateTime.now();
    var years = now.year - hireDate.year;
    if (now.month < hireDate.month ||
        (now.month == hireDate.month && now.day < hireDate.day)) {
      years--;
    }
    return years.clamp(1, 99);
  }

  int get currentServiceYear => serviceYearFor(currentUser);

  bool isUnderOneYear(EmployeeAccount? account) {
    final hireDate = DateTime.tryParse(account?.hireDate ?? '');
    if (hireDate == null) return false;
    final now = DateTime.now();
    final firstAnniversary = DateTime(
      hireDate.year + 1,
      hireDate.month,
      hireDate.day,
    );
    return now.isBefore(firstAnniversary);
  }

  int completedServiceMonthsFor(EmployeeAccount? account) {
    final hireDate = DateTime.tryParse(account?.hireDate ?? '');
    if (hireDate == null) return 0;
    final now = DateTime.now();
    var months = (now.year - hireDate.year) * 12 + now.month - hireDate.month;
    if (now.day < hireDate.day) months--;
    return months.clamp(0, 11);
  }

  int accruedMonthlyLeaveFor(EmployeeAccount? account) =>
      completedServiceMonthsFor(account) * monthlyLeavePerMonth;

  double annualLeaveDaysFor(EmployeeAccount account) =>
      (_annualLeaveDaysForServiceYear(serviceYearFor(account))).toDouble();

  int _annualLeaveDaysForServiceYear(int serviceYear) {
    if (annualLeaveByYear.isEmpty) return 19;
    final years = annualLeaveByYear.keys.toList()..sort();
    final applicable = years.where((year) => year <= serviceYear);
    final selectedYear = applicable.isEmpty ? years.first : applicable.last;
    return annualLeaveByYear[selectedYear] ?? 19;
  }

  double monthlyLeaveDaysFor(EmployeeAccount account) =>
      account.monthlyLeaveDays ?? accruedMonthlyLeaveFor(account).toDouble();

  double totalAnnualLeaveFor(EmployeeAccount? account) {
    if (account == null) return 0;
    if (isUnderOneYear(account)) return monthlyLeaveDaysFor(account);
    return annualLeaveDaysFor(account);
  }

  String leaveEntitlementLabelFor(EmployeeAccount? account) =>
      isUnderOneYear(account) ? '발생 월차' : '총 연차';

  String leaveUsedLabelFor(EmployeeAccount? account) =>
      isUnderOneYear(account) ? '사용 월차' : '사용 연차';

  String leaveRemainingLabelFor(EmployeeAccount? account) =>
      isUnderOneYear(account) ? '잔여 월차' : '잔여 연차';

  String servicePeriodLabelFor(EmployeeAccount? account) =>
      isUnderOneYear(account)
      ? '${completedServiceMonthsFor(account)}개월차'
      : '${serviceYearFor(account)}년';

  double get totalAnnualLeave => totalAnnualLeaveFor(currentUser);

  double usedAnnualLeaveFor(String userId) => leaveRequestsFor(userId)
      .where((request) => request.status == '승인완료')
      .fold(0, (sum, request) => sum + request.days);

  double pendingAnnualLeaveFor(String userId) => leaveRequestsFor(userId)
      .where((request) => request.status == '승인대기')
      .fold(0, (sum, request) => sum + request.days);

  double remainingAnnualLeaveFor(EmployeeAccount account) =>
      (totalAnnualLeaveFor(account) -
              usedAnnualLeaveFor(account.id) -
              pendingAnnualLeaveFor(account.id))
          .clamp(0, 365)
          .toDouble();

  double get usedAnnualLeave => currentUserLeaveRequests
      .where((request) => request.status == '승인완료')
      .fold(0, (sum, request) => sum + request.days);

  double get pendingAnnualLeave => currentUserLeaveRequests
      .where((request) => request.status == '승인대기')
      .fold(0, (sum, request) => sum + request.days);

  double get remainingAnnualLeave =>
      (totalAnnualLeave - usedAnnualLeave - pendingAnnualLeave)
          .clamp(0, 365)
          .toDouble();

  bool canActOnLeave(LeaveRequest request) {
    final user = currentUser;
    if (user == null || request.status != '승인대기') return false;
    if (request.approvalLine.isNotEmpty) {
      return request.approvalLine.any(
        (step) => step.status == '진행중' && step.userId == user.id,
      );
    }
    if (request.ceoStatus == '진행중') {
      return user.id == 'ceo' || user.position.contains('대표');
    }
    return false;
  }
}

bool _audienceIncludesCurrentUser(
  Iterable<String> audience,
  EmployeeAccount user,
) {
  final labels = {user.id, user.name, user.department}
    ..removeWhere((label) => label.trim().isEmpty);
  return audience.any((label) => labels.contains(label.trim()));
}

const _preferredDepartmentOrder = <String>[
  '대표이사',
  '기술부',
  '연구소',
  '관리부',
  '공무',
  '경리부',
];

int _compareDepartments(String left, String right) {
  final leftIndex = _preferredDepartmentOrder.indexOf(left);
  final rightIndex = _preferredDepartmentOrder.indexOf(right);
  if (leftIndex >= 0 && rightIndex >= 0) return leftIndex.compareTo(rightIndex);
  if (leftIndex >= 0) return -1;
  if (rightIndex >= 0) return 1;
  return left.compareTo(right);
}

const _preferredPositionOrder = <String>[
  '대표',
  '회장',
  '부회장',
  '사장',
  '부사장',
  '전무',
  '상무',
  '이사',
  '본부장',
  '연구소장',
  '소장',
  '실장',
  '부장',
  '차장',
  '과장',
  '팀장',
  '대리',
  '주임',
  '사원',
  '인턴',
];

int compareEmployeeOrganizationOrder(
  EmployeeAccount left,
  EmployeeAccount right,
) {
  final leftRank = _positionRank(left.position);
  final rightRank = _positionRank(right.position);
  final positionComparison = leftRank.compareTo(rightRank);
  if (positionComparison != 0) return positionComparison;
  return left.name.compareTo(right.name);
}

int _positionRank(String position) {
  final normalized = position.replaceAll(' ', '');
  final index = _preferredPositionOrder.indexWhere(
    (rank) => normalized == rank || normalized.contains(rank),
  );
  return index < 0 ? _preferredPositionOrder.length : index;
}
