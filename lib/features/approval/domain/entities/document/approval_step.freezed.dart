part of 'approval_step.dart';

T _$identity<T>(T value) => value;

mixin _$ApprovalStep {
  String get name;
  String get department;
  String get type;
  String get role;
  String get status;
  String? get approvedAt;
  String? get delegatedBy;

  bool get requiresOriginalApproval;

  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ApprovalStepCopyWith<ApprovalStep> get copyWith =>
      _$ApprovalStepCopyWithImpl<ApprovalStep>(
        this as ApprovalStep,
        _$identity,
      );

  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ApprovalStep &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.department, department) ||
                other.department == department) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.approvedAt, approvedAt) ||
                other.approvedAt == approvedAt) &&
            (identical(other.delegatedBy, delegatedBy) ||
                other.delegatedBy == delegatedBy) &&
            (identical(
                  other.requiresOriginalApproval,
                  requiresOriginalApproval,
                ) ||
                other.requiresOriginalApproval == requiresOriginalApproval));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    department,
    type,
    role,
    status,
    approvedAt,
    delegatedBy,
    requiresOriginalApproval,
  );

  @override
  String toString() {
    return 'ApprovalStep(name: $name, department: $department, type: $type, role: $role, status: $status, approvedAt: $approvedAt, delegatedBy: $delegatedBy, requiresOriginalApproval: $requiresOriginalApproval)';
  }
}

abstract mixin class $ApprovalStepCopyWith<$Res> {
  factory $ApprovalStepCopyWith(
    ApprovalStep value,
    $Res Function(ApprovalStep) _then,
  ) = _$ApprovalStepCopyWithImpl;

  @useResult
  $Res call({
    String name,
    String department,
    String type,
    String role,
    String status,
    String? approvedAt,
    String? delegatedBy,
    bool requiresOriginalApproval,
  });
}

class _$ApprovalStepCopyWithImpl<$Res> implements $ApprovalStepCopyWith<$Res> {
  _$ApprovalStepCopyWithImpl(this._self, this._then);

  final ApprovalStep _self;
  final $Res Function(ApprovalStep) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? department = null,
    Object? type = null,
    Object? role = null,
    Object? status = null,
    Object? approvedAt = freezed,
    Object? delegatedBy = freezed,
    Object? requiresOriginalApproval = null,
  }) {
    return _then(
      _self.copyWith(
        name: null == name ? _self.name : name as String,
        department: null == department
            ? _self.department
            : department as String,
        type: null == type ? _self.type : type as String,
        role: null == role ? _self.role : role as String,
        status: null == status ? _self.status : status as String,
        approvedAt: freezed == approvedAt
            ? _self.approvedAt
            : approvedAt as String?,
        delegatedBy: freezed == delegatedBy
            ? _self.delegatedBy
            : delegatedBy as String?,
        requiresOriginalApproval: null == requiresOriginalApproval
            ? _self.requiresOriginalApproval
            : requiresOriginalApproval as bool,
      ),
    );
  }
}

extension ApprovalStepPatterns on ApprovalStep {
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ApprovalStep value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ApprovalStep() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ApprovalStep value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ApprovalStep():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ApprovalStep value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ApprovalStep() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      String name,
      String department,
      String type,
      String role,
      String status,
      String? approvedAt,
      String? delegatedBy,
      bool requiresOriginalApproval,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ApprovalStep() when $default != null:
        return $default(
          _that.name,
          _that.department,
          _that.type,
          _that.role,
          _that.status,
          _that.approvedAt,
          _that.delegatedBy,
          _that.requiresOriginalApproval,
        );
      case _:
        return orElse();
    }
  }

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      String name,
      String department,
      String type,
      String role,
      String status,
      String? approvedAt,
      String? delegatedBy,
      bool requiresOriginalApproval,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ApprovalStep():
        return $default(
          _that.name,
          _that.department,
          _that.type,
          _that.role,
          _that.status,
          _that.approvedAt,
          _that.delegatedBy,
          _that.requiresOriginalApproval,
        );
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      String name,
      String department,
      String type,
      String role,
      String status,
      String? approvedAt,
      String? delegatedBy,
      bool requiresOriginalApproval,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ApprovalStep() when $default != null:
        return $default(
          _that.name,
          _that.department,
          _that.type,
          _that.role,
          _that.status,
          _that.approvedAt,
          _that.delegatedBy,
          _that.requiresOriginalApproval,
        );
      case _:
        return null;
    }
  }
}

@JsonSerializable()
class _ApprovalStep implements ApprovalStep {
  const _ApprovalStep({
    required this.name,
    required this.department,
    this.type = '결재',
    this.role = '',
    required this.status,
    this.approvedAt,
    this.delegatedBy,
    this.requiresOriginalApproval = false,
  });

  factory _ApprovalStep.fromJson(Map<String, dynamic> json) =>
      _$ApprovalStepFromJson(json);

  @override
  final String name;
  @override
  final String department;
  @override
  @JsonKey()
  final String type;
  @override
  @JsonKey()
  final String role;
  @override
  final String status;
  @override
  final String? approvedAt;
  @override
  final String? delegatedBy;
  @override
  @JsonKey()
  final bool requiresOriginalApproval;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ApprovalStepCopyWith<_ApprovalStep> get copyWith =>
      __$ApprovalStepCopyWithImpl<_ApprovalStep>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ApprovalStepToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ApprovalStep &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.department, department) ||
                other.department == department) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.approvedAt, approvedAt) ||
                other.approvedAt == approvedAt) &&
            (identical(other.delegatedBy, delegatedBy) ||
                other.delegatedBy == delegatedBy) &&
            (identical(
                  other.requiresOriginalApproval,
                  requiresOriginalApproval,
                ) ||
                other.requiresOriginalApproval == requiresOriginalApproval));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    department,
    type,
    role,
    status,
    approvedAt,
    delegatedBy,
    requiresOriginalApproval,
  );

  @override
  String toString() {
    return 'ApprovalStep(name: $name, department: $department, type: $type, role: $role, status: $status, approvedAt: $approvedAt, delegatedBy: $delegatedBy, requiresOriginalApproval: $requiresOriginalApproval)';
  }
}

abstract mixin class _$ApprovalStepCopyWith<$Res>
    implements $ApprovalStepCopyWith<$Res> {
  factory _$ApprovalStepCopyWith(
    _ApprovalStep value,
    $Res Function(_ApprovalStep) _then,
  ) = __$ApprovalStepCopyWithImpl;

  @override
  @useResult
  $Res call({
    String name,
    String department,
    String type,
    String role,
    String status,
    String? approvedAt,
    String? delegatedBy,
    bool requiresOriginalApproval,
  });
}

class __$ApprovalStepCopyWithImpl<$Res>
    implements _$ApprovalStepCopyWith<$Res> {
  __$ApprovalStepCopyWithImpl(this._self, this._then);

  final _ApprovalStep _self;
  final $Res Function(_ApprovalStep) _then;

  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? department = null,
    Object? type = null,
    Object? role = null,
    Object? status = null,
    Object? approvedAt = freezed,
    Object? delegatedBy = freezed,
    Object? requiresOriginalApproval = null,
  }) {
    return _then(
      _ApprovalStep(
        name: null == name ? _self.name : name as String,
        department: null == department
            ? _self.department
            : department as String,
        type: null == type ? _self.type : type as String,
        role: null == role ? _self.role : role as String,
        status: null == status ? _self.status : status as String,
        approvedAt: freezed == approvedAt
            ? _self.approvedAt
            : approvedAt as String?,
        delegatedBy: freezed == delegatedBy
            ? _self.delegatedBy
            : delegatedBy as String?,
        requiresOriginalApproval: null == requiresOriginalApproval
            ? _self.requiresOriginalApproval
            : requiresOriginalApproval as bool,
      ),
    );
  }
}
