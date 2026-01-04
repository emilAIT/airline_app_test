import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:ait_airlines/core/error/failures.dart';
import 'package:ait_airlines/core/network/api_client.dart';
import 'package:ait_airlines/features/auth/data/models/user_model.dart';
import 'package:ait_airlines/features/auth/domain/entities/user.dart';
import 'package:ait_airlines/features/admin/domain/entities/admin_user_summary.dart';
import 'package:ait_airlines/features/admin/data/models/admin_user_summary_model.dart';
import 'package:ait_airlines/features/admin/domain/repositories/admin_repository.dart';

@LazySingleton(as: AdminRepository)
class AdminRepositoryImpl implements AdminRepository {
  final ApiClient _apiClient;

  AdminRepositoryImpl(this._apiClient);

  @override
  Future<Either<Failure, List<User>>> getPendingStaff() async {
    try {
      final response = await _apiClient.dio.get('/staff-management/pending');
      final List<dynamic> data = response.data;
      return Right(data.map((json) => UserModel.fromJson(json)).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> approveStaff(int staffId) async {
    try {
      await _apiClient.dio.post('/staff-management/$staffId/approve');
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> rejectStaff(int staffId) async {
    try {
      await _apiClient.dio.post('/staff-management/$staffId/reject');
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteStaff(int staffId) async {
    try {
      await _apiClient.dio.delete('/staff-management/$staffId');
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AdminUserSummary>>> getUsersSummary() async {
    try {
      final response = await _apiClient.dio.get('/staff-management/summary');
      final List<dynamic> data = response.data;
      return Right(
          data.map((json) => AdminUserSummaryModel.fromJson(json)).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
