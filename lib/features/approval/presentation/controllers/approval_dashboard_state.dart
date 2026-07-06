part of 'approval_providers.dart';

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
