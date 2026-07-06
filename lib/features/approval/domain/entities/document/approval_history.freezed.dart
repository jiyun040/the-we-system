// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'approval_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ApprovalHistory {

 String get id; String get category; String get date; String get user; String get description; String get snapshot;
/// Create a copy of ApprovalHistory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApprovalHistoryCopyWith<ApprovalHistory> get copyWith => _$ApprovalHistoryCopyWithImpl<ApprovalHistory>(this as ApprovalHistory, _$identity);

  /// Serializes this ApprovalHistory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApprovalHistory&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.date, date) || other.date == date)&&(identical(other.user, user) || other.user == user)&&(identical(other.description, description) || other.description == description)&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,category,date,user,description,snapshot);

@override
String toString() {
  return 'ApprovalHistory(id: $id, category: $category, date: $date, user: $user, description: $description, snapshot: $snapshot)';
}


}

/// @nodoc
abstract mixin class $ApprovalHistoryCopyWith<$Res>  {
  factory $ApprovalHistoryCopyWith(ApprovalHistory value, $Res Function(ApprovalHistory) _then) = _$ApprovalHistoryCopyWithImpl;
@useResult
$Res call({
 String id, String category, String date, String user, String description, String snapshot
});




}
/// @nodoc
class _$ApprovalHistoryCopyWithImpl<$Res>
    implements $ApprovalHistoryCopyWith<$Res> {
  _$ApprovalHistoryCopyWithImpl(this._self, this._then);

  final ApprovalHistory _self;
  final $Res Function(ApprovalHistory) _then;

/// Create a copy of ApprovalHistory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? category = null,Object? date = null,Object? user = null,Object? description = null,Object? snapshot = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ApprovalHistory].
extension ApprovalHistoryPatterns on ApprovalHistory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApprovalHistory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApprovalHistory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApprovalHistory value)  $default,){
final _that = this;
switch (_that) {
case _ApprovalHistory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApprovalHistory value)?  $default,){
final _that = this;
switch (_that) {
case _ApprovalHistory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String category,  String date,  String user,  String description,  String snapshot)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApprovalHistory() when $default != null:
return $default(_that.id,_that.category,_that.date,_that.user,_that.description,_that.snapshot);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String category,  String date,  String user,  String description,  String snapshot)  $default,) {final _that = this;
switch (_that) {
case _ApprovalHistory():
return $default(_that.id,_that.category,_that.date,_that.user,_that.description,_that.snapshot);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String category,  String date,  String user,  String description,  String snapshot)?  $default,) {final _that = this;
switch (_that) {
case _ApprovalHistory() when $default != null:
return $default(_that.id,_that.category,_that.date,_that.user,_that.description,_that.snapshot);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApprovalHistory implements ApprovalHistory {
  const _ApprovalHistory({required this.id, required this.category, required this.date, required this.user, required this.description, this.snapshot = ''});
  factory _ApprovalHistory.fromJson(Map<String, dynamic> json) => _$ApprovalHistoryFromJson(json);

@override final  String id;
@override final  String category;
@override final  String date;
@override final  String user;
@override final  String description;
@override@JsonKey() final  String snapshot;

/// Create a copy of ApprovalHistory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApprovalHistoryCopyWith<_ApprovalHistory> get copyWith => __$ApprovalHistoryCopyWithImpl<_ApprovalHistory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApprovalHistoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApprovalHistory&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.date, date) || other.date == date)&&(identical(other.user, user) || other.user == user)&&(identical(other.description, description) || other.description == description)&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,category,date,user,description,snapshot);

@override
String toString() {
  return 'ApprovalHistory(id: $id, category: $category, date: $date, user: $user, description: $description, snapshot: $snapshot)';
}


}

/// @nodoc
abstract mixin class _$ApprovalHistoryCopyWith<$Res> implements $ApprovalHistoryCopyWith<$Res> {
  factory _$ApprovalHistoryCopyWith(_ApprovalHistory value, $Res Function(_ApprovalHistory) _then) = __$ApprovalHistoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String category, String date, String user, String description, String snapshot
});




}
/// @nodoc
class __$ApprovalHistoryCopyWithImpl<$Res>
    implements _$ApprovalHistoryCopyWith<$Res> {
  __$ApprovalHistoryCopyWithImpl(this._self, this._then);

  final _ApprovalHistory _self;
  final $Res Function(_ApprovalHistory) _then;

/// Create a copy of ApprovalHistory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? category = null,Object? date = null,Object? user = null,Object? description = null,Object? snapshot = null,}) {
  return _then(_ApprovalHistory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
