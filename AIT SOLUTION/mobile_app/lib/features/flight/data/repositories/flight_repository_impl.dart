import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'package:ait_airlines/core/error/failures.dart';
import 'package:ait_airlines/core/network/api_client.dart';
import 'package:ait_airlines/features/flight/domain/entities/flight.dart';
import 'package:ait_airlines/features/flight/domain/entities/airport.dart';
import 'package:ait_airlines/features/flight/domain/repositories/flight_repository.dart';
import 'package:ait_airlines/features/flight/data/models/flight_model.dart';
import 'package:ait_airlines/features/flight/data/models/airport_model.dart';

@Injectable(as: FlightRepository)
class FlightRepositoryImpl implements FlightRepository {
  final ApiClient _apiClient;

  FlightRepositoryImpl(this._apiClient);

  @override
  Future<Either<Failure, List<Flight>>> getFlights(
      {String? departure,
      String? arrival,
      String? date,
      int? passengersCount}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (departure != null) queryParams['departure'] = departure;
      if (arrival != null) queryParams['arrival'] = arrival;
      if (date != null) queryParams['date'] = date;
      if (passengersCount != null)
        queryParams['passengers_count'] = passengersCount;

      final response = await _apiClient.dio.get(
        '/flights/',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        final List data = response.data;
        return Right(data.map((json) => FlightModel.fromJson(json)).toList());
      }
      return Left(ServerFailure('Failed to fetch flights'));
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data['detail']?.toString() ??
          e.message ??
          'Server error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Flight>> createFlight(
      Map<String, dynamic> flightData) async {
    try {
      final response = await _apiClient.dio.post('/flights/', data: flightData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Right(FlightModel.fromJson(response.data));
      }
      return Left(ServerFailure('Failed to create flight'));
    } on DioException catch (e) {
      final msg = e.response?.data['detail'] ?? 'Flight creation failed';
      return Left(ServerFailure(msg.toString()));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Airport>>> getAirports() async {
    try {
      final response = await _apiClient.dio.get('/airports/');
      if (response.statusCode == 200) {
        final List data = response.data;
        return Right(data.map((json) => AirportModel.fromJson(json)).toList());
      }
      return Left(ServerFailure('Failed to fetch airports'));
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data['detail']?.toString() ??
          e.message ??
          'Server error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Airport>> createAirport(
      Map<String, dynamic> airportData) async {
    try {
      final response =
          await _apiClient.dio.post('/airports/', data: airportData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Right(AirportModel.fromJson(response.data));
      }
      return Left(ServerFailure('Failed to create airport'));
    } on DioException catch (e) {
      final msg = e.response?.data['detail'] ?? 'Airport creation failed';
      return Left(ServerFailure(msg.toString()));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Flight>> updateFlightStatus(
      int flightId, String status) async {
    try {
      final response = await _apiClient.dio.patch(
        '/flights/$flightId/status',
        data: {'status': status},
      );
      if (response.statusCode == 200) {
        return Right(FlightModel.fromJson(response.data));
      }
      return Left(ServerFailure('Failed to update flight status'));
    } on DioException catch (e) {
      // Extract detailed error message from backend
      final data = e.response?.data;
      String message = 'Status update failed';
      
      if (data != null) {
        if (data is Map<String, dynamic>) {
          message = data['detail']?.toString() ?? data.toString();
        } else if (data is String) {
          message = data;
        } else {
          message = data.toString();
        }
      }
      
      // For 400 errors, show the detailed message without prefix
      if (e.response?.statusCode == 400) {
        return Left(ServerFailure(message));
      }
      
      return Left(ServerFailure('Error ${e.response?.statusCode}: $message'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getSeatMap(
      int flightId) async {
    try {
      final response = await _apiClient.dio.get('/flights/$flightId/seats');
      if (response.statusCode == 200) {
        final List data = response.data;
        return Right(data.cast<Map<String, dynamic>>());
      }
      return Left(ServerFailure('Failed to fetch seat map'));
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data['detail']?.toString() ??
          e.message ??
          'Server error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Flight>> updateGates(
      int flightId, String gateDeparture, String gateArrival) async {
    try {
      final response = await _apiClient.dio.patch(
        '/flights/$flightId/gate',
        data: {
          'gate_departure': gateDeparture,
          'gate_arrival': gateArrival,
        },
      );
      if (response.statusCode == 200) {
        return Right(FlightModel.fromJson(response.data));
      }
      return Left(ServerFailure('Failed to update gates'));
    } on DioException catch (e) {
      // Extract detailed error message from backend
      final data = e.response?.data;
      String message = 'Gate update failed';
      
      if (data != null) {
        if (data is Map<String, dynamic>) {
          message = data['detail']?.toString() ?? data.toString();
        } else if (data is String) {
          message = data;
        } else {
          message = data.toString();
        }
      }
      
      // For 400 errors, show the detailed message without prefix
      if (e.response?.statusCode == 400) {
        return Left(ServerFailure(message));
      }
      
      return Left(ServerFailure('Error ${e.response?.statusCode}: $message'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
