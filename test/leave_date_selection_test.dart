import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/features/approval/presentation/models/approval_local_models.dart';

void main() {
  test('시작일을 고르면 종료일도 같은 날로 따라가고 이후에는 개별 수정된다', () {
    final selection = LeaveDateSelection(
      type: '연차',
      startDate: DateTime(2026, 9, 3),
    );

    expect(selection.endDate, DateTime(2026, 9, 3));

    selection.selectStartDate(DateTime(2026, 9, 5));
    expect(selection.endDate, DateTime(2026, 9, 5));

    selection.selectEndDate(DateTime(2026, 9, 8));
    selection.selectStartDate(DateTime(2026, 9, 6));
    expect(selection.startDate, DateTime(2026, 9, 6));
    expect(selection.endDate, DateTime(2026, 9, 8));
    expect(selection.days, 3);
  });

  test('반차는 시작일과 종료일이 같고 0.5일로 계산된다', () {
    final selection = LeaveDateSelection(
      type: '연차',
      startDate: DateTime(2026, 9, 3),
    )..selectEndDate(DateTime(2026, 9, 5));

    selection.selectType('반차');

    expect(selection.startDate, DateTime(2026, 9, 3));
    expect(selection.endDate, DateTime(2026, 9, 3));
    expect(selection.days, .5);
  });

  test('현장팀은 토요일을 포함하고 일요일은 포함하지 않는다', () {
    final selection = LeaveDateSelection(
      type: '연차',
      department: '현장팀',
      startDate: DateTime(2026, 9, 4),
    )..selectEndDate(DateTime(2026, 9, 6));

    expect(selection.days, 2);
  });
}
