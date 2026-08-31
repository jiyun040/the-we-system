import 'approval_absence_dependencies.dart';
import 'approval_absence_seed.dart';
import 'approval_attendance_models.dart';

final attendanceControllerProvider =
    NotifierProvider<AttendanceController, Map<String, AttendanceSnapshot>>(
      AttendanceController.new,
    );

class AttendanceController extends Notifier<Map<String, AttendanceSnapshot>> {
  @override
  Map<String, AttendanceSnapshot> build() => approvalAttendanceSeedState;

  void clockIn(String userId) {
    final snapshot = state[userId] ?? approvalEmptyAttendanceSnapshot;
    state = {
      ...state,
      userId: snapshot.copyWith(
        clockInTime: formatApprovalTime(DateTime.now()),
        clearClockOutTime: true,
      ),
    };
  }

  void clockOut(String userId) {
    final snapshot = state[userId] ?? approvalEmptyAttendanceSnapshot;
    state = {
      ...state,
      userId: snapshot.copyWith(
        clockOutTime: formatApprovalTime(DateTime.now()),
      ),
    };
  }

  void addRequest(String userId, AttendanceRequestRecord request) {
    final snapshot = state[userId] ?? approvalEmptyAttendanceSnapshot;
    state = {
      ...state,
      userId: snapshot.copyWith(requests: [request, ...snapshot.requests]),
    };
  }

  void addDelegation(String userId, AttendanceDelegation delegation) {
    final snapshot = state[userId] ?? approvalEmptyAttendanceSnapshot;
    state = {
      ...state,
      userId: snapshot.copyWith(
        delegations: [delegation, ...snapshot.delegations],
      ),
    };
  }
}
