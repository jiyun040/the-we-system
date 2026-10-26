import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/sales/domain/sales_ledger_entry.dart';
import 'package:the_we_system/features/sales/domain/sales_ledger_order.dart';

void main() {
  SalesLedgerEntry entry(
    String name,
    String date, {
    String status = '신규',
    String category = '본사',
    String elevator = '1호기',
  }) => SalesLedgerEntry.fromJson({
    'id': '$name-$date',
    'projectName': name,
    'startDate': date,
    'status': status,
    'category': category,
    'elevator': elevator,
  });

  test('기록일이 9월이어도 실사용 시작이 10월이면 10월 신규다', () {
    final october = SalesLedgerEntry.fromJson({
      'id': 'october-use',
      'projectName': '10월 사용 현장',
      'elevator': '1호기',
      'recordDate': '2026-09-21',
      'contractStartDate': '2026-10-02',
      'startDate': '2026-10-02',
    });
    final november = SalesLedgerEntry.fromJson({
      'id': 'october-use',
      'projectName': '10월 사용 현장',
      'elevator': '1호기',
      'recordDate': '2026-09-21',
      'contractStartDate': '2026-10-02',
      'startDate': '2026-11-01',
    });
    expect(classifyAndSortLedger([october], const [], month: DateTime(2026, 10)).single.status, '신규');
    expect(classifyAndSortLedger([november], [october], month: DateTime(2026, 11)).single.status, '진행');
  });

  test('전월 사용 현장은 진행, 당월 첫 사용 현장은 신규로 정렬한다', () {
    final result = classifyAndSortLedger(
      [
        entry('다 현장', '2026-10-20'),
        entry('나 현장', '2026-10-03'),
        entry('가 현장', '2026-10-10'),
        entry('종료 현장', '2026-10-01', status: '종료'),
        entry('기존 현장', '2026-10-02'),
        entry('기존 현장', '2026-10-18', elevator: '2호기'),
        entry('가 진행', '2026-10-15'),
        entry('가맹 신규', '2026-10-04', category: '가맹'),
        entry('가맹 진행', '2026-10-22', category: '가맹'),
      ],
      [
        entry('기존 현장', '2026-09-01'),
        entry('가 진행', '2026-09-20'),
        entry('가맹 진행', '2026-09-21', category: '가맹'),
      ],
    );
    expect(result.map((item) => '${item.projectName}:${item.status}'), [
      '가 진행:진행',
      '가 현장:신규',
      '기존 현장:진행',
      '기존 현장:신규',
      '나 현장:신규',
      '다 현장:신규',
      '종료 현장:종료',
      '가맹 신규:신규',
      '가맹 진행:진행',
    ]);
  });

  test('진행 호기가 종료되어도 같은 현장의 새 호기 위에 남는다', () {
    final previous = [entry('가 현장', '2026-09-01')];
    final current = [
      entry('가 현장', '2026-10-12', elevator: '2호기'),
      entry('가 현장', '2026-09-01'),
    ];
    final active = classifyAndSortLedger(current, previous);
    final ended = classifyAndSortLedger([
      current[0],
      current[1].copyWith(status: '종료'),
    ], previous);
    expect(active.map((item) => item.elevator), ['1호기', '2호기']);
    expect(ended.map((item) => item.elevator), ['1호기', '2호기']);
    expect(ended.first.status, '종료');
    expect(ended.last.status, '신규');
  });
}
