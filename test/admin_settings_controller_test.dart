import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';

void main() {
  test('관리자 통합설정과 전체 문서 권한이 상태에 반영된다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(approvalDashboardControllerProvider.future);
    final notifier = container.read(
      approvalDashboardControllerProvider.notifier,
    );

    notifier.updateSecurityPolicy(
      adminOtpEnabled: false,
      settingsPasswordEnabled: false,
      adminDocumentAccessEnabled: true,
    );
    expect(await notifier.login('edu_manager', '1234'), isTrue);
    expect(notifier.enterAdminMode(''), isTrue);

    var state = container
        .read(approvalDashboardControllerProvider)
        .requireValue;
    expect(state.isAdminMode, isTrue);
    expect(state.visibleDocuments.length, state.documents.length);
    expect(state.adminOtpEnabled, isFalse);
    expect(state.settingsPasswordEnabled, isFalse);

    notifier.updatePortalName('더우리 임직원 포털');
    expect(
      notifier.updatePortalLogo(Uint8List.fromList([1, 2, 3]), 'logo.png'),
      isNull,
    );
    expect(notifier.renameDepartment('교육관리팀', '교육운영팀'), isNull);
    expect(notifier.setAdminPermission('jiyun', true), isNull);

    state = container.read(approvalDashboardControllerProvider).requireValue;
    expect(state.portalName, '더우리 임직원 포털');
    expect(state.customLogoFileName, 'logo.png');
    expect(
      state.accounts
          .where((account) => account.id == 'edu_teacher')
          .single
          .department,
      '교육운영팀',
    );
    expect(
      state.accounts.where((account) => account.id == 'jiyun').single.isAdmin,
      isTrue,
    );
  });
}
