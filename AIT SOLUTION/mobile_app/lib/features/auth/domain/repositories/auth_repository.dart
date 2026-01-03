import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/user_model.dart';

abstract class AuthRepository {
  Future<Either<Failure, TokenModel>> login(String email, String password);
  Future<Either<Failure, TokenModel>> register(String email, String password, String role, {String? firstName, String? lastName, String? phone, String? passportNumber, String? nationality});
  Future<void> logout();
  Future<Either<Failure, UserModel>> getCurrentUser();
}
