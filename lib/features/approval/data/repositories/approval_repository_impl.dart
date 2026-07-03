import 'package:the_we_system/features/approval/data/datasources/approval_remote_data_source.dart';
import 'package:the_we_system/features/approval/domain/entities/dashboard/approval_dashboard.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';
import 'package:the_we_system/features/approval/domain/repositories/approval_repository.dart';

class ApprovalRepositoryImpl implements ApprovalRepository {
  ApprovalRepositoryImpl(this._remoteDataSource);

  final ApprovalRemoteDataSource _remoteDataSource;

  @override
  Future<ApprovalDashboard> fetchDashboard() {
    return _remoteDataSource.fetchDashboard();
  }

  @override
  Future<ApprovalDocument> fetchDocument(String id) {
    return _remoteDataSource.fetchDocument(id);
  }

  @override
  Future<void> approveDocument(String id) {
    return _remoteDataSource.approveDocument(id);
  }
}
