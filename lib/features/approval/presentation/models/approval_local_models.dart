import 'package:the_we_system/features/approval/domain/entities/document/approval_attachment.dart';

import '../pages/admin/approval_admin_dependencies.dart';

const designatedAdminAccountId = 'we81048';
const designatedAdminName = '김효민';
const designatedAdminDepartment = '경리부';
const designatedAdminPosition = '대리';

class PortalNotice {
  const PortalNotice({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
  });

  final String id;
  final String title;
  final String content;
  final String authorName;
  final String createdAt;
  final String updatedAt;
  final bool isPinned;
}

class EmployeeAccount {
  const EmployeeAccount({
    required this.id,
    required this.password,
    required this.name,
    required this.department,
    required this.position,
    this.hireDate = '2024-01-15',
    this.isAdmin = false,
    this.canChangeAdminOtp = false,
    this.annualLeaveDays,
    this.monthlyLeaveDays,
    this.leaveBalanceAdjustment = 0,
  });

  final String id;
  final String password;
  final String name;
  final String department;
  final String position;
  final String hireDate;
  final bool isAdmin;
  final bool canChangeAdminOtp;
  final double? annualLeaveDays;
  final double? monthlyLeaveDays;
  final double leaveBalanceAdjustment;

  String get normalizedId =>
      id.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  bool get isSystemAdministrator => isAdmin && normalizedId == 'admin';

  bool get isDesignatedAdministrator =>
      normalizedId == designatedAdminAccountId ||
      (isAdmin &&
          name.trim() == designatedAdminName &&
          department.replaceAll(RegExp(r'\s+'), '') ==
              designatedAdminDepartment &&
          position.replaceAll(RegExp(r'\s+'), '') == designatedAdminPosition);

  bool get canAccessAdminMode =>
      isSystemAdministrator || isDesignatedAdministrator;

  EmployeeAccount copyWith({
    String? id,
    String? password,
    String? name,
    String? department,
    String? position,
    String? hireDate,
    bool? isAdmin,
    bool? canChangeAdminOtp,
    double? annualLeaveDays,
    double? monthlyLeaveDays,
    double? leaveBalanceAdjustment,
  }) {
    return EmployeeAccount(
      id: id ?? this.id,
      password: password ?? this.password,
      name: name ?? this.name,
      department: department ?? this.department,
      position: position ?? this.position,
      hireDate: hireDate ?? this.hireDate,
      isAdmin: isAdmin ?? this.isAdmin,
      canChangeAdminOtp: canChangeAdminOtp ?? this.canChangeAdminOtp,
      annualLeaveDays: annualLeaveDays ?? this.annualLeaveDays,
      monthlyLeaveDays: monthlyLeaveDays ?? this.monthlyLeaveDays,
      leaveBalanceAdjustment:
          leaveBalanceAdjustment ?? this.leaveBalanceAdjustment,
    );
  }
}

class ApprovalLinePreset {
  const ApprovalLinePreset({
    required this.id,
    required this.name,
    required this.userIds,
  });

  final String id;
  final String name;
  final List<String> userIds;
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
    this.approvalLines = const [],
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
  final List<ApprovalLinePreset> approvalLines;

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
    List<ApprovalLinePreset>? approvalLines,
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
      approvalLines: approvalLines ?? this.approvalLines,
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
    this.attachments = const <ApprovalAttachment>[],
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
  final List<ApprovalAttachment> attachments;
  final bool departmentVisible;
  final String documentLayout;
  final Map<String, String> formFields;
  final List<Map<String, String>> lineItems;
}

class LeaveApprovalStep {
  const LeaveApprovalStep({
    required this.userId,
    required this.name,
    required this.department,
    required this.position,
    required this.status,
  });

  final String userId;
  final String name;
  final String department;
  final String position;
  final String status;

  LeaveApprovalStep copyWith({String? userId, String? status}) =>
      LeaveApprovalStep(
        userId: userId ?? this.userId,
        name: name,
        department: department,
        position: position,
        status: status ?? this.status,
      );
}

class LeaveDateSelection {
  LeaveDateSelection({required this.type, required DateTime startDate})
    : startDate = DateUtils.dateOnly(startDate),
      endDate = DateUtils.dateOnly(startDate);

  String type;
  DateTime startDate;
  DateTime endDate;
  bool _endDateWasEdited = false;

  bool get isHalfDay => type == '반차';

  double get days => isHalfDay
      ? .5
      : endDate.difference(startDate).inDays + 1.0;

  void selectType(String value) {
    type = value;
    if (isHalfDay) {
      endDate = startDate;
      _endDateWasEdited = false;
    }
  }

  void selectStartDate(DateTime value) {
    startDate = DateUtils.dateOnly(value);
    if (isHalfDay || !_endDateWasEdited || endDate.isBefore(startDate)) {
      endDate = startDate;
      _endDateWasEdited = false;
    }
  }

  void selectEndDate(DateTime value) {
    final normalized = DateUtils.dateOnly(value);
    if (normalized.isBefore(startDate)) {
      endDate = startDate;
      _endDateWasEdited = false;
      return;
    }
    endDate = normalized;
    _endDateWasEdited = true;
  }
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
    this.ceoStatus = '진행중',
    this.approvalLine = const [],
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
  final String ceoStatus;
  final List<LeaveApprovalStep> approvalLine;
  final String rejectedBy;
  final bool directEntry;
  final String registeredBy;

  LeaveRequest copyWith({
    String? userId,
    String? status,
    String? ceoStatus,
    List<LeaveApprovalStep>? approvalLine,
    String? rejectedBy,
    bool? directEntry,
    String? registeredBy,
  }) => LeaveRequest(
    id: id,
    userId: userId ?? this.userId,
    type: type,
    startDate: startDate,
    endDate: endDate,
    days: days,
    reason: reason,
    status: status ?? this.status,
    ceoStatus: ceoStatus ?? this.ceoStatus,
    approvalLine: approvalLine ?? this.approvalLine,
    rejectedBy: rejectedBy ?? this.rejectedBy,
    directEntry: directEntry ?? this.directEntry,
    registeredBy: registeredBy ?? this.registeredBy,
  );
}
