// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'approval_document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ApprovalDocument {

 String get id; String get title; String get drafter; String get department; String get form; String get status; String get draftedAt; String get dueDate; int get progress; String get documentNo; String get effectiveDate; String get cooperationDepartment; String get agreement; String get content; bool get urgent; bool get receivedRequest; bool get canCancel; bool get canReuse; bool get canEdit; List<String> get receivers; List<String> get references; List<String> get viewers; List<String> get publicReceivers; List<String> get linkedDocuments; String get documentLayout; Map<String, String> get formFields; List<Map<String, String>> get lineItems; List<ApprovalStep> get steps; List<ApprovalHistory> get histories;
/// Create a copy of ApprovalDocument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApprovalDocumentCopyWith<ApprovalDocument> get copyWith => _$ApprovalDocumentCopyWithImpl<ApprovalDocument>(this as ApprovalDocument, _$identity);

  /// Serializes this ApprovalDocument to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApprovalDocument&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.drafter, drafter) || other.drafter == drafter)&&(identical(other.department, department) || other.department == department)&&(identical(other.form, form) || other.form == form)&&(identical(other.status, status) || other.status == status)&&(identical(other.draftedAt, draftedAt) || other.draftedAt == draftedAt)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.documentNo, documentNo) || other.documentNo == documentNo)&&(identical(other.effectiveDate, effectiveDate) || other.effectiveDate == effectiveDate)&&(identical(other.cooperationDepartment, cooperationDepartment) || other.cooperationDepartment == cooperationDepartment)&&(identical(other.agreement, agreement) || other.agreement == agreement)&&(identical(other.content, content) || other.content == content)&&(identical(other.urgent, urgent) || other.urgent == urgent)&&(identical(other.receivedRequest, receivedRequest) || other.receivedRequest == receivedRequest)&&(identical(other.canCancel, canCancel) || other.canCancel == canCancel)&&(identical(other.canReuse, canReuse) || other.canReuse == canReuse)&&(identical(other.canEdit, canEdit) || other.canEdit == canEdit)&&const DeepCollectionEquality().equals(other.receivers, receivers)&&const DeepCollectionEquality().equals(other.references, references)&&const DeepCollectionEquality().equals(other.viewers, viewers)&&const DeepCollectionEquality().equals(other.publicReceivers, publicReceivers)&&const DeepCollectionEquality().equals(other.linkedDocuments, linkedDocuments)&&(identical(other.documentLayout, documentLayout) || other.documentLayout == documentLayout)&&const DeepCollectionEquality().equals(other.formFields, formFields)&&const DeepCollectionEquality().equals(other.lineItems, lineItems)&&const DeepCollectionEquality().equals(other.steps, steps)&&const DeepCollectionEquality().equals(other.histories, histories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,drafter,department,form,status,draftedAt,dueDate,progress,documentNo,effectiveDate,cooperationDepartment,agreement,content,urgent,receivedRequest,canCancel,canReuse,canEdit,const DeepCollectionEquality().hash(receivers),const DeepCollectionEquality().hash(references),const DeepCollectionEquality().hash(viewers),const DeepCollectionEquality().hash(publicReceivers),const DeepCollectionEquality().hash(linkedDocuments),documentLayout,const DeepCollectionEquality().hash(formFields),const DeepCollectionEquality().hash(lineItems),const DeepCollectionEquality().hash(steps),const DeepCollectionEquality().hash(histories)]);

@override
String toString() {
  return 'ApprovalDocument(id: $id, title: $title, drafter: $drafter, department: $department, form: $form, status: $status, draftedAt: $draftedAt, dueDate: $dueDate, progress: $progress, documentNo: $documentNo, effectiveDate: $effectiveDate, cooperationDepartment: $cooperationDepartment, agreement: $agreement, content: $content, urgent: $urgent, receivedRequest: $receivedRequest, canCancel: $canCancel, canReuse: $canReuse, canEdit: $canEdit, receivers: $receivers, references: $references, viewers: $viewers, publicReceivers: $publicReceivers, linkedDocuments: $linkedDocuments, documentLayout: $documentLayout, formFields: $formFields, lineItems: $lineItems, steps: $steps, histories: $histories)';
}


}

/// @nodoc
abstract mixin class $ApprovalDocumentCopyWith<$Res>  {
  factory $ApprovalDocumentCopyWith(ApprovalDocument value, $Res Function(ApprovalDocument) _then) = _$ApprovalDocumentCopyWithImpl;
@useResult
$Res call({
 String id, String title, String drafter, String department, String form, String status, String draftedAt, String dueDate, int progress, String documentNo, String effectiveDate, String cooperationDepartment, String agreement, String content, bool urgent, bool receivedRequest, bool canCancel, bool canReuse, bool canEdit, List<String> receivers, List<String> references, List<String> viewers, List<String> publicReceivers, List<String> linkedDocuments, String documentLayout, Map<String, String> formFields, List<Map<String, String>> lineItems, List<ApprovalStep> steps, List<ApprovalHistory> histories
});




}
/// @nodoc
class _$ApprovalDocumentCopyWithImpl<$Res>
    implements $ApprovalDocumentCopyWith<$Res> {
  _$ApprovalDocumentCopyWithImpl(this._self, this._then);

  final ApprovalDocument _self;
  final $Res Function(ApprovalDocument) _then;

/// Create a copy of ApprovalDocument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? drafter = null,Object? department = null,Object? form = null,Object? status = null,Object? draftedAt = null,Object? dueDate = null,Object? progress = null,Object? documentNo = null,Object? effectiveDate = null,Object? cooperationDepartment = null,Object? agreement = null,Object? content = null,Object? urgent = null,Object? receivedRequest = null,Object? canCancel = null,Object? canReuse = null,Object? canEdit = null,Object? receivers = null,Object? references = null,Object? viewers = null,Object? publicReceivers = null,Object? linkedDocuments = null,Object? documentLayout = null,Object? formFields = null,Object? lineItems = null,Object? steps = null,Object? histories = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,drafter: null == drafter ? _self.drafter : drafter // ignore: cast_nullable_to_non_nullable
as String,department: null == department ? _self.department : department // ignore: cast_nullable_to_non_nullable
as String,form: null == form ? _self.form : form // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,draftedAt: null == draftedAt ? _self.draftedAt : draftedAt // ignore: cast_nullable_to_non_nullable
as String,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as int,documentNo: null == documentNo ? _self.documentNo : documentNo // ignore: cast_nullable_to_non_nullable
as String,effectiveDate: null == effectiveDate ? _self.effectiveDate : effectiveDate // ignore: cast_nullable_to_non_nullable
as String,cooperationDepartment: null == cooperationDepartment ? _self.cooperationDepartment : cooperationDepartment // ignore: cast_nullable_to_non_nullable
as String,agreement: null == agreement ? _self.agreement : agreement // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,urgent: null == urgent ? _self.urgent : urgent // ignore: cast_nullable_to_non_nullable
as bool,receivedRequest: null == receivedRequest ? _self.receivedRequest : receivedRequest // ignore: cast_nullable_to_non_nullable
as bool,canCancel: null == canCancel ? _self.canCancel : canCancel // ignore: cast_nullable_to_non_nullable
as bool,canReuse: null == canReuse ? _self.canReuse : canReuse // ignore: cast_nullable_to_non_nullable
as bool,canEdit: null == canEdit ? _self.canEdit : canEdit // ignore: cast_nullable_to_non_nullable
as bool,receivers: null == receivers ? _self.receivers : receivers // ignore: cast_nullable_to_non_nullable
as List<String>,references: null == references ? _self.references : references // ignore: cast_nullable_to_non_nullable
as List<String>,viewers: null == viewers ? _self.viewers : viewers // ignore: cast_nullable_to_non_nullable
as List<String>,publicReceivers: null == publicReceivers ? _self.publicReceivers : publicReceivers // ignore: cast_nullable_to_non_nullable
as List<String>,linkedDocuments: null == linkedDocuments ? _self.linkedDocuments : linkedDocuments // ignore: cast_nullable_to_non_nullable
as List<String>,documentLayout: null == documentLayout ? _self.documentLayout : documentLayout // ignore: cast_nullable_to_non_nullable
as String,formFields: null == formFields ? _self.formFields : formFields // ignore: cast_nullable_to_non_nullable
as Map<String, String>,lineItems: null == lineItems ? _self.lineItems : lineItems // ignore: cast_nullable_to_non_nullable
as List<Map<String, String>>,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<ApprovalStep>,histories: null == histories ? _self.histories : histories // ignore: cast_nullable_to_non_nullable
as List<ApprovalHistory>,
  ));
}

}


/// Adds pattern-matching-related methods to [ApprovalDocument].
extension ApprovalDocumentPatterns on ApprovalDocument {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApprovalDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApprovalDocument() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApprovalDocument value)  $default,){
final _that = this;
switch (_that) {
case _ApprovalDocument():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApprovalDocument value)?  $default,){
final _that = this;
switch (_that) {
case _ApprovalDocument() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String drafter,  String department,  String form,  String status,  String draftedAt,  String dueDate,  int progress,  String documentNo,  String effectiveDate,  String cooperationDepartment,  String agreement,  String content,  bool urgent,  bool receivedRequest,  bool canCancel,  bool canReuse,  bool canEdit,  List<String> receivers,  List<String> references,  List<String> viewers,  List<String> publicReceivers,  List<String> linkedDocuments,  String documentLayout,  Map<String, String> formFields,  List<Map<String, String>> lineItems,  List<ApprovalStep> steps,  List<ApprovalHistory> histories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApprovalDocument() when $default != null:
return $default(_that.id,_that.title,_that.drafter,_that.department,_that.form,_that.status,_that.draftedAt,_that.dueDate,_that.progress,_that.documentNo,_that.effectiveDate,_that.cooperationDepartment,_that.agreement,_that.content,_that.urgent,_that.receivedRequest,_that.canCancel,_that.canReuse,_that.canEdit,_that.receivers,_that.references,_that.viewers,_that.publicReceivers,_that.linkedDocuments,_that.documentLayout,_that.formFields,_that.lineItems,_that.steps,_that.histories);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String drafter,  String department,  String form,  String status,  String draftedAt,  String dueDate,  int progress,  String documentNo,  String effectiveDate,  String cooperationDepartment,  String agreement,  String content,  bool urgent,  bool receivedRequest,  bool canCancel,  bool canReuse,  bool canEdit,  List<String> receivers,  List<String> references,  List<String> viewers,  List<String> publicReceivers,  List<String> linkedDocuments,  String documentLayout,  Map<String, String> formFields,  List<Map<String, String>> lineItems,  List<ApprovalStep> steps,  List<ApprovalHistory> histories)  $default,) {final _that = this;
switch (_that) {
case _ApprovalDocument():
return $default(_that.id,_that.title,_that.drafter,_that.department,_that.form,_that.status,_that.draftedAt,_that.dueDate,_that.progress,_that.documentNo,_that.effectiveDate,_that.cooperationDepartment,_that.agreement,_that.content,_that.urgent,_that.receivedRequest,_that.canCancel,_that.canReuse,_that.canEdit,_that.receivers,_that.references,_that.viewers,_that.publicReceivers,_that.linkedDocuments,_that.documentLayout,_that.formFields,_that.lineItems,_that.steps,_that.histories);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String drafter,  String department,  String form,  String status,  String draftedAt,  String dueDate,  int progress,  String documentNo,  String effectiveDate,  String cooperationDepartment,  String agreement,  String content,  bool urgent,  bool receivedRequest,  bool canCancel,  bool canReuse,  bool canEdit,  List<String> receivers,  List<String> references,  List<String> viewers,  List<String> publicReceivers,  List<String> linkedDocuments,  String documentLayout,  Map<String, String> formFields,  List<Map<String, String>> lineItems,  List<ApprovalStep> steps,  List<ApprovalHistory> histories)?  $default,) {final _that = this;
switch (_that) {
case _ApprovalDocument() when $default != null:
return $default(_that.id,_that.title,_that.drafter,_that.department,_that.form,_that.status,_that.draftedAt,_that.dueDate,_that.progress,_that.documentNo,_that.effectiveDate,_that.cooperationDepartment,_that.agreement,_that.content,_that.urgent,_that.receivedRequest,_that.canCancel,_that.canReuse,_that.canEdit,_that.receivers,_that.references,_that.viewers,_that.publicReceivers,_that.linkedDocuments,_that.documentLayout,_that.formFields,_that.lineItems,_that.steps,_that.histories);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApprovalDocument implements ApprovalDocument {
  const _ApprovalDocument({required this.id, required this.title, required this.drafter, required this.department, required this.form, required this.status, required this.draftedAt, required this.dueDate, required this.progress, this.documentNo = '', this.effectiveDate = '', this.cooperationDepartment = '', this.agreement = '', this.content = '', this.urgent = false, this.receivedRequest = false, this.canCancel = false, this.canReuse = true, this.canEdit = true, final  List<String> receivers = const <String>[], final  List<String> references = const <String>[], final  List<String> viewers = const <String>[], final  List<String> publicReceivers = const <String>[], final  List<String> linkedDocuments = const <String>[], this.documentLayout = 'basic', final  Map<String, String> formFields = const <String, String>{}, final  List<Map<String, String>> lineItems = const <Map<String, String>>[], final  List<ApprovalStep> steps = const <ApprovalStep>[], final  List<ApprovalHistory> histories = const <ApprovalHistory>[]}): _receivers = receivers,_references = references,_viewers = viewers,_publicReceivers = publicReceivers,_linkedDocuments = linkedDocuments,_formFields = formFields,_lineItems = lineItems,_steps = steps,_histories = histories;
  factory _ApprovalDocument.fromJson(Map<String, dynamic> json) => _$ApprovalDocumentFromJson(json);

@override final  String id;
@override final  String title;
@override final  String drafter;
@override final  String department;
@override final  String form;
@override final  String status;
@override final  String draftedAt;
@override final  String dueDate;
@override final  int progress;
@override@JsonKey() final  String documentNo;
@override@JsonKey() final  String effectiveDate;
@override@JsonKey() final  String cooperationDepartment;
@override@JsonKey() final  String agreement;
@override@JsonKey() final  String content;
@override@JsonKey() final  bool urgent;
@override@JsonKey() final  bool receivedRequest;
@override@JsonKey() final  bool canCancel;
@override@JsonKey() final  bool canReuse;
@override@JsonKey() final  bool canEdit;
 final  List<String> _receivers;
@override@JsonKey() List<String> get receivers {
  if (_receivers is EqualUnmodifiableListView) return _receivers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_receivers);
}

 final  List<String> _references;
@override@JsonKey() List<String> get references {
  if (_references is EqualUnmodifiableListView) return _references;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_references);
}

 final  List<String> _viewers;
@override@JsonKey() List<String> get viewers {
  if (_viewers is EqualUnmodifiableListView) return _viewers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_viewers);
}

 final  List<String> _publicReceivers;
@override@JsonKey() List<String> get publicReceivers {
  if (_publicReceivers is EqualUnmodifiableListView) return _publicReceivers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_publicReceivers);
}

 final  List<String> _linkedDocuments;
@override@JsonKey() List<String> get linkedDocuments {
  if (_linkedDocuments is EqualUnmodifiableListView) return _linkedDocuments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_linkedDocuments);
}

@override@JsonKey() final  String documentLayout;
 final  Map<String, String> _formFields;
@override@JsonKey() Map<String, String> get formFields {
  if (_formFields is EqualUnmodifiableMapView) return _formFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_formFields);
}

 final  List<Map<String, String>> _lineItems;
@override@JsonKey() List<Map<String, String>> get lineItems {
  if (_lineItems is EqualUnmodifiableListView) return _lineItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lineItems);
}

 final  List<ApprovalStep> _steps;
@override@JsonKey() List<ApprovalStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

 final  List<ApprovalHistory> _histories;
@override@JsonKey() List<ApprovalHistory> get histories {
  if (_histories is EqualUnmodifiableListView) return _histories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_histories);
}


/// Create a copy of ApprovalDocument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApprovalDocumentCopyWith<_ApprovalDocument> get copyWith => __$ApprovalDocumentCopyWithImpl<_ApprovalDocument>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApprovalDocumentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApprovalDocument&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.drafter, drafter) || other.drafter == drafter)&&(identical(other.department, department) || other.department == department)&&(identical(other.form, form) || other.form == form)&&(identical(other.status, status) || other.status == status)&&(identical(other.draftedAt, draftedAt) || other.draftedAt == draftedAt)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.documentNo, documentNo) || other.documentNo == documentNo)&&(identical(other.effectiveDate, effectiveDate) || other.effectiveDate == effectiveDate)&&(identical(other.cooperationDepartment, cooperationDepartment) || other.cooperationDepartment == cooperationDepartment)&&(identical(other.agreement, agreement) || other.agreement == agreement)&&(identical(other.content, content) || other.content == content)&&(identical(other.urgent, urgent) || other.urgent == urgent)&&(identical(other.receivedRequest, receivedRequest) || other.receivedRequest == receivedRequest)&&(identical(other.canCancel, canCancel) || other.canCancel == canCancel)&&(identical(other.canReuse, canReuse) || other.canReuse == canReuse)&&(identical(other.canEdit, canEdit) || other.canEdit == canEdit)&&const DeepCollectionEquality().equals(other._receivers, _receivers)&&const DeepCollectionEquality().equals(other._references, _references)&&const DeepCollectionEquality().equals(other._viewers, _viewers)&&const DeepCollectionEquality().equals(other._publicReceivers, _publicReceivers)&&const DeepCollectionEquality().equals(other._linkedDocuments, _linkedDocuments)&&(identical(other.documentLayout, documentLayout) || other.documentLayout == documentLayout)&&const DeepCollectionEquality().equals(other._formFields, _formFields)&&const DeepCollectionEquality().equals(other._lineItems, _lineItems)&&const DeepCollectionEquality().equals(other._steps, _steps)&&const DeepCollectionEquality().equals(other._histories, _histories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,drafter,department,form,status,draftedAt,dueDate,progress,documentNo,effectiveDate,cooperationDepartment,agreement,content,urgent,receivedRequest,canCancel,canReuse,canEdit,const DeepCollectionEquality().hash(_receivers),const DeepCollectionEquality().hash(_references),const DeepCollectionEquality().hash(_viewers),const DeepCollectionEquality().hash(_publicReceivers),const DeepCollectionEquality().hash(_linkedDocuments),documentLayout,const DeepCollectionEquality().hash(_formFields),const DeepCollectionEquality().hash(_lineItems),const DeepCollectionEquality().hash(_steps),const DeepCollectionEquality().hash(_histories)]);

@override
String toString() {
  return 'ApprovalDocument(id: $id, title: $title, drafter: $drafter, department: $department, form: $form, status: $status, draftedAt: $draftedAt, dueDate: $dueDate, progress: $progress, documentNo: $documentNo, effectiveDate: $effectiveDate, cooperationDepartment: $cooperationDepartment, agreement: $agreement, content: $content, urgent: $urgent, receivedRequest: $receivedRequest, canCancel: $canCancel, canReuse: $canReuse, canEdit: $canEdit, receivers: $receivers, references: $references, viewers: $viewers, publicReceivers: $publicReceivers, linkedDocuments: $linkedDocuments, documentLayout: $documentLayout, formFields: $formFields, lineItems: $lineItems, steps: $steps, histories: $histories)';
}


}

/// @nodoc
abstract mixin class _$ApprovalDocumentCopyWith<$Res> implements $ApprovalDocumentCopyWith<$Res> {
  factory _$ApprovalDocumentCopyWith(_ApprovalDocument value, $Res Function(_ApprovalDocument) _then) = __$ApprovalDocumentCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String drafter, String department, String form, String status, String draftedAt, String dueDate, int progress, String documentNo, String effectiveDate, String cooperationDepartment, String agreement, String content, bool urgent, bool receivedRequest, bool canCancel, bool canReuse, bool canEdit, List<String> receivers, List<String> references, List<String> viewers, List<String> publicReceivers, List<String> linkedDocuments, String documentLayout, Map<String, String> formFields, List<Map<String, String>> lineItems, List<ApprovalStep> steps, List<ApprovalHistory> histories
});




}
/// @nodoc
class __$ApprovalDocumentCopyWithImpl<$Res>
    implements _$ApprovalDocumentCopyWith<$Res> {
  __$ApprovalDocumentCopyWithImpl(this._self, this._then);

  final _ApprovalDocument _self;
  final $Res Function(_ApprovalDocument) _then;

/// Create a copy of ApprovalDocument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? drafter = null,Object? department = null,Object? form = null,Object? status = null,Object? draftedAt = null,Object? dueDate = null,Object? progress = null,Object? documentNo = null,Object? effectiveDate = null,Object? cooperationDepartment = null,Object? agreement = null,Object? content = null,Object? urgent = null,Object? receivedRequest = null,Object? canCancel = null,Object? canReuse = null,Object? canEdit = null,Object? receivers = null,Object? references = null,Object? viewers = null,Object? publicReceivers = null,Object? linkedDocuments = null,Object? documentLayout = null,Object? formFields = null,Object? lineItems = null,Object? steps = null,Object? histories = null,}) {
  return _then(_ApprovalDocument(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,drafter: null == drafter ? _self.drafter : drafter // ignore: cast_nullable_to_non_nullable
as String,department: null == department ? _self.department : department // ignore: cast_nullable_to_non_nullable
as String,form: null == form ? _self.form : form // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,draftedAt: null == draftedAt ? _self.draftedAt : draftedAt // ignore: cast_nullable_to_non_nullable
as String,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as int,documentNo: null == documentNo ? _self.documentNo : documentNo // ignore: cast_nullable_to_non_nullable
as String,effectiveDate: null == effectiveDate ? _self.effectiveDate : effectiveDate // ignore: cast_nullable_to_non_nullable
as String,cooperationDepartment: null == cooperationDepartment ? _self.cooperationDepartment : cooperationDepartment // ignore: cast_nullable_to_non_nullable
as String,agreement: null == agreement ? _self.agreement : agreement // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,urgent: null == urgent ? _self.urgent : urgent // ignore: cast_nullable_to_non_nullable
as bool,receivedRequest: null == receivedRequest ? _self.receivedRequest : receivedRequest // ignore: cast_nullable_to_non_nullable
as bool,canCancel: null == canCancel ? _self.canCancel : canCancel // ignore: cast_nullable_to_non_nullable
as bool,canReuse: null == canReuse ? _self.canReuse : canReuse // ignore: cast_nullable_to_non_nullable
as bool,canEdit: null == canEdit ? _self.canEdit : canEdit // ignore: cast_nullable_to_non_nullable
as bool,receivers: null == receivers ? _self._receivers : receivers // ignore: cast_nullable_to_non_nullable
as List<String>,references: null == references ? _self._references : references // ignore: cast_nullable_to_non_nullable
as List<String>,viewers: null == viewers ? _self._viewers : viewers // ignore: cast_nullable_to_non_nullable
as List<String>,publicReceivers: null == publicReceivers ? _self._publicReceivers : publicReceivers // ignore: cast_nullable_to_non_nullable
as List<String>,linkedDocuments: null == linkedDocuments ? _self._linkedDocuments : linkedDocuments // ignore: cast_nullable_to_non_nullable
as List<String>,documentLayout: null == documentLayout ? _self.documentLayout : documentLayout // ignore: cast_nullable_to_non_nullable
as String,formFields: null == formFields ? _self._formFields : formFields // ignore: cast_nullable_to_non_nullable
as Map<String, String>,lineItems: null == lineItems ? _self._lineItems : lineItems // ignore: cast_nullable_to_non_nullable
as List<Map<String, String>>,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<ApprovalStep>,histories: null == histories ? _self._histories : histories // ignore: cast_nullable_to_non_nullable
as List<ApprovalHistory>,
  ));
}


}

// dart format on
