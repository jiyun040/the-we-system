import 'package:freezed_annotation/freezed_annotation.dart';

part 'approval_history.freezed.dart';
part 'approval_history.g.dart';

@freezed
abstract class ApprovalHistory with _$ApprovalHistory {
  const factory ApprovalHistory({
    required String id,
    required String category,
    required String date,
    required String user,
    required String description,
    @Default('') String snapshot,
  }) = _ApprovalHistory;

  factory ApprovalHistory.fromJson(Map<String, dynamic> json) =>
      _$ApprovalHistoryFromJson(json);
}
