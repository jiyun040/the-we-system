import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:the_we_system/core/network/dio_provider.dart';
import 'package:the_we_system/features/approval/data/datasources/approval_remote_data_source.dart';
import 'package:the_we_system/features/approval/data/repositories/approval_repository_impl.dart';
import 'package:the_we_system/features/approval/domain/entities/approval_dashboard.dart';
import 'package:the_we_system/features/approval/domain/entities/approval_document.dart';
import 'package:the_we_system/features/approval/domain/repositories/approval_repository.dart';

part 'approval_providers.freezed.dart';

final approvalRemoteDataSourceProvider = Provider<ApprovalRemoteDataSource>((
  ref,
) {
  return ApprovalRemoteDataSource(ref.watch(dioProvider));
});

final approvalRepositoryProvider = Provider<ApprovalRepository>((ref) {
  return ApprovalRepositoryImpl(ref.watch(approvalRemoteDataSourceProvider));
});

final approvalDashboardControllerProvider =
    AsyncNotifierProvider<ApprovalDashboardController, ApprovalDashboardState>(
      ApprovalDashboardController.new,
    );

final approvalDocumentProvider =
    FutureProvider.family<ApprovalDocument, String>((ref, id) {
      return ref.watch(approvalRepositoryProvider).fetchDocument(id);
    });

@freezed
abstract class ApprovalDashboardState with _$ApprovalDashboardState {
  const factory ApprovalDashboardState({
    required ApprovalDashboard dashboard,
    @Default('') String keyword,
    @Default(false) bool approving,
  }) = _ApprovalDashboardState;
}

class ApprovalDashboardController
    extends AsyncNotifier<ApprovalDashboardState> {
  @override
  Future<ApprovalDashboardState> build() async {
    final dashboard = await ref
        .watch(approvalRepositoryProvider)
        .fetchDashboard();
    return ApprovalDashboardState(dashboard: dashboard);
  }

  void updateKeyword(String keyword) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    state = AsyncData(current.copyWith(keyword: keyword));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dashboard = await ref
          .read(approvalRepositoryProvider)
          .fetchDashboard();
      return ApprovalDashboardState(dashboard: dashboard);
    });
  }

  Future<void> approve(String id) async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    state = AsyncData(current.copyWith(approving: true));
    await ref.read(approvalRepositoryProvider).approveDocument(id);
    final dashboard = await ref
        .read(approvalRepositoryProvider)
        .fetchDashboard();
    state = AsyncData(
      ApprovalDashboardState(
        dashboard: dashboard,
        keyword: current.keyword,
        approving: false,
      ),
    );
  }
}
