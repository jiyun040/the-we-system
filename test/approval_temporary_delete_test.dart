import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/core/network/api_exception.dart';
import 'package:the_we_system/core/network/auth_token_store.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/data/datasources/the_we_api_service.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';
import 'package:the_we_system/features/approval/presentation/pages/approval/approval_box_page.dart';

class _TemporaryBoxController extends ApprovalDashboardController {
  _TemporaryBoxController(this.initialState);

  final ApprovalDashboardState initialState;

  @override
  Future<ApprovalDashboardState> build() async => initialState;
}

class _RecordingApiService extends TheWeApiService {
  _RecordingApiService({this.error}) : super(Dio(), AuthTokenStore());

  final Object? error;
  final List<String> deletedDocumentIds = [];

  @override
  Future<void> deleteDraft(String id) async {
    if (error != null) throw error!;
    deletedDocumentIds.add(id);
  }
}

const _employee = EmployeeAccount(
  id: 'employee',
  password: '',
  name: '김직원',
  department: '기술부',
  position: '사원',
);

const _draft = ApprovalDocument(
  id: 'DRAFT-1',
  documentNo: '임시저장',
  title: '삭제할 임시 문서',
  drafter: '김직원',
  department: '기술부',
  form: '업무기안',
  status: '작성중',
  draftedAt: '2026-09-10',
  dueDate: '2026-09-10',
  progress: 0,
);

GoRouter _router() => GoRouter(
  initialLocation: '/approval/temporary',
  routes: [
    GoRoute(
      path: '/approval/temporary',
      name: AppRouteName.temporaryBox,
      builder: (context, state) => const ApprovalBoxPage(kind: 'temporary'),
    ),
  ],
);

Future<void> _pumpTemporaryBox(
  WidgetTester tester,
  _RecordingApiService api,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1600, 1000);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final state = signedOutApprovalState.copyWith(
    currentUser: _employee,
    accounts: const [_employee],
    documents: const [_draft],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        theWeApiServiceProvider.overrideWithValue(api),
        approvalDashboardControllerProvider.overrideWith(
          () => _TemporaryBoxController(state),
        ),
      ],
      child: MaterialApp.router(routerConfig: _router()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('임시저장함에서 확인 후 문서를 삭제하고 목록에서 제거한다', (tester) async {
    final api = _RecordingApiService();
    await _pumpTemporaryBox(tester, api);

    await tester.tap(find.byKey(const ValueKey('delete-draft-DRAFT-1')));
    await tester.pumpAndSettle();

    expect(find.text('임시 저장 문서를 삭제할까요?'), findsOneWidget);
    expect(find.textContaining('삭제 후 복구할 수 없습니다.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await tester.pumpAndSettle();

    expect(api.deletedDocumentIds, ['DRAFT-1']);
    expect(find.byKey(const ValueKey('delete-draft-DRAFT-1')), findsNothing);
    expect(find.text('임시 저장 문서를 삭제했습니다.'), findsOneWidget);
  });

  testWidgets('서버 삭제가 실패하면 임시 문서를 목록에 유지한다', (tester) async {
    final api = _RecordingApiService(error: const ApiException('삭제 실패'));
    await _pumpTemporaryBox(tester, api);

    await tester.tap(find.byKey(const ValueKey('delete-draft-DRAFT-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await tester.pumpAndSettle();

    expect(api.deletedDocumentIds, isEmpty);
    expect(find.byKey(const ValueKey('delete-draft-DRAFT-1')), findsOneWidget);
  });
}
