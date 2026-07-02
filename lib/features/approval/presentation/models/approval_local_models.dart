class EmployeeAccount {
  const EmployeeAccount({
    required this.id,
    required this.password,
    required this.name,
    required this.department,
    required this.position,
    required this.email,
    this.isAdmin = false,
  });

  final String id;
  final String password;
  final String name;
  final String department;
  final String position;
  final String email;
  final bool isAdmin;

  EmployeeAccount copyWith({
    String? id,
    String? password,
    String? name,
    String? department,
    String? position,
    String? email,
    bool? isAdmin,
  }) {
    return EmployeeAccount(
      id: id ?? this.id,
      password: password ?? this.password,
      name: name ?? this.name,
      department: department ?? this.department,
      position: position ?? this.position,
      email: email ?? this.email,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}

class ApprovalFormTemplate {
  const ApprovalFormTemplate({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.defaultTitle,
    required this.defaultContent,
    required this.receivers,
    required this.references,
    required this.viewers,
    required this.publicReceivers,
    required this.cooperationDepartment,
    required this.agreement,
  });

  final String id;
  final String category;
  final String name;
  final String description;
  final String defaultTitle;
  final String defaultContent;
  final List<String> receivers;
  final List<String> references;
  final List<String> viewers;
  final List<String> publicReceivers;
  final String cooperationDepartment;
  final String agreement;
}

class ApprovalRequestDraft {
  const ApprovalRequestDraft({
    required this.formId,
    required this.title,
    required this.content,
    required this.urgent,
    required this.linkedDocuments,
  });

  final String formId;
  final String title;
  final String content;
  final bool urgent;
  final List<String> linkedDocuments;
}
