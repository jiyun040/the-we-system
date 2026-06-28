part of 'approval_dashboard.dart';

T _$identity<T>(T value) => value;

mixin _$ApprovalDashboard {
  int get pendingCount;
  int get receivedCount;
  int get referenceCount;
  int get scheduledCount;

  List<ApprovalForm> get frequentForms;
  List<ApprovalDocument> get processingDocuments;
  List<ApprovalDocument> get waitingDocuments;

  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ApprovalDashboardCopyWith<ApprovalDashboard> get copyWith =>
      _$ApprovalDashboardCopyWithImpl<ApprovalDashboard>(
        this as ApprovalDashboard,
        _$identity,
      );

  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ApprovalDashboard &&
            (identical(other.pendingCount, pendingCount) ||
                other.pendingCount == pendingCount) &&
            (identical(other.receivedCount, receivedCount) ||
                other.receivedCount == receivedCount) &&
            (identical(other.referenceCount, referenceCount) ||
                other.referenceCount == referenceCount) &&
            (identical(other.scheduledCount, scheduledCount) ||
                other.scheduledCount == scheduledCount) &&
            const DeepCollectionEquality().equals(
              other.frequentForms,
              frequentForms,
            ) &&
            const DeepCollectionEquality().equals(
              other.processingDocuments,
              processingDocuments,
            ) &&
            const DeepCollectionEquality().equals(
              other.waitingDocuments,
              waitingDocuments,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    pendingCount,
    receivedCount,
    referenceCount,
    scheduledCount,
    const DeepCollectionEquality().hash(frequentForms),
    const DeepCollectionEquality().hash(processingDocuments),
    const DeepCollectionEquality().hash(waitingDocuments),
  );

  @override
  String toString() {
    return 'ApprovalDashboard(pendingCount: $pendingCount, receivedCount: $receivedCount, referenceCount: $referenceCount, scheduledCount: $scheduledCount, frequentForms: $frequentForms, processingDocuments: $processingDocuments, waitingDocuments: $waitingDocuments)';
  }
}

abstract mixin class $ApprovalDashboardCopyWith<$Res> {
  factory $ApprovalDashboardCopyWith(
    ApprovalDashboard value,
    $Res Function(ApprovalDashboard) _then,
  ) = _$ApprovalDashboardCopyWithImpl;

  @useResult
  $Res call({
    int pendingCount,
    int receivedCount,
    int referenceCount,
    int scheduledCount,
    List<ApprovalForm> frequentForms,
    List<ApprovalDocument> processingDocuments,
    List<ApprovalDocument> waitingDocuments,
  });
}

class _$ApprovalDashboardCopyWithImpl<$Res>
    implements $ApprovalDashboardCopyWith<$Res> {
  _$ApprovalDashboardCopyWithImpl(this._self, this._then);

  final ApprovalDashboard _self;
  final $Res Function(ApprovalDashboard) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pendingCount = null,
    Object? receivedCount = null,
    Object? referenceCount = null,
    Object? scheduledCount = null,
    Object? frequentForms = null,
    Object? processingDocuments = null,
    Object? waitingDocuments = null,
  }) {
    return _then(
      _self.copyWith(
        pendingCount: null == pendingCount
            ? _self.pendingCount
            : pendingCount as int,
        receivedCount: null == receivedCount
            ? _self.receivedCount
            : receivedCount as int,
        referenceCount: null == referenceCount
            ? _self.referenceCount
            : referenceCount as int,
        scheduledCount: null == scheduledCount
            ? _self.scheduledCount
            : scheduledCount as int,
        frequentForms: null == frequentForms
            ? _self.frequentForms
            : frequentForms as List<ApprovalForm>,
        processingDocuments: null == processingDocuments
            ? _self.processingDocuments
            : processingDocuments as List<ApprovalDocument>,
        waitingDocuments: null == waitingDocuments
            ? _self.waitingDocuments
            : waitingDocuments as List<ApprovalDocument>,
      ),
    );
  }
}

extension ApprovalDashboardPatterns on ApprovalDashboard {
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ApprovalDashboard value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ApprovalDashboard() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ApprovalDashboard value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ApprovalDashboard():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ApprovalDashboard value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ApprovalDashboard() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      int pendingCount,
      int receivedCount,
      int referenceCount,
      int scheduledCount,
      List<ApprovalForm> frequentForms,
      List<ApprovalDocument> processingDocuments,
      List<ApprovalDocument> waitingDocuments,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ApprovalDashboard() when $default != null:
        return $default(
          _that.pendingCount,
          _that.receivedCount,
          _that.referenceCount,
          _that.scheduledCount,
          _that.frequentForms,
          _that.processingDocuments,
          _that.waitingDocuments,
        );
      case _:
        return orElse();
    }
  }

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      int pendingCount,
      int receivedCount,
      int referenceCount,
      int scheduledCount,
      List<ApprovalForm> frequentForms,
      List<ApprovalDocument> processingDocuments,
      List<ApprovalDocument> waitingDocuments,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ApprovalDashboard():
        return $default(
          _that.pendingCount,
          _that.receivedCount,
          _that.referenceCount,
          _that.scheduledCount,
          _that.frequentForms,
          _that.processingDocuments,
          _that.waitingDocuments,
        );
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      int pendingCount,
      int receivedCount,
      int referenceCount,
      int scheduledCount,
      List<ApprovalForm> frequentForms,
      List<ApprovalDocument> processingDocuments,
      List<ApprovalDocument> waitingDocuments,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ApprovalDashboard() when $default != null:
        return $default(
          _that.pendingCount,
          _that.receivedCount,
          _that.referenceCount,
          _that.scheduledCount,
          _that.frequentForms,
          _that.processingDocuments,
          _that.waitingDocuments,
        );
      case _:
        return null;
    }
  }
}

@JsonSerializable()
class _ApprovalDashboard implements ApprovalDashboard {
  const _ApprovalDashboard({
    required this.pendingCount,
    required this.receivedCount,
    required this.referenceCount,
    required this.scheduledCount,
    final List<ApprovalForm> frequentForms = const <ApprovalForm>[],
    final List<ApprovalDocument> processingDocuments =
        const <ApprovalDocument>[],
    final List<ApprovalDocument> waitingDocuments = const <ApprovalDocument>[],
  }) : _frequentForms = frequentForms,
       _processingDocuments = processingDocuments,
       _waitingDocuments = waitingDocuments;

  factory _ApprovalDashboard.fromJson(Map<String, dynamic> json) =>
      _$ApprovalDashboardFromJson(json);

  @override
  final int pendingCount;
  @override
  final int receivedCount;
  @override
  final int referenceCount;
  @override
  final int scheduledCount;
  final List<ApprovalForm> _frequentForms;

  @override
  @JsonKey()
  List<ApprovalForm> get frequentForms {
    if (_frequentForms is EqualUnmodifiableListView) return _frequentForms;
    return EqualUnmodifiableListView(_frequentForms);
  }

  final List<ApprovalDocument> _processingDocuments;

  @override
  @JsonKey()
  List<ApprovalDocument> get processingDocuments {
    if (_processingDocuments is EqualUnmodifiableListView)
      return _processingDocuments;
    return EqualUnmodifiableListView(_processingDocuments);
  }

  final List<ApprovalDocument> _waitingDocuments;

  @override
  @JsonKey()
  List<ApprovalDocument> get waitingDocuments {
    if (_waitingDocuments is EqualUnmodifiableListView)
      return _waitingDocuments;
    return EqualUnmodifiableListView(_waitingDocuments);
  }

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ApprovalDashboardCopyWith<_ApprovalDashboard> get copyWith =>
      __$ApprovalDashboardCopyWithImpl<_ApprovalDashboard>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ApprovalDashboardToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ApprovalDashboard &&
            (identical(other.pendingCount, pendingCount) ||
                other.pendingCount == pendingCount) &&
            (identical(other.receivedCount, receivedCount) ||
                other.receivedCount == receivedCount) &&
            (identical(other.referenceCount, referenceCount) ||
                other.referenceCount == referenceCount) &&
            (identical(other.scheduledCount, scheduledCount) ||
                other.scheduledCount == scheduledCount) &&
            const DeepCollectionEquality().equals(
              other._frequentForms,
              _frequentForms,
            ) &&
            const DeepCollectionEquality().equals(
              other._processingDocuments,
              _processingDocuments,
            ) &&
            const DeepCollectionEquality().equals(
              other._waitingDocuments,
              _waitingDocuments,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    pendingCount,
    receivedCount,
    referenceCount,
    scheduledCount,
    const DeepCollectionEquality().hash(_frequentForms),
    const DeepCollectionEquality().hash(_processingDocuments),
    const DeepCollectionEquality().hash(_waitingDocuments),
  );

  @override
  String toString() {
    return 'ApprovalDashboard(pendingCount: $pendingCount, receivedCount: $receivedCount, referenceCount: $referenceCount, scheduledCount: $scheduledCount, frequentForms: $frequentForms, processingDocuments: $processingDocuments, waitingDocuments: $waitingDocuments)';
  }
}

abstract mixin class _$ApprovalDashboardCopyWith<$Res>
    implements $ApprovalDashboardCopyWith<$Res> {
  factory _$ApprovalDashboardCopyWith(
    _ApprovalDashboard value,
    $Res Function(_ApprovalDashboard) _then,
  ) = __$ApprovalDashboardCopyWithImpl;

  @override
  @useResult
  $Res call({
    int pendingCount,
    int receivedCount,
    int referenceCount,
    int scheduledCount,
    List<ApprovalForm> frequentForms,
    List<ApprovalDocument> processingDocuments,
    List<ApprovalDocument> waitingDocuments,
  });
}

class __$ApprovalDashboardCopyWithImpl<$Res>
    implements _$ApprovalDashboardCopyWith<$Res> {
  __$ApprovalDashboardCopyWithImpl(this._self, this._then);

  final _ApprovalDashboard _self;
  final $Res Function(_ApprovalDashboard) _then;

  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? pendingCount = null,
    Object? receivedCount = null,
    Object? referenceCount = null,
    Object? scheduledCount = null,
    Object? frequentForms = null,
    Object? processingDocuments = null,
    Object? waitingDocuments = null,
  }) {
    return _then(
      _ApprovalDashboard(
        pendingCount: null == pendingCount
            ? _self.pendingCount
            : pendingCount as int,
        receivedCount: null == receivedCount
            ? _self.receivedCount
            : receivedCount as int,
        referenceCount: null == referenceCount
            ? _self.referenceCount
            : referenceCount as int,
        scheduledCount: null == scheduledCount
            ? _self.scheduledCount
            : scheduledCount as int,
        frequentForms: null == frequentForms
            ? _self._frequentForms
            : frequentForms as List<ApprovalForm>,
        processingDocuments: null == processingDocuments
            ? _self._processingDocuments
            : processingDocuments as List<ApprovalDocument>,
        waitingDocuments: null == waitingDocuments
            ? _self._waitingDocuments
            : waitingDocuments as List<ApprovalDocument>,
      ),
    );
  }
}
