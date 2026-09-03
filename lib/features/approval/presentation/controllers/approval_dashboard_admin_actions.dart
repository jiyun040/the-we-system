import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:the_we_system/core/network/api_exception.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_controller_models.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_provider_helpers.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';

extension ApprovalDashboardAdminActions on ApprovalDashboardController {
  void syncRemote(Future<void> Function() operation) {
    unawaited(
      operation().then((_) => reloadRemoteState()).catchError((Object error) {
        debugPrint('서버 동기화 실패: $error');
        reportOperationError(error, fallback: '변경사항을 서버에 저장하지 못했습니다.');
      }),
    );
  }

  Future<bool> enterAdminMode(String otp) async {
    try {
      final current = currentDashboardState;
      if (current == null ||
          current.currentUser?.canAccessAdminMode != true ||
          !await api.verifyAdminOtp(otp)) {
        return false;
      }
      setApprovalDashboardState(
        this,
        (value) => value.copyWith(adminMode: true),
      );
      return true;
    } catch (error) {
      reportOperationError(error, fallback: '관리자 인증을 완료하지 못했습니다.');
      return false;
    }
  }

  void leaveAdminMode() {
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(adminMode: false),
    );
  }

  Future<bool> verifyCurrentPassword(String password) async {
    try {
      return await api.verifyPassword(password);
    } catch (error) {
      reportOperationError(error, fallback: '비밀번호 확인을 완료하지 못했습니다.');
      return false;
    }
  }

  Future<String?> changeAdminOtp({
    required String currentOtp,
    required String newOtp,
  }) async {
    try {
      await api.changeAdminOtp(currentOtp: currentOtp, newOtp: newOtp);
      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (error) {
      return userFacingErrorMessage(error, fallback: 'OTP 번호를 변경하지 못했습니다.');
    }
  }

  Future<String?> saveNotice({
    String? noticeId,
    required String title,
    required String content,
    required bool isPinned,
  }) async {
    final current = currentDashboardState;
    if (current?.canManageNotices != true) {
      return '관리자 계정만 공지사항을 관리할 수 있습니다.';
    }
    final normalizedTitle = title.trim();
    final normalizedContent = content.trim();
    if (normalizedTitle.isEmpty || normalizedContent.isEmpty) {
      return '공지 제목과 내용을 모두 입력해 주세요.';
    }
    if (normalizedTitle.length > 200) {
      return '공지 제목은 200자 이하로 입력해 주세요.';
    }
    try {
      final notice = noticeId == null
          ? await api.createNotice(
              title: normalizedTitle,
              content: normalizedContent,
              isPinned: isPinned,
            )
          : await api.updateNotice(
              noticeId,
              title: normalizedTitle,
              content: normalizedContent,
              isPinned: isPinned,
            );
      setApprovalDashboardState(this, (value) {
        final notices = noticeId == null
            ? [notice, ...value.notices]
            : value.notices
                  .map((item) => item.id == noticeId ? notice : item)
                  .toList();
        notices.sort(_compareNotices);
        return value.copyWith(notices: notices);
      });
      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (error) {
      return userFacingErrorMessage(error, fallback: '공지사항을 저장하지 못했습니다.');
    }
  }

  Future<String?> deleteNotice(String noticeId) async {
    if (currentDashboardState?.canManageNotices != true) {
      return '관리자 계정만 공지사항을 관리할 수 있습니다.';
    }
    try {
      await api.deleteNotice(noticeId);
      setApprovalDashboardState(
        this,
        (value) => value.copyWith(
          notices: value.notices
              .where((notice) => notice.id != noticeId)
              .toList(),
        ),
      );
      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (error) {
      return userFacingErrorMessage(error, fallback: '공지사항을 삭제하지 못했습니다.');
    }
  }

  String? updateEmployee({
    required String userId,
    required String department,
    required String position,
    required String hireDate,
    String? id,
    String? name,
    String? password,
    bool? isAdmin,
    String? annualLeaveDays,
    String? monthlyLeaveDays,
    String? remainingLeaveDays,
  }) {
    final current = currentDashboardState;
    if (current == null) return '직원 정보를 불러오지 못했습니다.';
    final account = current.accounts
        .where((item) => item.id == userId)
        .firstOrNull;
    if (account == null) return '수정할 직원을 찾지 못했습니다.';
    final normalizedId = (id ?? account.id).trim();
    final normalizedName = (name ?? account.name).trim();
    final normalizedDepartment = department.trim();
    final normalizedPosition = position.trim();
    final normalizedHireDate = hireDate.trim();
    if ([
      normalizedId,
      normalizedName,
      normalizedDepartment,
      normalizedPosition,
      normalizedHireDate,
    ].any((value) => value.isEmpty)) {
      return '필수 항목을 모두 입력해 주세요.';
    }
    if (!RegExp(r'^[a-zA-Z0-9@.+_-]+$').hasMatch(normalizedId)) {
      return '아이디는 영문, 숫자와 @/./+/-/_만 사용할 수 있습니다.';
    }
    if (current.accounts.any(
      (item) =>
          item.id != userId &&
          item.id.toLowerCase() == normalizedId.toLowerCase(),
    )) {
      return '이미 사용 중인 아이디입니다.';
    }
    if (DateTime.tryParse(normalizedHireDate) == null) {
      return '입사일을 YYYY-MM-DD 형식으로 입력해 주세요.';
    }
    final annualDays = annualLeaveDays == null
        ? account.annualLeaveDays
        : double.tryParse(annualLeaveDays.trim());
    final monthlyDays = monthlyLeaveDays == null
        ? account.monthlyLeaveDays
        : double.tryParse(monthlyLeaveDays.trim());
    final remainingDays = remainingLeaveDays == null
        ? null
        : double.tryParse(remainingLeaveDays.trim());
    if ((annualLeaveDays != null && !_validLeaveDays(annualDays)) ||
        (monthlyLeaveDays != null && !_validLeaveDays(monthlyDays)) ||
        (remainingLeaveDays != null && !_validLeaveDays(remainingDays))) {
      return '연차, 월차, 잔여 개수는 0일 이상 365일 이하로 입력해 주세요.';
    }
    final preview = account.copyWith(
      hireDate: normalizedHireDate,
      annualLeaveDays: annualDays,
      monthlyLeaveDays: monthlyDays,
    );
    final adjustment = remainingDays == null
        ? account.leaveBalanceAdjustment
        : remainingDays -
              (current.totalAnnualLeaveFor(preview) -
                  current.usedAnnualLeaveFor(userId) -
                  current.pendingAnnualLeaveFor(userId));
    setApprovalDashboardState(this, (value) {
      final accounts = value.accounts.map((account) {
        if (account.id != userId) return account;
        return account.copyWith(
          id: normalizedId,
          name: normalizedName,
          department: normalizedDepartment,
          position: normalizedPosition,
          hireDate: normalizedHireDate,
          password: password?.trim().isEmpty == true ? null : password?.trim(),
          isAdmin: account.isAdmin,
          annualLeaveDays: annualDays,
          monthlyLeaveDays: monthlyDays,
          leaveBalanceAdjustment: adjustment,
        );
      }).toList();
      final currentUser = value.currentUser?.id == userId
          ? accounts.where((account) => account.id == normalizedId).first
          : value.currentUser;
      final leaveRequests = value.leaveRequests
          .map(
            (request) => request.userId == userId
                ? request.copyWith(
                    userId: normalizedId,
                    approvalLine: [
                      for (final step in request.approvalLine)
                        step.copyWith(
                          userId: step.userId == userId
                              ? normalizedId
                              : step.userId,
                        ),
                    ],
                  )
                : request.copyWith(
                    approvalLine: [
                      for (final step in request.approvalLine)
                        step.copyWith(
                          userId: step.userId == userId
                              ? normalizedId
                              : step.userId,
                        ),
                    ],
                  ),
          )
          .toList();
      final templates = value.formTemplates
          .map(
            (template) => template.copyWith(
              receivers: _replaceUserId(
                template.receivers,
                userId,
                normalizedId,
              ),
              references: _replaceUserId(
                template.references,
                userId,
                normalizedId,
              ),
              viewers: _replaceUserId(template.viewers, userId, normalizedId),
              publicReceivers: _replaceUserId(
                template.publicReceivers,
                userId,
                normalizedId,
              ),
              approvalLines: [
                for (final line in template.approvalLines)
                  ApprovalLinePreset(
                    id: line.id,
                    name: line.name,
                    userIds: _replaceUserId(line.userIds, userId, normalizedId),
                  ),
              ],
            ),
          )
          .toList();
      final documents = value.documents
          .map(
            (document) => document.copyWith(
              receivers: _replaceUserId(
                document.receivers,
                userId,
                normalizedId,
              ),
              references: _replaceUserId(
                document.references,
                userId,
                normalizedId,
              ),
              viewers: _replaceUserId(document.viewers, userId, normalizedId),
              publicReceivers: _replaceUserId(
                document.publicReceivers,
                userId,
                normalizedId,
              ),
            ),
          )
          .toList();
      final viewerIds = {
        for (final entry in value.documentCategoryViewerIds.entries)
          entry.key: {
            for (final id in entry.value) id == userId ? normalizedId : id,
          },
      };
      final leaveApprovalLines = {
        for (final entry in value.leaveApprovalLines.entries)
          entry.key: _replaceUserId(entry.value, userId, normalizedId),
      };
      return value.copyWith(
        accounts: accounts,
        currentUser: currentUser,
        selectedOrgUserId: value.selectedOrgUserId == userId
            ? normalizedId
            : value.selectedOrgUserId,
        leaveRequests: leaveRequests,
        formTemplates: templates,
        documents: documents,
        documentCategoryViewerIds: viewerIds,
        leaveApprovalLines: leaveApprovalLines,
      );
    });
    syncRemote(() {
      final payload = <String, dynamic>{
        'id': normalizedId,
        'name': normalizedName,
        'department': normalizedDepartment,
        'position': normalizedPosition,
        'hireDate': normalizedHireDate,
        if (password?.trim().isNotEmpty == true) 'password': password!.trim(),
        'leaveBalanceAdjustment': adjustment,
      };
      if (annualDays != null) payload['annualLeaveDays'] = annualDays;
      if (monthlyDays != null) payload['monthlyLeaveDays'] = monthlyDays;
      return api.updateEmployee(userId, payload);
    });
    return null;
  }

  String? deleteEmployee(String userId) {
    final current = currentDashboardState;
    if (current == null) return '직원 정보를 불러오지 못했습니다.';
    if (current.currentUser?.id == userId) return '현재 로그인한 계정은 삭제할 수 없습니다.';
    if (!current.accounts.any((account) => account.id == userId)) {
      return '삭제할 직원을 찾지 못했습니다.';
    }
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(
        accounts: value.accounts
            .where((account) => account.id != userId)
            .toList(),
        clearSelectedOrgUser: value.selectedOrgUserId == userId,
      ),
    );
    syncRemote(() => api.deleteEmployee(userId));
    return null;
  }

  String? addEmployee({
    required String id,
    required String password,
    required String name,
    required String department,
    required String position,
    required String hireDate,
    required bool isAdmin,
    required String annualLeaveDays,
    required String monthlyLeaveDays,
    required String remainingLeaveDays,
  }) {
    final current = currentDashboardState;
    if (current == null) return '직원 정보를 불러오지 못했습니다.';
    final normalizedId = id.trim();
    if ([
      normalizedId,
      password.trim(),
      name.trim(),
      department.trim(),
      position.trim(),
      hireDate.trim(),
    ].any((value) => value.isEmpty)) {
      return '모든 항목을 입력해 주세요.';
    }
    if (current.accounts.any((account) => account.id == normalizedId)) {
      return '이미 사용 중인 아이디입니다.';
    }
    if (DateTime.tryParse(hireDate.trim()) == null) {
      return '입사일을 YYYY-MM-DD 형식으로 입력해 주세요.';
    }
    final annualDays = double.tryParse(annualLeaveDays.trim());
    final monthlyDays = double.tryParse(monthlyLeaveDays.trim());
    final remainingDays = double.tryParse(remainingLeaveDays.trim());
    if (!_validLeaveDays(annualDays) ||
        !_validLeaveDays(monthlyDays) ||
        !_validLeaveDays(remainingDays)) {
      return '연차, 월차, 잔여 개수는 0일 이상 365일 이하로 입력해 주세요.';
    }
    final preview = EmployeeAccount(
      id: normalizedId,
      password: password.trim(),
      name: name.trim(),
      department: department.trim(),
      position: position.trim(),
      hireDate: hireDate.trim(),
      isAdmin: false,
      annualLeaveDays: annualDays,
      monthlyLeaveDays: monthlyDays,
    );
    final adjustment = remainingDays! - current.totalAnnualLeaveFor(preview);
    final account = preview.copyWith(leaveBalanceAdjustment: adjustment);
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(accounts: [...value.accounts, account]),
    );
    syncRemote(
      () => api.createEmployee({
        'id': normalizedId,
        'password': password.trim(),
        'name': name.trim(),
        'department': department.trim(),
        'position': position.trim(),
        'hireDate': hireDate.trim(),
        'annualLeaveDays': annualDays,
        'monthlyLeaveDays': monthlyDays,
        'leaveBalanceAdjustment': adjustment,
      }),
    );
    return null;
  }

  void toggleApp(String appId, bool enabled) {
    setApprovalDashboardState(this, (value) {
      final enabledIds = {...value.enabledAppIds};
      if (enabled) {
        enabledIds.add(appId);
      } else {
        enabledIds.remove(appId);
      }
      return value.copyWith(enabledAppIds: enabledIds);
    });
    final enabledIds = {...?currentDashboardState?.enabledAppIds};
    if (enabled) {
      enabledIds.add(appId);
    } else {
      enabledIds.remove(appId);
    }
    syncRemote(
      () => api.updateSettings({'enabledAppIds': enabledIds.toList()}),
    );
  }

  void toggleFormTemplate(String templateId, bool enabled) {
    setApprovalDashboardState(this, (value) {
      final disabledIds = {...value.disabledFormTemplateIds};
      if (enabled) {
        disabledIds.remove(templateId);
      } else {
        disabledIds.add(templateId);
      }
      return value.copyWith(disabledFormTemplateIds: disabledIds);
    });
    syncRemote(() => api.setFormEnabled(templateId, enabled));
  }

  String? saveFormTemplate({
    String? templateId,
    required String category,
    required String name,
    required String description,
    required String defaultTitle,
    required String defaultContent,
    String documentLayout = ApprovalDocumentLayout.basic,
    int lineItemRows = 8,
    List<ApprovalLinePreset> approvalLines = const [],
  }) {
    final current = currentDashboardState;
    if (current == null) return '양식 정보를 불러오지 못했습니다.';
    if ([
      category,
      name,
      description,
      defaultTitle,
      defaultContent,
    ].any((value) => value.trim().isEmpty)) {
      return '모든 항목을 입력해 주세요.';
    }

    final templates = [...current.formTemplates];
    if (templateId == null) {
      final nextId = 'custom-${DateTime.now().microsecondsSinceEpoch}';
      templates.add(
        ApprovalFormTemplate(
          id: nextId,
          category: category.trim(),
          name: name.trim(),
          description: description.trim(),
          defaultTitle: defaultTitle.trim(),
          defaultContent: defaultContent.trim(),
          receivers: const [],
          references: const [],
          viewers: const [],
          publicReceivers: const [],
          cooperationDepartment: '',
          agreement: '',
          documentLayout: documentLayout,
          lineItemRows: lineItemRows,
          approvalLines: approvalLines,
        ),
      );
    } else {
      final index = templates.indexWhere((item) => item.id == templateId);
      if (index < 0) return '수정할 양식을 찾지 못했습니다.';
      templates[index] = templates[index].copyWith(
        category: category.trim(),
        name: name.trim(),
        description: description.trim(),
        defaultTitle: defaultTitle.trim(),
        defaultContent: defaultContent.trim(),
        documentLayout: documentLayout,
        lineItemRows: lineItemRows,
        approvalLines: approvalLines,
      );
    }
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(formTemplates: templates),
    );
    final saved = currentDashboardState?.formTemplates
        .where(
          (item) =>
              item.id == templateId ||
              (templateId == null && item.name == name.trim()),
        )
        .lastOrNull;
    syncRemote(
      () => api.saveForm(
        id: templateId,
        data: {
          if (saved != null && templateId == null) 'id': saved.id,
          'category': category.trim(),
          'name': name.trim(),
          'description': description.trim(),
          'defaultTitle': defaultTitle.trim(),
          'defaultContent': defaultContent.trim(),
          'documentLayout': documentLayout,
          'lineItemRows': lineItemRows,
          'approvalLines': [
            for (final line in approvalLines)
              {'id': line.id, 'name': line.name, 'userIds': line.userIds},
          ],
        },
      ),
    );
    return null;
  }

  void deleteFormTemplate(String templateId) {
    setApprovalDashboardState(this, (value) {
      final disabledIds = {...value.disabledFormTemplateIds}
        ..remove(templateId);
      return value.copyWith(
        formTemplates: value.formTemplates
            .where((template) => template.id != templateId)
            .toList(),
        frequentForms: value.frequentForms
            .where((form) => form.id != templateId)
            .toList(),
        disabledFormTemplateIds: disabledIds,
      );
    });
    syncRemote(() => api.deleteForm(templateId));
  }

  void updatePortalName(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) return;
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(portalName: normalized),
    );
    syncRemote(() => api.updateSettings({'portalName': normalized}));
  }

  String? updatePortalLogo(Uint8List bytes, String fileName) {
    if (bytes.isEmpty) return '선택한 로고 파일을 읽을 수 없습니다.';
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      return '로고 파일은 5MB 이하만 사용할 수 있습니다.';
    }
    setApprovalDashboardState(
      this,
      (value) =>
          value.copyWith(customLogoBytes: bytes, customLogoFileName: fileName),
    );
    syncRemote(
      () => api.updateSettings({
        'customLogoBase64': base64Encode(bytes),
        'customLogoFileName': fileName,
      }),
    );
    return null;
  }

  void resetPortalLogo() {
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(clearCustomLogo: true),
    );
    syncRemote(
      () => api.updateSettings({
        'customLogoBase64': '',
        'customLogoFileName': '',
      }),
    );
  }

  void updateSecurityPolicy({
    bool? adminOtpEnabled,
    bool? settingsPasswordEnabled,
    bool? adminDocumentAccessEnabled,
  }) {
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(
        adminOtpEnabled: adminOtpEnabled,
        settingsPasswordEnabled: settingsPasswordEnabled,
        adminDocumentAccessEnabled: adminDocumentAccessEnabled,
      ),
    );
    syncRemote(
      () => api.updateSettings({
        'adminOtpEnabled': ?adminOtpEnabled,
        'settingsPasswordEnabled': ?settingsPasswordEnabled,
        'adminDocumentAccessEnabled': ?adminDocumentAccessEnabled,
      }),
    );
  }

  Future<String?> saveDocumentCategoryAccess({
    required Set<String> organizationWideCategories,
    required Map<String, Set<String>> viewerIds,
  }) async {
    final current = currentDashboardState;
    if (current == null) return '결재 문서 설정을 불러오지 못했습니다.';
    final categories = current.formTemplates
        .map((template) => template.category)
        .where((category) => category.isNotEmpty)
        .toSet();
    final normalizedWide = {
      for (final category in organizationWideCategories)
        if (categories.contains(category)) category,
    };
    final normalizedViewerIds = {
      for (final category in categories) category: {...?viewerIds[category]},
    };
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(
        organizationWideDocumentCategories: normalizedWide,
        documentCategoryViewerIds: normalizedViewerIds,
      ),
    );
    try {
      await api.updateSettings({
        'organizationWideDocumentCategories': normalizedWide.toList(),
        'documentCategoryViewerIds': {
          for (final entry in normalizedViewerIds.entries)
            entry.key: entry.value.toList(),
        },
      });
      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (error) {
      return userFacingErrorMessage(
        error,
        fallback: '결재 문서 열람 권한을 저장하지 못했습니다.',
      );
    }
  }

  String? setAdminPermission(String userId, bool enabled) {
    final account = currentDashboardState?.accounts
        .where((item) => item.id == userId)
        .firstOrNull;
    return account?.isAdmin == true && enabled
        ? null
        : '관리자 권한은 서버의 사용자 권한 설정에서 관리해 주세요.';
  }

  String? renameDepartment(String currentName, String nextName) {
    final normalized = nextName.trim();
    if (normalized.isEmpty) return '변경할 부서명을 입력해 주세요.';
    final current = currentDashboardState;
    if (current == null) return '조직 정보를 불러오지 못했습니다.';
    if (normalized != currentName && current.departments.contains(normalized)) {
      return '이미 사용 중인 부서명입니다.';
    }
    final accounts = current.accounts
        .map(
          (account) => account.department == currentName
              ? account.copyWith(department: normalized)
              : account,
        )
        .toList();
    final currentUser = current.currentUser == null
        ? null
        : accounts
                  .where((account) => account.id == current.currentUser!.id)
                  .firstOrNull ??
              current.currentUser;
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(
        accounts: accounts,
        organizationDepartments: value.organizationDepartments
            .map((name) => name == currentName ? normalized : name)
            .toSet()
            .toList(),
        currentUser: currentUser,
        selectedOrgDepartment: value.selectedOrgDepartment == currentName
            ? normalized
            : value.selectedOrgDepartment,
        leaveApprovalLines: {
          for (final entry in value.leaveApprovalLines.entries)
            (entry.key == currentName ? normalized : entry.key): entry.value,
        },
      ),
    );
    syncRemote(() => api.renameDepartment(currentName, normalized));
    return null;
  }

  String? addDepartment(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) return '추가할 부서명을 입력해 주세요.';
    final current = currentDashboardState;
    if (current == null) return '조직 정보를 불러오지 못했습니다.';
    if (current.departments.contains(normalized)) return '이미 사용 중인 부서명입니다.';
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(
        organizationDepartments: [...value.organizationDepartments, normalized],
      ),
    );
    syncRemote(() => api.createDepartment(normalized));
    return null;
  }

  void moveDepartment(String name, int offset) {
    final current = currentDashboardState;
    if (current == null) return;
    final reordered = current.reorderedDepartments(name, offset);
    if (reordered.indexOf(name) == current.departments.indexOf(name)) return;
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(organizationDepartments: reordered),
    );
    syncRemote(() => api.reorderDepartments(reordered));
  }

  String? deleteDepartment(String name) {
    final current = currentDashboardState;
    if (current == null) return '조직 정보를 불러오지 못했습니다.';
    if (!current.departments.contains(name)) return '삭제할 부서를 찾지 못했습니다.';
    if (current.accounts.any((account) => account.department == name)) {
      return '소속 직원이 있는 부서는 삭제할 수 없습니다.';
    }
    final remainingDepartments = current.departments
        .where((department) => department != name)
        .toList();
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(
        organizationDepartments: value.organizationDepartments
            .where((department) => department != name)
            .toList(),
        selectedOrgDepartment: value.selectedOrgDepartment == name
            ? (remainingDepartments.firstOrNull ?? '')
            : value.selectedOrgDepartment,
        clearSelectedOrgUser: value.selectedOrgDepartment == name,
        leaveApprovalLines: {
          for (final entry in value.leaveApprovalLines.entries)
            if (entry.key != name) entry.key: entry.value,
        },
      ),
    );
    syncRemote(() => api.deleteDepartment(name));
    return null;
  }

  void updateAnnualLeavePolicy(int year, int days) {
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(
        annualLeaveByYear: {...value.annualLeaveByYear, year: days},
      ),
    );
    final policy =
        currentDashboardState?.annualLeaveByYear ?? const <int, int>{};
    syncRemote(
      () => api.updateSettings({
        'annualLeaveByYear': {
          for (final entry in policy.entries) '${entry.key}': entry.value,
        },
      }),
    );
  }

  String? updateAnnualLeavePolicies(
    Map<int, int> policies, {
    int? monthlyLeavePerMonth,
  }) {
    if (policies.isEmpty) return '저장할 연차 설정이 없습니다.';
    if (policies.values.any((days) => days < 1 || days > 365)) {
      return '연차 일수는 1일 이상 365일 이하로 입력해 주세요.';
    }
    if (monthlyLeavePerMonth != null &&
        (monthlyLeavePerMonth < 1 || monthlyLeavePerMonth > 31)) {
      return '월차 지급 일수는 1일 이상 31일 이하로 입력해 주세요.';
    }
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(
        annualLeaveByYear: {...policies},
        monthlyLeavePerMonth: monthlyLeavePerMonth,
      ),
    );
    syncRemote(
      () => api.updateSettings({
        'annualLeaveByYear': {
          for (final entry in policies.entries) '${entry.key}': entry.value,
        },
        'monthlyLeavePerMonth': ?monthlyLeavePerMonth,
      }),
    );
    return null;
  }

  String? updateDepartmentLeaveApprovalLine(
    String department,
    List<String> userIds,
  ) {
    final current = currentDashboardState;
    if (current == null || !current.isAdminMode) {
      return '관리자 모드에서만 휴가 결재라인을 수정할 수 있습니다.';
    }
    if (!current.departments.contains(department)) {
      return '부서 정보를 찾지 못했습니다.';
    }
    final normalized = userIds
        .where((id) => current.accounts.any((account) => account.id == id))
        .toSet()
        .toList();
    if (normalized.isEmpty) return '한 명 이상의 휴가 결재자를 선택해 주세요.';
    final updated = {...current.leaveApprovalLines, department: normalized};
    setApprovalDashboardState(
      this,
      (value) => value.copyWith(leaveApprovalLines: updated),
    );
    syncRemote(() => api.updateSettings({'leaveApprovalLines': updated}));
    return null;
  }

  String? addLeaveForEmployee({
    required String userId,
    required String type,
    required String startDate,
    required String endDate,
    required double days,
    required String reason,
  }) {
    final current = currentDashboardState;
    if (current == null || !current.isAdminMode) {
      return '관리자 모드에서만 휴가를 직접 등록할 수 있습니다.';
    }
    final account = current.accounts
        .where((item) => item.id == userId)
        .firstOrNull;
    if (account == null) return '직원 정보를 찾을 수 없습니다.';
    if (reason.trim().isEmpty) return '관리자 등록 사유를 입력해 주세요.';
    final parsedStart = DateTime.tryParse(startDate);
    final parsedEnd = DateTime.tryParse(endDate);
    if (parsedStart == null ||
        parsedEnd == null ||
        parsedEnd.isBefore(parsedStart)) {
      return '휴가 날짜를 확인해 주세요.';
    }
    if (days <= 0) return '사용 일수를 확인해 주세요.';
    final remaining = current.remainingAnnualLeaveFor(account);
    if (days > remaining) {
      return '잔여 휴가 ${remaining.toStringAsFixed(remaining == remaining.roundToDouble() ? 0 : 1)}일을 초과했습니다.';
    }
    syncRemote(
      () => api.createLeave(
        userId: userId,
        type: type,
        startDate: startDate,
        endDate: endDate,
        days: days,
        reason: reason.trim(),
        directEntry: true,
      ),
    );
    return null;
  }

  void requestLeave({
    required String type,
    required String startDate,
    required String endDate,
    required double days,
    required String reason,
  }) {
    syncRemote(
      () => api.createLeave(
        type: type,
        startDate: startDate,
        endDate: endDate,
        days: days,
        reason: reason,
      ),
    );
  }

  void updateLeaveStatus(String requestId, String status) {
    if (status == '승인완료' || status == '반려') {
      syncRemote(() => api.actOnLeave(requestId, approve: status == '승인완료'));
    }
  }

  bool actOnLeave(String requestId, {required bool approve}) {
    final current = currentDashboardState;
    if (current == null || current.currentUser == null) return false;
    final request = current.leaveRequests
        .where((item) => item.id == requestId)
        .firstOrNull;
    if (request == null || !current.canActOnLeave(request)) return false;

    syncRemote(() => api.actOnLeave(requestId, approve: approve));
    return true;
  }

  void acknowledgeApprovedLeaves([Iterable<String>? requestIds]) {
    final targets =
        requestIds?.toSet() ??
        currentDashboardState?.unacknowledgedApprovedLeaveRequests
            .map((request) => request.id)
            .toSet() ??
        const <String>{};
    setApprovalDashboardState(this, (value) {
      final targets =
          requestIds?.toSet() ??
          value.unacknowledgedApprovedLeaveRequests
              .map((request) => request.id)
              .toSet();
      return value.copyWith(
        acknowledgedLeaveRequestIds: {
          ...value.acknowledgedLeaveRequestIds,
          ...targets,
        },
      );
    });
    for (final id in targets) {
      syncRemote(() => api.acknowledgeLeave(id));
    }
  }
}

bool _validLeaveDays(double? value) =>
    value != null && value.isFinite && value >= 0 && value <= 365;

List<String> _replaceUserId(List<String> values, String oldId, String newId) =>
    values.map((value) => value == oldId ? newId : value).toList();

int _compareNotices(PortalNotice left, PortalNotice right) {
  if (left.isPinned != right.isPinned) return left.isPinned ? -1 : 1;
  return right.createdAt.compareTo(left.createdAt);
}
