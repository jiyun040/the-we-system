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
    this.documentLayout = ApprovalDocumentLayout.basic,
    this.lineItemRows = 8,
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
  final String documentLayout;
  final int lineItemRows;

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
    String? documentLayout,
    int? lineItemRows,
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
      documentLayout: documentLayout ?? this.documentLayout,
      lineItemRows: lineItemRows ?? this.lineItemRows,
    );
  }
}

abstract final class ApprovalDocumentLayout {
  static const basic = 'basic';
  static const expense = 'expense';
  static const hospitality = 'hospitality';
  static const purchase = 'purchase';
  static const payroll = 'payroll';

  static const labels = <String, String>{
    basic: '기본 기안서',
    expense: '지출결의서(지급품의)',
    hospitality: '접대비 지출결의서',
    purchase: '비품/소모품 구입신청서',
    payroll: '급여대장 기안서',
  };
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
    this.documentLayout = ApprovalDocumentLayout.basic,
    this.formFields = const <String, String>{},
    this.lineItems = const <Map<String, String>>[],
  });

  final String formId;
  final String title;
  final String content;
  final bool urgent;
  final List<String> linkedDocuments;
  final bool departmentVisible;
  final String documentLayout;
  final Map<String, String> formFields;
  final List<Map<String, String>> lineItems;
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
    this.directorStatus = '진행중',
    this.ceoStatus = '결재 예정',
    this.rejectedBy = '',
    this.directEntry = false,
    this.registeredBy = '',
  });

  final String id;
  final String userId;
  final String type;
  final String startDate;
  final String endDate;
  final double days;
  final String reason;
  final String status;
  final String directorStatus;
  final String ceoStatus;
  final String rejectedBy;
  final bool directEntry;
  final String registeredBy;

  LeaveRequest copyWith({
    String? status,
    String? directorStatus,
    String? ceoStatus,
    String? rejectedBy,
    bool? directEntry,
    String? registeredBy,
  }) => LeaveRequest(
    id: id,
    userId: userId,
    type: type,
    startDate: startDate,
    endDate: endDate,
    days: days,
    reason: reason,
    status: status ?? this.status,
    directorStatus: directorStatus ?? this.directorStatus,
    ceoStatus: ceoStatus ?? this.ceoStatus,
    rejectedBy: rejectedBy ?? this.rejectedBy,
    directEntry: directEntry ?? this.directEntry,
    registeredBy: registeredBy ?? this.registeredBy,
  );
}
