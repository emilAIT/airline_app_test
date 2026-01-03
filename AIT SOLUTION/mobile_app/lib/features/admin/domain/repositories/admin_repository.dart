import 'package:dartz/dartz.dart';
import 'package:ait_airlines/core/error/failures.dart';
import 'package:ait_airlines/features/auth/domain/entities/user.dart';
import 'package:ait_airlines/features/admin/domain/entities/admin_user_summary.dart';

abstract class AdminRepository {
  Future<Either<Failure, List<User>>> getPendingStaff();
  Future<Either<Failure, Unit>> approveStaff(int staffId);
  Future<Either<Failure, Unit>> rejectStaff(int staffId);
  Future<Either<Failure, Unit>> deleteStaff(int staffId);
  // Получить сводку всех пользователей/стаффа для админа
  Future<Either<Failure, List<AdminUserSummary>>> getUsersSummary();
}
