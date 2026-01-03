import 'package:dio/dio.dart';
import '../models/flight.dart';
import '../models/booking.dart';
import '../models/aviation.dart';
import '../config/api_config.dart';

class StaffService {
  final Dio _dio;
  final String? token;

  StaffService(this._dio, {this.token});

  Dio get _authenticatedDio {
    if (token != null) {
      final dio = Dio(_dio.options);
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
      ));
      return dio;
    }
    return _dio;
  }

  // ==================== АЭРОПОРТЫ ====================
  
  Future<List<Airport>> getAirports() async {
    try {
      final url = '${ApiConfig.baseUrl}/staff/airports';
      final response = await _authenticatedDio.get(url);
      return (response.data as List)
          .map((json) => Airport.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Airport> createAirport({
    required String code,
    required String name,
    required String city,
    required String country,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/staff/airports';
      final response = await _authenticatedDio.post(url, data: {
        'code': code,
        'name': name,
        'city': city,
        'country': country,
      });
      return Airport.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Airport> updateAirport({
    required String code,
    String? name,
    String? city,
    String? country,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (city != null) data['city'] = city;
      if (country != null) data['country'] = country;

      final url = '${ApiConfig.baseUrl}/staff/airports/$code';
      final response = await _authenticatedDio.put(url, data: data);
      return Airport.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteAirport(String code) async {
    try {
      final url = '${ApiConfig.baseUrl}/staff/airports/$code';
      await _authenticatedDio.delete(url);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== САМОЛЕТЫ ====================
  
  Future<List<Airplane>> getAirplanes() async {
    try {
      final url = '${ApiConfig.baseUrl}/staff/airplanes';
      final response = await _authenticatedDio.get(url);
      return (response.data as List)
          .map((json) => Airplane.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Airplane> createAirplane({
    required String name,
    required String model,
    required int rows,
    required int seatsPerRow,
    required int businessRows,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/staff/airplanes';
      final response = await _authenticatedDio.post(url, data: {
        'name': name,
        'model': model,
        'rows': rows,
        'seats_per_row': seatsPerRow,
        'business_rows': businessRows,
      });
      return Airplane.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Airplane> updateAirplane({
    required int airplaneId,
    String? name,
    String? model,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (model != null) data['model'] = model;

      final url = '${ApiConfig.baseUrl}/staff/airplanes/$airplaneId';
      final response = await _authenticatedDio.put(url, data: data);
      return Airplane.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteAirplane(int airplaneId) async {
    try {
      final url = '${ApiConfig.baseUrl}/staff/airplanes/$airplaneId';
      await _authenticatedDio.delete(url);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Seat>> getAirplaneSeats(int airplaneId) async {
    try {
      final url = '${ApiConfig.baseUrl}/staff/airplanes/$airplaneId/seats';
      final response = await _authenticatedDio.get(url);
      return (response.data as List)
          .map((json) => Seat.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== РЕЙСЫ ====================
  
  Future<List<Flight>> getFlights() async {
    try {
      final url = '${ApiConfig.baseUrl}/staff/flights';
      final response = await _authenticatedDio.get(url);
      return (response.data as List)
          .map((json) => Flight.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Flight> getFlight(int flightId) async {
    try {
      final url = '${ApiConfig.baseUrl}/staff/flights/$flightId';
      final response = await _authenticatedDio.get(url);
      return Flight.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Flight> createFlight({
    required String flightNumber,
    required String departureAirportCode,
    required String arrivalAirportCode,
    required int airplaneId,
    required DateTime departureTime,
    required DateTime arrivalTime,
    required double basePrice,
    String? gate,
    String? terminal,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/staff/flights';
      
      // Convert local time to UTC before sending to backend
      // Admin sets time in local timezone (Kyrgyzstan UTC+6), we need to convert to UTC
      // DateTime() constructor creates local time, toUtc() correctly converts it
      // The issue might be that we need to ensure the DateTime is treated as local
      final departureTimeUtc = departureTime.isUtc 
          ? departureTime 
          : departureTime.toUtc();
      final arrivalTimeUtc = arrivalTime.isUtc 
          ? arrivalTime 
          : arrivalTime.toUtc();
      
      final response = await _authenticatedDio.post(url, data: {
        'flight_number': flightNumber,
        'departure_airport_code': departureAirportCode,
        'arrival_airport_code': arrivalAirportCode,
        'airplane_id': airplaneId,
        'departure_time': departureTimeUtc.toIso8601String(),
        'arrival_time': arrivalTimeUtc.toIso8601String(),
        'base_price': basePrice,
        'gate': gate,
        'terminal': terminal,
      });
      return Flight.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Flight> updateFlight({
    required int flightId,
    String? status,
    String? gate,
    String? terminal,
    DateTime? departureTime,
    DateTime? arrivalTime,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (status != null) data['status'] = status;
      if (gate != null) data['gate'] = gate;
      if (terminal != null) data['terminal'] = terminal;
      if (departureTime != null) {
        // Convert local time to UTC before sending to backend
        final departureTimeUtc = departureTime.isUtc ? departureTime : departureTime.toUtc();
        data['departure_time'] = departureTimeUtc.toIso8601String();
      }
      if (arrivalTime != null) {
        // Convert local time to UTC before sending to backend
        final arrivalTimeUtc = arrivalTime.isUtc ? arrivalTime : arrivalTime.toUtc();
        data['arrival_time'] = arrivalTimeUtc.toIso8601String();
      }
      
      final url = '${ApiConfig.baseUrl}/staff/flights/$flightId';
      final response = await _authenticatedDio.put(url, data: data);
      return Flight.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteFlight(int flightId) async {
    try {
      final url = '${ApiConfig.baseUrl}/staff/flights/$flightId';
      await _authenticatedDio.delete(url);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Announcement> createAnnouncement({
    required int flightId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/staff/flights/$flightId/announcements';
      final response = await _authenticatedDio.post(url, data: {
        'title': title,
        'message': message,
        'type': type,
      });
      return Announcement.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== БРОНИРОВАНИЯ ====================
  
  Future<List<Booking>> getAllBookings() async {
    try {
      final url = '${ApiConfig.baseUrl}/staff/bookings';
      final response = await _authenticatedDio.get(url);
      return (response.data as List)
          .map((json) => Booking.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Booking> getBookingByPnr(String pnr) async {
    try {
      final url = '${ApiConfig.baseUrl}/staff/bookings/by-pnr/$pnr';
      final response = await _authenticatedDio.get(url);
      return Booking.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Booking>> getBookingsByFlight(int flightId) async {
    try {
      final url = '${ApiConfig.baseUrl}/staff/bookings/by-flight/$flightId';
      final response = await _authenticatedDio.get(url);
      return (response.data as List)
          .map((json) => Booking.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Booking> cancelBooking(int bookingId) async {
    try {
      final url = '${ApiConfig.baseUrl}/staff/bookings/$bookingId/cancel';
      final response = await _authenticatedDio.post(url);
      return Booking.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteBooking(int bookingId) async {
    try {
      final url = '${ApiConfig.baseUrl}/staff/bookings/$bookingId';
      await _authenticatedDio.delete(url);
      // Response is just a success message, no need to parse
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Booking> reassignSeat({
    required int ticketId,
    required String newSeatNumber,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/staff/bookings/reassign-seat';
      final response = await _authenticatedDio.post(url, data: {
        'ticket_id': ticketId,
        'new_seat_number': newSeatNumber,
      });
      return Booking.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      final message = error.response?.data['detail'] ?? 'Unknown error';
      return message.toString();
    } else {
      return 'Network error. Please check your connection.';
    }
  }
}

