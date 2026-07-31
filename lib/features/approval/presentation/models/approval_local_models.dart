class EmployeeAccount {
  const EmployeeAccount({
    required this.id,
    required this.password,
    required this.name,
    required this.department,
    required this.position,
    required this.email,
    this.hireDate = '2024-01-15',
    this.isAdmin = false,
  });

  final String id;
  final String password;
  final String name;
  final String department;
  final String position;
  final String email;
  final String hireDate;
  final bool isAdmin;

  EmployeeAccount copyWith({
    String? id,
    String? password,
    String? name,
    String? department,
    String? position,
    String? email,
    String? hireDate,
    bool? isAdmin,
  }) {
    return EmployeeAccount(
      id: id ?? this.id,
      password: password ?? this.password,
      name: name ?? this.name,
      department: department ?? this.department,
      position: position ?? this.position,
      email: email ?? this.email,
      hireDate: hireDate ?? this.hireDate,
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

  ApprovalFormTemplate copyWith({
    String? id,
    String? category,
    String? name,
    String? description,
    String? defaultTitle,
    String? defaultContent,
    List<String>? receivers,
    List<String>? references,
    List<String>? viewers,
    List<String>? publicReceivers,
    String? cooperationDepartment,
    String? agreement,
  }) {
    return ApprovalFormTemplate(
      id: id ?? this.id,
      category: category ?? this.category,
      name: name ?? this.name,
      description: description ?? this.description,
      defaultTitle: defaultTitle ?? this.defaultTitle,
      defaultContent: defaultContent ?? this.defaultContent,
      receivers: receivers ?? this.receivers,
      references: references ?? this.references,
      viewers: viewers ?? this.viewers,
      publicReceivers: publicReceivers ?? this.publicReceivers,
      cooperationDepartment:
          cooperationDepartment ?? this.cooperationDepartment,
      agreement: agreement ?? this.agreement,
    );
  }
}

abstract final class PortalAppId {
  static const approval = 'approval';
  static const attendance = 'attendance';
  static const leave = 'leave';
}

class ApprovalRequestDraft {
  const ApprovalRequestDraft({
    required this.formId,
    required this.title,
    required this.content,
    required this.urgent,
    required this.linkedDocuments,
    this.departmentVisible = true,
  });

  final String formId;
  final String title;
  final String content;
  final bool urgent;
  final List<String> linkedDocuments;
  final bool departmentVisible;
}

class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.userId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.reason,
    this.status = '승인대기',
  });

  final String id;
  final String userId;
  final String type;
  final String startDate;
  final String endDate;
  final double days;
  final String reason;
  final String status;

  LeaveRequest copyWith({String? status}) => LeaveRequest(
    id: id,
    userId: userId,
    type: type,
    startDate: startDate,
    endDate: endDate,
    days: days,
    reason: reason,
    status: status ?? this.status,
  );
}
