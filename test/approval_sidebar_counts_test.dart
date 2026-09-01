import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_step.dart';
import 'package:the_we_system/features/approval/domain/entities/form/approval_form.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';

ApprovalDocument _document({
  required String id,
  required String drafter,
  bool received = false,
  List<String> receivers = const [],
  List<String> references = const [],
  List<String> viewers = const [],
  List<ApprovalStep> steps = const [],
}) => ApprovalDocument(
  id: id,
  title: id,
  drafter: drafter,
  department: '기술부',
  form: '업무기안[기본양식]',
  status: '결재대기',
  draftedAt: '2026-08-31',
  dueDate: '2026-09-03',
  progress: 0,
  receivedRequest: received,
  receivers: receivers,
  references: references,
  viewers: viewers,
  steps: steps,
);

void main() {
  test('자주 쓰는 양식은 사용 횟수순이며 결재 메뉴 숫자는 문서함 개수와 같다', () {
    const user = EmployeeAccount(
      id: 'test-user',
      password: '',
      name: '테스트 사용자',
      department: '테스트부서',
      position: '담당',
      email: '',
    );
    const template = ApprovalFormTemplate(
      id: 'business-draft',
      category: '지원',
      name: '업무기안[기본양식]',
      description: '일반 기안',
      defaultTitle: '',
      defaultContent: '',
      receivers: [],
      references: [],
      viewers: [],
      publicReceivers: [],
      cooperationDepartment: '',
      agreement: '',
    );
    final state = signedOutApprovalState.copyWith(
      currentUser: user,
      accounts: const [user],
      formTemplates: const [template],
      frequentForms: const [
        ApprovalForm(
          id: 'unused-form',
          name: '미사용 양식',
          description: '',
          recentCount: 0,
        ),
        ApprovalForm(
          id: 'business-draft',
          name: '업무기안[기본양식]',
          description: '일반 기안',
          recentCount: 4,
        ),
      ],
      documents: [
        _document(
          id: 'waiting',
          drafter: '기안자 A',
          steps: const [
            ApprovalStep(name: '테스트 사용자', department: '테스트부서', status: '진행중'),
          ],
        ),
        _document(
          id: 'received',
          drafter: '기안자 B',
          received: true,
          receivers: const ['테스트부서'],
        ),
        _document(
          id: 'not-received',
          drafter: '기안자 B',
          received: true,
          receivers: const ['기술부'],
        ),
        _document(
          id: 'reference',
          drafter: '기안자 C',
          references: const ['test-user'],
        ),
        _document(
          id: 'scheduled',
          drafter: '기안자 D',
          steps: const [
            ApprovalStep(name: '테스트 사용자', department: '테스트부서', status: '결재 예정'),
          ],
        ),
      ],
    );

    expect(state.activeFrequentForms, hasLength(1));
    expect(state.activeFrequentForms.single.recentCount, 4);
    expect(state.dashboard.pendingCount, state.waitingDocuments.length);
    expect(state.dashboard.receivedCount, state.receivedDocuments.length);
    expect(state.dashboard.referenceCount, state.referenceDocuments.length);
    expect(state.dashboard.scheduledCount, state.scheduledDocuments.length);
    expect(state.dashboard.pendingCount, 1);
    expect(state.dashboard.receivedCount, 1);
    expect(state.dashboard.referenceCount, 1);
    expect(state.dashboard.scheduledCount, 1);
  });
}
