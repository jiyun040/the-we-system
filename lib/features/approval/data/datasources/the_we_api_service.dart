import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:the_we_system/core/network/api_exception.dart';
import 'package:the_we_system/core/network/auth_token_store.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:the_we_system/features/approval/domain/entities/form/approval_form.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';

class RemoteBootstrapData {
  const RemoteBootstrapData({
    required this.currentUser,
    required this.accounts,
    required this.departments,
    required this.frequentForms,
    required this.formTemplates,
    required this.disabledFormTemplateIds,
    required this.documents,
    required this.restrictedDocumentIds,
    required this.leaveRequests,
    required this.acknowledgedLeaveRequestIds,
    required this.portalName,
    required this.annualLeaveByYear,
    required this.monthlyLeavePerMonth,
    required this.adminOtpEnabled,
    required this.settingsPasswordEnabled,
    required this.adminDocumentAccessEnabled,
    required this.customLogoBytes,
    required this.customLogoFileName,
    required this.enabledAppIds,
    required this.organizationWideDocumentCategories,
    required this.documentCategoryViewerIds,
  });

  final EmployeeAccount currentUser;
  final List<EmployeeAccount> accounts;
  final List<String> departments;
  final List<ApprovalForm> frequentForms;
  final List<ApprovalFormTemplate> formTemplates;
  final Set<String> disabledFormTemplateIds;
  final List<ApprovalDocument> documents;
  final Set<String> restrictedDocumentIds;
  final List<LeaveRequest> leaveRequests;
  final Set<String> acknowledgedLeaveRequestIds;
  final String portalName;
  final Map<int, int> annualLeaveByYear;
  final int monthlyLeavePerMonth;
  final bool adminOtpEnabled;
  final bool settingsPasswordEnabled;
  final bool adminDocumentAccessEnabled;
  final Uint8List? customLogoBytes;
  final String? customLogoFileName;
  final Set<String> enabledAppIds;
  final Set<String> organizationWideDocumentCategories;
  final Map<String, Set<String>> documentCategoryViewerIds;
}

class TheWeApiService {
  TheWeApiService(this._dio, this._tokenStore);

  final Dio _dio;
  final AuthTokenStore _tokenStore;

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<bool> hasStoredToken() async {
    final token = await _tokenStore.read();
    return token != null && token.isNotEmpty;
  }

  Future<void> login(String id, String password) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'id': id, 'password': password},
    );
    final token = response.data?['token']?.toString() ?? '';
    if (token.isEmpty) throw const ApiException('로그인 토큰을 받지 못했습니다.');
    await _tokenStore.write(token);
  });

  Future<void> register({
    required String id,
    required String password,
    required String name,
    required String department,
    required String position,
  }) => _guard(() async {
    await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'id': id,
        'password': password,
        'name': name,
        'department': department,
        'position': position,
      },
    );
  });

  Future<void> logout() async {
    try {
      if (await hasStoredToken()) await _dio.post<void>('/auth/logout');
    } on DioException {
      // Local token removal must still succeed when the server is unavailable.
    } finally {
      await _tokenStore.clear();
    }
  }

  Future<bool> verifyPassword(String password) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/verify-password',
      data: {'password': password},
    );
    return response.data?['valid'] == true;
  });

  Future<bool> verifyAdminOtp(String otp) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/admin/verify-otp',
      data: {'otp': otp},
    );
    return response.data?['valid'] == true;
  });

  Future<void> changeAdminOtp({
    required String currentOtp,
    required String newOtp,
  }) => _guard(() async {
    await _dio.post<void>(
      '/admin/change-otp',
      data: {'currentOtp': currentOtp, 'newOtp': newOtp},
    );
  });

  Future<RemoteBootstrapData> fetchBootstrap() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('/bootstrap');
    final data = response.data ?? <String, dynamic>{};
    final settings = _map(data['settings']);
    Uint8List? logoBytes;
    final logo = settings['customLogoBase64']?.toString() ?? '';
    if (logo.isNotEmpty) {
      try {
        logoBytes = base64Decode(logo);
      } on FormatException {
        logoBytes = null;
      }
    }
    return RemoteBootstrapData(
      currentUser: _account(_map(data['currentUser'])),
      accounts: _list(
        data['accounts'],
      ).map((item) => _account(_map(item))).toList(),
      departments: _departmentNames(data['departments']),
      frequentForms: _list(
        data['frequentForms'],
      ).map((item) => ApprovalForm.fromJson(_map(item))).toList(),
      formTemplates: _list(
        data['formTemplates'],
      ).map((item) => _formTemplate(_map(item))).toList(),
      disabledFormTemplateIds: _strings(
        data['disabledFormTemplateIds'],
      ).toSet(),
      documents: _list(
        data['documents'],
      ).map((item) => ApprovalDocument.fromJson(_map(item))).toList(),
      restrictedDocumentIds: _strings(data['restrictedDocumentIds']).toSet(),
      leaveRequests: _list(
        data['leaveRequests'],
      ).map((item) => _leaveRequest(_map(item))).toList(),
      acknowledgedLeaveRequestIds: _strings(
        data['acknowledgedLeaveRequestIds'],
      ).toSet(),
      portalName: (settings['portalName']?.toString() ?? '우리기술 전자결재')
          .replaceAll('더우리기술', '우리기술'),
      annualLeaveByYear: _intMap(settings['annualLeaveByYear']),
      monthlyLeavePerMonth: _integer(settings['monthlyLeavePerMonth'], 1),
      adminOtpEnabled: settings['adminOtpEnabled'] != false,
      settingsPasswordEnabled: settings['settingsPasswordEnabled'] != false,
      adminDocumentAccessEnabled:
          settings['adminDocumentAccessEnabled'] != false,
      customLogoBytes: logoBytes,
      customLogoFileName: settings['customLogoFileName']?.toString(),
      enabledAppIds: _strings(settings['enabledAppIds']).toSet(),
      organizationWideDocumentCategories: _strings(
        settings['organizationWideDocumentCategories'],
      ).toSet(),
      documentCategoryViewerIds: _setMap(settings['documentCategoryViewerIds']),
    );
  });

  Future<ApprovalDocument> createDraft({
    required ApprovalRequestDraft draft,
    List<Map<String, dynamic>>? steps,
  }) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/approvals/documents',
      data: _documentPayload(draft, steps: steps),
    );
    return ApprovalDocument.fromJson(response.data ?? <String, dynamic>{});
  });

  Future<ApprovalDocument> updateDraft(
    String id, {
    required ApprovalRequestDraft draft,
    List<Map<String, dynamic>>? steps,
  }) => _guard(() async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/approvals/documents/$id',
      data: _documentPayload(draft, includeForm: false, steps: steps),
    );
    return ApprovalDocument.fromJson(response.data ?? <String, dynamic>{});
  });

  Future<ApprovalDocument> submitDocument(String id) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/approvals/documents/$id/submit',
      data: const <String, dynamic>{},
    );
    return ApprovalDocument.fromJson(response.data ?? <String, dynamic>{});
  });

  Future<ApprovalDocument> actOnDocument(
    String id, {
    required bool approve,
    required String opinion,
  }) => _guard(() async {
    final action = approve ? 'approve' : 'reject';
    final response = await _dio.post<Map<String, dynamic>>(
      '/approvals/$id/$action',
      data: {'opinion': opinion},
    );
    return ApprovalDocument.fromJson(response.data ?? <String, dynamic>{});
  });

  Future<ApprovalDocument> cancelDocument(String id) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/approvals/$id/cancel',
      data: const <String, dynamic>{},
    );
    return ApprovalDocument.fromJson(response.data ?? <String, dynamic>{});
  });

  Future<void> createLeave({
    String? userId,
    required String type,
    required String startDate,
    required String endDate,
    required double days,
    required String reason,
    bool directEntry = false,
  }) => _guard(() async {
    await _dio.post<Map<String, dynamic>>(
      '/leave/requests',
      data: {
        'userId': ?userId,
        'type': type,
        'startDate': startDate,
        'endDate': endDate,
        'days': days,
        'reason': reason,
        'directEntry': directEntry,
      },
    );
  });

  Future<void> actOnLeave(String id, {required bool approve}) =>
      _guard(() async {
        await _dio.post<Map<String, dynamic>>(
          '/leave/requests/$id/${approve ? 'approve' : 'reject'}',
          data: const <String, dynamic>{},
        );
      });

  Future<void> acknowledgeLeave(String id) => _guard(() async {
    await _dio.post<Map<String, dynamic>>(
      '/leave/requests/$id/acknowledge',
      data: const <String, dynamic>{},
    );
  });

  Future<void> createEmployee(Map<String, dynamic> data) => _guard(() async {
    await _dio.post<Map<String, dynamic>>(
      '/organization/employees',
      data: data,
    );
  });

  Future<void> updateEmployee(String id, Map<String, dynamic> data) =>
      _guard(() async {
        await _dio.patch<Map<String, dynamic>>(
          '/organization/employees/$id',
          data: data,
        );
      });

  Future<void> deleteEmployee(String id) => _guard(() async {
    await _dio.delete<void>('/organization/employees/$id');
  });

  Future<void> createDepartment(String name) => _guard(() async {
    await _dio.post<Map<String, dynamic>>(
      '/organization/departments',
      data: {'name': name},
    );
  });

  Future<void> reorderDepartments(List<String> departments) => _guard(() async {
    await _dio.patch<Map<String, dynamic>>(
      '/organization/departments/reorder',
      data: {'departments': departments},
    );
  });

  Future<void> renameDepartment(String currentName, String nextName) =>
      _guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/organization/departments',
        );
        final departments = _list(response.data?['departments']);
        final department = departments
            .map(_map)
            .where((item) => item['name']?.toString() == currentName)
            .firstOrNull;
        if (department == null) throw const ApiException('부서를 찾을 수 없습니다.');
        await _dio.patch<Map<String, dynamic>>(
          '/organization/departments/${department['id']}',
          data: {'name': nextName},
        );
      });

  Future<void> deleteDepartment(String name) => _guard(() async {
    final id = await _departmentId(name);
    await _dio.delete<void>('/organization/departments/$id');
  });

  Future<Object> _departmentId(String name) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/organization/departments',
    );
    final department = _list(
      response.data?['departments'],
    ).map(_map).where((item) => item['name']?.toString() == name).firstOrNull;
    if (department == null) throw const ApiException('부서를 찾을 수 없습니다.');
    return department['id']!;
  }

  Future<void> updateSettings(Map<String, dynamic> data) => _guard(() async {
    await _dio.patch<Map<String, dynamic>>('/settings', data: data);
  });

  Future<void> setFormEnabled(String id, bool enabled) => _guard(() async {
    await _dio.patch<Map<String, dynamic>>(
      '/approval-forms/$id',
      data: {'enabled': enabled},
    );
  });

  Future<void> saveForm({String? id, required Map<String, dynamic> data}) =>
      _guard(() async {
        if (id == null) {
          await _dio.post<Map<String, dynamic>>('/approval-forms', data: data);
        } else {
          await _dio.patch<Map<String, dynamic>>(
            '/approval-forms/$id',
            data: data,
          );
        }
      });

  Future<void> deleteForm(String id) => _guard(() async {
    await _dio.delete<void>('/approval-forms/$id');
  });
}

Map<String, dynamic> _documentPayload(
  ApprovalRequestDraft draft, {
  bool includeForm = true,
  List<Map<String, dynamic>>? steps,
}) => {
  if (includeForm) 'formId': draft.formId,
  'title': draft.title,
  'content': draft.content,
  'urgent': draft.urgent,
  'departmentVisible': draft.departmentVisible,
  'linkedDocuments': draft.linkedDocuments,
  'attachments': draft.attachments.map((item) => item.toJson()).toList(),
  'documentLayout': draft.documentLayout,
  'formFields': draft.formFields,
  'lineItems': draft.lineItems,
  'steps': ?steps,
};

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<dynamic> _list(dynamic value) => value is List ? value : const [];

List<String> _strings(dynamic value) =>
    _list(value).map((item) => item.toString()).toList();

List<String> _departmentNames(dynamic value) => _list(value)
    .map((item) => item is Map ? _map(item)['name'] : item)
    .map((item) => item?.toString().trim() ?? '')
    .where((item) => item.isNotEmpty)
    .toList();

int _integer(dynamic value, int fallback) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ?? fallback;

Map<int, int> _intMap(dynamic value) => _map(value).map(
  (key, item) => MapEntry(int.tryParse(key) ?? 0, _integer(item, 0)),
)..remove(0);

Map<String, Set<String>> _setMap(dynamic value) =>
    _map(value).map((key, item) => MapEntry(key, _strings(item).toSet()));

EmployeeAccount _account(Map<String, dynamic> data) => EmployeeAccount(
  id: data['id']?.toString() ?? '',
  password: '',
  name: data['name']?.toString() ?? '',
  department: data['department']?.toString() ?? '',
  position: data['position']?.toString() ?? '',
  email: data['email']?.toString() ?? '',
  hireDate: data['hireDate']?.toString() ?? '',
  isAdmin: data['isAdmin'] == true,
  canChangeAdminOtp: data['canChangeAdminOtp'] == true,
);

ApprovalFormTemplate _formTemplate(Map<String, dynamic> data) =>
    ApprovalFormTemplate(
      id: data['id']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      defaultTitle: data['defaultTitle']?.toString() ?? '',
      defaultContent: data['defaultContent']?.toString() ?? '',
      receivers: _strings(data['receivers']),
      references: _strings(data['references']),
      viewers: _strings(data['viewers']),
      publicReceivers: _strings(data['publicReceivers']),
      cooperationDepartment: data['cooperationDepartment']?.toString() ?? '',
      agreement: data['agreement']?.toString() ?? '',
      documentLayout: data['documentLayout']?.toString() ?? 'basic',
      lineItemRows: _integer(data['lineItemRows'], 8),
    );

LeaveRequest _leaveRequest(Map<String, dynamic> data) => LeaveRequest(
  id: data['id']?.toString() ?? '',
  userId: data['userId']?.toString() ?? '',
  type: data['type']?.toString() ?? '',
  startDate: data['startDate']?.toString() ?? '',
  endDate: data['endDate']?.toString() ?? '',
  days: (data['days'] as num?)?.toDouble() ?? 0,
  reason: data['reason']?.toString() ?? '',
  status: data['status']?.toString() == '승인'
      ? '승인완료'
      : data['status']?.toString() ?? '승인대기',
  ceoStatus: data['ceoStatus']?.toString() ?? '진행중',
  rejectedBy: data['rejectedBy']?.toString() ?? '',
  directEntry: data['directEntry'] == true,
  registeredBy: data['registeredBy']?.toString() ?? '',
);
