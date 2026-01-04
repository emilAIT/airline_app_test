import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/airplane.dart';
import '../../domain/repositories/airplane_repository.dart';
import '../models/airplane_model.dart';

@Injectable(as: AirplaneRepository)
class AirplaneRepositoryImpl implements AirplaneRepository {
  final ApiClient _apiClient;

  AirplaneRepositoryImpl(this._apiClient);

  @override
  Future<Either<Failure, List<Airplane>>> getAirplanes() async {
    try {
      final response = await _apiClient.dio.get('/airplanes/');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final airplanes = data.map((json) => AirplaneModel.fromJson(json)).toList();
        return Right(airplanes);
      } else {
        return Left(ServerFailure('Failed to fetch airplanes'));
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Airplane>> addAirplane(Airplane airplane) async {
    try {
      // Calculate rows_count based on total_seats if needed
      final seatsPerRow = 6;
      final rowsCount = (airplane.totalSeats + seatsPerRow - 1) ~/ seatsPerRow;
      
      final response = await _apiClient.dio.post(
        '/airplanes/',
        data: {
            'model': airplane.model,
            'registration': airplane.registration,
            'manufacturer': airplane.manufacturer,
            'total_seats': airplane.totalSeats,
            'economy_seats': airplane.economySeats,
            'business_seats': airplane.businessSeats,
            'first_class_seats': 0,
            'rows_count': rowsCount, 
            'seats_per_row': seatsPerRow,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = response.data;
          if (responseData is Map<String, dynamic>) {
            final newAirplane = AirplaneModel.fromJson(responseData);
            return Right(newAirplane);
          } else {
            // If response is not a map, airplane was still created
            // Return success with original airplane (list will refresh)
            return Right(airplane);
          }
        } catch (e) {
          // Parsing failed but request was successful - airplane was created
          // Return success with original airplane (list will refresh to show new airplane)
          return Right(airplane);
        }
      } else {
        return Left(ServerFailure('Server returned status ${response.statusCode}'));
      }
    } on DioException catch (e) {
      // If we got a successful response but DioException was thrown (e.g., parsing error)
      if (e.response != null && (e.response!.statusCode == 200 || e.response!.statusCode == 201)) {
        // Airplane was created successfully, return success
        return Right(airplane);
      }
      return _handleDioError(e);
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAirplane(int id) async {
    try {
      final response = await _apiClient.dio.delete(
        '/airplanes/$id',
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Right(unit);
      } else {
        return Left(ServerFailure('Failed to delete airplane'));
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  Either<Failure, T> _handleDioError<T>(DioException e) {
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
      return Left(ServerFailure('Connection error. Is the server running?'));
    }
    
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    
    // Extract detailed error message from backend
    String message = 'Unknown error';
    
    if (data != null) {
      if (data is Map<String, dynamic>) {
        // Backend returns error in 'detail' field (FastAPI format)
        message = data['detail']?.toString() ?? data.toString();
      } else if (data is String) {
        message = data;
      } else {
        message = data.toString();
      }
    }
    
    // For 400 errors, show the detailed message without prefix
    // This ensures users see the full explanation from backend
    if (statusCode == 400) {
      return Left(ServerFailure(message));
    }
    
    // For other errors, include status code
    return Left(ServerFailure('Error $statusCode: $message'));
  }
}
