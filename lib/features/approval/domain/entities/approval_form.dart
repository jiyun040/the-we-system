import 'package:freezed_annotation/freezed_annotation.dart';

part 'approval_form.freezed.dart';
part 'approval_form.g.dart';

@freezed
abstract class ApprovalForm with _$ApprovalForm {
  const factory ApprovalForm({
    required String id,
    required String name,
    required String description,
    required int recentCount,
  }) = _ApprovalForm;

  factory ApprovalForm.fromJson(Map<String, dynamic> json) =>
      _$ApprovalFormFromJson(json);
}
