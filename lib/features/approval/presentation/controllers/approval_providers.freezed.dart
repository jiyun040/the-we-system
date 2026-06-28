part of 'approval_providers.dart';

T _$identity<T>(T value) => value;
mixin _$ApprovalDashboardState {
  ApprovalDashboard get dashboard;
  String get keyword;
  bool get approving;

  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ApprovalDashboardStateCopyWith<ApprovalDashboardState> get copyWith =>
      _$ApprovalDashboardStateCopyWithImpl<ApprovalDashboardState>(
        this as ApprovalDashboardState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ApprovalDashboardState &&
            (identical(other.dashboard, dashboard) ||
                other.dashboard == dashboard) &&
            (identical(other.keyword, keyword) || other.keyword == keyword) &&
            (identical(other.approving, approving) ||
                other.approving == approving));
  }

  @override
  int get hashCode => Object.hash(runtimeType, dashboard, keyword, approving);

  @override
  String toString() {
    return 'ApprovalDashboardState(dashboard: $dashboard, keyword: $keyword, approving: $approving)';
  }
}

abstract mixin class $ApprovalDashboardStateCopyWith<$Res> {
  factory $ApprovalDashboardStateCopyWith(
    ApprovalDashboardState value,
    $Res Function(ApprovalDashboardState) _then,
  ) = _$ApprovalDashboardStateCopyWithImpl;

  @useResult
  $Res call({ApprovalDashboard dashboard, String keyword, bool approving});

  $ApprovalDashboardCopyWith<$Res> get dashboard;
}

class _$ApprovalDashboardStateCopyWithImpl<$Res>
    implements $ApprovalDashboardStateCopyWith<$Res> {
  _$ApprovalDashboardStateCopyWithImpl(this._self, this._then);

  final ApprovalDashboardState _self;
  final $Res Function(ApprovalDashboardState) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dashboard = null,
    Object? keyword = null,
    Object? approving = null,
  }) {
    return _then(
      _self.copyWith(
        dashboard: null == dashboard
            ? _self.dashboard
            : dashboard as ApprovalDashboard,
        keyword: null == keyword ? _self.keyword : keyword as String,
        approving: null == approving ? _self.approving : approving as bool,
      ),
    );
  }

  @override
  @pragma('vm:prefer-inline')
  $ApprovalDashboardCopyWith<$Res> get dashboard {
    return $ApprovalDashboardCopyWith<$Res>(_self.dashboard, (value) {
      return _then(_self.copyWith(dashboard: value));
    });
  }
}

extension ApprovalDashboardStatePatterns on ApprovalDashboardState {
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ApprovalDashboardState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ApprovalDashboardState() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ApprovalDashboardState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ApprovalDashboardState():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ApprovalDashboardState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ApprovalDashboardState() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      ApprovalDashboard dashboard,
      String keyword,
      bool approving,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ApprovalDashboardState() when $default != null:
        return $default(_that.dashboard, _that.keyword, _that.approving);
      case _:
        return orElse();
    }
  }

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      ApprovalDashboard dashboard,
      String keyword,
      bool approving,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ApprovalDashboardState():
        return $default(_that.dashboard, _that.keyword, _that.approving);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      ApprovalDashboard dashboard,
      String keyword,
      bool approving,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ApprovalDashboardState() when $default != null:
        return $default(_that.dashboard, _that.keyword, _that.approving);
      case _:
        return null;
    }
  }
}

class _ApprovalDashboardState implements ApprovalDashboardState {
  const _ApprovalDashboardState({
    required this.dashboard,
    this.keyword = '',
    this.approving = false,
  });

  @override
  final ApprovalDashboard dashboard;
  @override
  @JsonKey()
  final String keyword;
  @override
  @JsonKey()
  final bool approving;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ApprovalDashboardStateCopyWith<_ApprovalDashboardState> get copyWith =>
      __$ApprovalDashboardStateCopyWithImpl<_ApprovalDashboardState>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ApprovalDashboardState &&
            (identical(other.dashboard, dashboard) ||
                other.dashboard == dashboard) &&
            (identical(other.keyword, keyword) || other.keyword == keyword) &&
            (identical(other.approving, approving) ||
                other.approving == approving));
  }

  @override
  int get hashCode => Object.hash(runtimeType, dashboard, keyword, approving);

  @override
  String toString() {
    return 'ApprovalDashboardState(dashboard: $dashboard, keyword: $keyword, approving: $approving)';
  }
}

abstract mixin class _$ApprovalDashboardStateCopyWith<$Res>
    implements $ApprovalDashboardStateCopyWith<$Res> {
  factory _$ApprovalDashboardStateCopyWith(
    _ApprovalDashboardState value,
    $Res Function(_ApprovalDashboardState) _then,
  ) = __$ApprovalDashboardStateCopyWithImpl;

  @override
  @useResult
  $Res call({ApprovalDashboard dashboard, String keyword, bool approving});

  @override
  $ApprovalDashboardCopyWith<$Res> get dashboard;
}

class __$ApprovalDashboardStateCopyWithImpl<$Res>
    implements _$ApprovalDashboardStateCopyWith<$Res> {
  __$ApprovalDashboardStateCopyWithImpl(this._self, this._then);

  final _ApprovalDashboardState _self;
  final $Res Function(_ApprovalDashboardState) _then;

  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? dashboard = null,
    Object? keyword = null,
    Object? approving = null,
  }) {
    return _then(
      _ApprovalDashboardState(
        dashboard: null == dashboard
            ? _self.dashboard
            : dashboard as ApprovalDashboard,
        keyword: null == keyword ? _self.keyword : keyword as String,
        approving: null == approving ? _self.approving : approving as bool,
      ),
    );
  }

  @override
  @pragma('vm:prefer-inline')
  $ApprovalDashboardCopyWith<$Res> get dashboard {
    return $ApprovalDashboardCopyWith<$Res>(_self.dashboard, (value) {
      return _then(_self.copyWith(dashboard: value));
    });
  }
}
