import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_provider_helpers.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';

void main() {
  test('결재라인을 설정하지 않으면 대표가 기본 결재자다', () {
    const drafter = EmployeeAccount(id: 'staff', password: '', name: '직원', department: '공무팀', position: '사원');
    const manager = EmployeeAccount(id: 'manager', password: '', name: '김수현', department: '공무팀', position: '과장', isAdmin: true);
    const ceo = EmployeeAccount(id: 'ceo', password: '', name: '대표님', department: '대표이사', position: '대표');
    expect(approvalChainFor(drafter, [drafter, manager, ceo]).map((item) => item.name), ['대표님']);
  });
}
