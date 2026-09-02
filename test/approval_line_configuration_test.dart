import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_provider_helpers.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/features/approval/presentation/pages/admin/approval_admin_apps_forms.dart';
import 'package:the_we_system/features/approval/presentation/pages/approval/approval_draft_page.dart';

class _ApprovalLineTestController extends ApprovalDashboardController {
  _ApprovalLineTestController(this.initialState);

  final ApprovalDashboardState initialState;

  @override
  Future<ApprovalDashboardState> build() async => initialState;
}

const drafter = EmployeeAccount(
  id: 'drafter',
  password: '',
  name: '기안자',
  department: '기술부',
  position: '대리',
);

const manager = EmployeeAccount(
  id: 'manager',
  password: '',
  name: '부장 결재자',
  department: '기술부',
  position: '부장',
);

const director = EmployeeAccount(
  id: 'director',
  password: '',
  name: '이사 결재자',
  department: '관리부',
  position: '이사',
);

const template = ApprovalFormTemplate(
  id: 'line-form',
  category: '지원',
  name: '결재라인 테스트 양식',
  description: '테스트 양식',
  defaultTitle: '테스트 기안',
  defaultContent: '테스트 내용',
  receivers: [],
  references: [],
  viewers: [],
  publicReceivers: [],
  cooperationDepartment: '',
  agreement: '',
  approvalLines: [
    ApprovalLinePreset(
      id: 'manager-line',
      name: '부장 결재라인',
      userIds: ['manager'],
    ),
    ApprovalLinePreset(
      id: 'director-line',
      name: '임원 결재라인',
      userIds: ['director'],
    ),
  ],
);

ApprovalDashboardState _state() => signedOutApprovalState.copyWith(
  currentUser: drafter,
  accounts: const [drafter, manager, director],
  formTemplates: const [template],
  enabledAppIds: const {'approval'},
);

void main() {
  test('양식 결재라인의 사용자 순서로 결재 단계를 만든다', () {
    final steps = buildApprovalStepsFor(
      drafter,
      const [drafter, manager, director],
      approverIds: const ['director', 'manager'],
    );

    expect(steps.map((step) => step.name), ['기안자', '이사 결재자', '부장 결재자']);
  });

  testWidgets('기안자는 양식에 저장된 결재라인을 선택한다', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1100);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approvalDashboardControllerProvider.overrideWith(
            () => _ApprovalLineTestController(_state()),
          ),
        ],
        child: const MaterialApp(
          home: ApprovalDraftPage(selectedFormId: 'line-form'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('draft-approval-line-selector')),
      findsOneWidget,
    );
    expect(find.text('부장 결재라인'), findsOneWidget);
    expect(find.text('부장 결재자'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('draft-approval-line-dropdown')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('임원 결재라인').last);
    await tester.pumpAndSettle();

    expect(find.text('이사 결재자'), findsOneWidget);
  });

  testWidgets('관리자 양식 수정 화면에서 결재라인을 추가할 수 있다', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1100);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approvalDashboardControllerProvider.overrideWith(
            () => _ApprovalLineTestController(_state()),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: AdminAppManagement(state: _state())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('양식 관리').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('양식 수정'));
    await tester.pumpAndSettle();

    expect(find.text('결재라인'), findsOneWidget);
    expect(find.text('부장 결재라인'), findsWidgets);
    expect(
      find.byKey(const ValueKey('form-approval-line-add')),
      findsOneWidget,
    );
  });
}
