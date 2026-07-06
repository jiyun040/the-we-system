part of 'approval_form.dart';

T _$identity<T>(T value) => value;

mixin _$ApprovalForm {
  String get id;

  String get name;

  String get description;

  int get recentCount;

  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ApprovalFormCopyWith<ApprovalForm> get copyWith =>
      _$ApprovalFormCopyWithImpl<ApprovalForm>(
        this as ApprovalForm,
        _$identity,
      );

  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ApprovalForm &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.recentCount, recentCount) ||
                other.recentCount == recentCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, description, recentCount);

  @override
  String toString() {
    return 'ApprovalForm(id: $id, name: $name, description: $description, recentCount: $recentCount)';
  }
}

abstract mixin class $ApprovalFormCopyWith<$Res> {
  factory $ApprovalFormCopyWith(
    ApprovalForm value,
    $Res Function(ApprovalForm) _then,
  ) = _$ApprovalFormCopyWithImpl;

  @useResult
  $Res call({String id, String name, String description, int recentCount});
}

class _$ApprovalFormCopyWithImpl<$Res> implements $ApprovalFormCopyWith<$Res> {
  _$ApprovalFormCopyWithImpl(this._self, this._then);

  final ApprovalForm _self;
  final $Res Function(ApprovalForm) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? recentCount = null,
  }) {
    return _then(
      _self.copyWith(
        id: null == id ? _self.id : id as String,
        name: null == name ? _self.name : name as String,
        description: null == description
            ? _self.description
            : description as String,
        recentCount: null == recentCount
            ? _self.recentCount
            : recentCount as int,
      ),
    );
  }
}

extension ApprovalFormPatterns on ApprovalForm {
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ApprovalForm value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ApprovalForm() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ApprovalForm value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ApprovalForm():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ApprovalForm value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ApprovalForm() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      String id,
      String name,
      String description,
      int recentCount,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ApprovalForm() when $default != null:
        return $default(
          _that.id,
          _that.name,
          _that.description,
          _that.recentCount,
        );
      case _:
        return orElse();
    }
  }

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      String id,
      String name,
      String description,
      int recentCount,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ApprovalForm():
        return $default(
          _that.id,
          _that.name,
          _that.description,
          _that.recentCount,
        );
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      String id,
      String name,
      String description,
      int recentCount,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ApprovalForm() when $default != null:
        return $default(
          _that.id,
          _that.name,
          _that.description,
          _that.recentCount,
        );
      case _:
        return null;
    }
  }
}

@JsonSerializable()
class _ApprovalForm implements ApprovalForm {
  const _ApprovalForm({
    required this.id,
    required this.name,
    required this.description,
    required this.recentCount,
  });

  factory _ApprovalForm.fromJson(Map<String, dynamic> json) =>
      _$ApprovalFormFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final int recentCount;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ApprovalFormCopyWith<_ApprovalForm> get copyWith =>
      __$ApprovalFormCopyWithImpl<_ApprovalForm>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ApprovalFormToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ApprovalForm &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.recentCount, recentCount) ||
                other.recentCount == recentCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, description, recentCount);

  @override
  String toString() {
    return 'ApprovalForm(id: $id, name: $name, description: $description, recentCount: $recentCount)';
  }
}

abstract mixin class _$ApprovalFormCopyWith<$Res>
    implements $ApprovalFormCopyWith<$Res> {
  factory _$ApprovalFormCopyWith(
    _ApprovalForm value,
    $Res Function(_ApprovalForm) _then,
  ) = __$ApprovalFormCopyWithImpl;

  @override
  @useResult
  $Res call({String id, String name, String description, int recentCount});
}

class __$ApprovalFormCopyWithImpl<$Res>
    implements _$ApprovalFormCopyWith<$Res> {
  __$ApprovalFormCopyWithImpl(this._self, this._then);

  final _ApprovalForm _self;
  final $Res Function(_ApprovalForm) _then;

  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? recentCount = null,
  }) {
    return _then(
      _ApprovalForm(
        id: null == id ? _self.id : id as String,
        name: null == name ? _self.name : name as String,
        description: null == description
            ? _self.description
            : description as String,
        recentCount: null == recentCount
            ? _self.recentCount
            : recentCount as int,
      ),
    );
  }
}
