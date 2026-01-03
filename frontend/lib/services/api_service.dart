import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_service.dart';

// Сервис для работы с API
class ApiService {
  // Global timeout for all HTTP requests to avoid hanging forever
  static const _timeout = Duration(seconds: 10);

  static DateTime? _safeDateYmd(int year, int month, int day) {
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;

    final dt = DateTime.utc(year, month, day);
    if (dt.year != year || dt.month != month || dt.day != day) return null;
    return dt;
  }

  static DateTime? _parseFlexibleDate(String input) {
    final v = input.trim();
    if (v.isEmpty) return null;

    // YYYY-MM-DD (preferred) OR YYYY-DD-MM (common user mistake)
    final isoLike = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
    final m1 = isoLike.firstMatch(v);
    if (m1 != null) {
      final year = int.tryParse(m1.group(1)!);
      final a = int.tryParse(m1.group(2)!);
      final b = int.tryParse(m1.group(3)!);
      if (year == null || a == null || b == null) return null;

      final asYmd = _safeDateYmd(year, a, b);
      if (asYmd != null) return asYmd;

      final swapped = _safeDateYmd(year, b, a);
      if (swapped != null) return swapped;
      return null;
    }

    // DD.MM.YYYY or DD-MM-YYYY
    final dmy = RegExp(r'^(\d{2})[.\-](\d{2})[.\-](\d{4})$');
    final m2 = dmy.firstMatch(v);
    if (m2 != null) {
      final day = int.tryParse(m2.group(1)!);
      final month = int.tryParse(m2.group(2)!);
      final year = int.tryParse(m2.group(3)!);
      if (year == null || month == null || day == null) return null;
      return _safeDateYmd(year, month, day);
    }

    return null;
  }

  static String? _normalizeDateOnly(String? input) {
    if (input == null) return null;
    final parsed = _parseFlexibleDate(input);
    if (parsed == null) return null;
    final y = parsed.year.toString().padLeft(4, '0');
    final m = parsed.month.toString().padLeft(2, '0');
    final d = parsed.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _extractApiErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String) return detail;
        if (detail is Map) {
          final inner = detail['detail'];
          if (inner is String && inner.trim().isNotEmpty) return inner;
        }
        if (detail is List) {
          final messages = <String>[];
          for (final item in detail) {
            if (item is Map) {
              final msg = item['msg'];
              if (msg is String && msg.trim().isNotEmpty) messages.add(msg);
            }
          }
          if (messages.isNotEmpty) return messages.join('\n');
        }
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) return message;
      }
    } catch (_) {
      // ignore
    }
    return '${response.statusCode}: ${response.body}';
  }

  static String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final detail = decoded['detail'];
        if (detail is String && detail.trim().isNotEmpty) return detail;
        if (detail is Map) {
          final inner = detail['detail'];
          if (inner is String && inner.trim().isNotEmpty) return inner;
        }
      }
    } catch (_) {
      // Not JSON or unexpected format.
    }

    final trimmed = body.trim();
    if (trimmed.isEmpty) return 'Ошибка сервера';
    return trimmed.length > 200 ? trimmed.substring(0, 200) : trimmed;
  }

  static Future<List<dynamic>> getAirports() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/airports'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching airports: $e');
    }
    return [];
  }

  static Future<List<dynamic>> searchFlights(
    int fromId,
    int toId,
    DateTime date,
  ) async {
    try {
      final dateStr =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/flights?origin_id=$fromId&destination_id=$toId&departure_date=$dateStr',
            ),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception(
        'Ошибка поиска рейсов (${response.statusCode}): ${_extractErrorMessage(response.body)}',
      );
    } catch (e) {
      debugPrint('Error searching flights: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getSeatMap(int flightId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/flights/$flightId/seats'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching seat map: $e');
    }
    return [];
  }

  static String _uuidV4() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));

    // Per RFC 4122 v4
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int v) => v.toRadixString(16).padLeft(2, '0');
    final b = bytes.map(hex).toList();
    return '${b[0]}${b[1]}${b[2]}${b[3]}-${b[4]}${b[5]}-${b[6]}${b[7]}-${b[8]}${b[9]}-${b[10]}${b[11]}${b[12]}${b[13]}${b[14]}${b[15]}';
  }

  static bool _isProfileComplete(Map<String, dynamic> profile) {
    bool has(String key) => (profile[key] ?? '').toString().trim().isNotEmpty;
    return has('first_name') &&
        has('last_name') &&
        has('passport_number') &&
        has('nationality') &&
        has('date_of_birth');
  }

  /// Create a booking by sending `flight_id` and selected seats.
  ///
  /// Backend contract requires passengers; if [passengerDetails] is omitted,
  /// this method will use the current user's profile to build passengers for
  /// each selected seat.
  ///
  /// Returns booking response which includes:
  /// - `id` (booking id)
  /// - `pnr`
  /// - `seats_held_until` (timestamp when the seat lock expires)
  static Future<Map<String, dynamic>?> createBooking(
    int flightId,
    List<String> selectedSeats, {
    List<Map<String, dynamic>>? passengerDetails,
  }) async {
    final token = AuthService.token;
    if (token == null) return null;

    List<Map<String, dynamic>> passengers;
    if (passengerDetails != null) {
      passengers = passengerDetails.map((p) {
        final rawDob = (p['date_of_birth'] ?? '').toString();
        final normalizedDob = _normalizeDateOnly(rawDob);
        if (normalizedDob == null) {
          throw Exception('Некорректная дата рождения. Используйте YYYY-MM-DD');
        }
        return {...p, 'date_of_birth': normalizedDob};
      }).toList();
    } else {
      final profile = await getMyProfile();
      if (profile == null || !_isProfileComplete(profile)) {
        return null;
      }

      final normalizedDob = _normalizeDateOnly(
        (profile['date_of_birth'] ?? '').toString(),
      );
      if (normalizedDob == null) {
        throw Exception('Некорректная дата рождения. Используйте YYYY-MM-DD');
      }

      passengers = selectedSeats
          .map(
            (seat) => {
              'first_name': profile['first_name'],
              'last_name': profile['last_name'],
              'seat_number': seat,
              'passport_number': profile['passport_number'],
              'nationality': profile['nationality'],
              'date_of_birth': normalizedDob,
            },
          )
          .toList();
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/bookings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'flight_id': flightId, 'passengers': passengers}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    final message = _extractApiErrorMessage(response);
    debugPrint('Booking failed: ${response.statusCode} $message');
    throw Exception(message);
  }

  static Future<List<dynamic>> _getMyBookingsRaw() async {
    try {
      final token = AuthService.token;
      if (token == null) return [];

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/bookings/my'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
      }

      debugPrint(
        'Get my bookings failed: ${response.statusCode} ${response.body}',
      );
      return [];
    } catch (e) {
      debugPrint('Error fetching my bookings: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getMyBookings() async {
    final token = AuthService.token;
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/bookings/my'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      return [];
    }

    final message = _extractApiErrorMessage(response);
    debugPrint('Get my bookings failed: ${response.statusCode} $message');
    throw Exception(message);
  }

  static Future<Map<String, dynamic>?> getFlight(int flightId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/flights/$flightId'),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
      }
      debugPrint('Get flight failed: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error fetching flight: $e');
      return null;
    }
  }

  static Future<List<dynamic>> getAnnouncementsForFlight(int flightId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/announcements/flight/$flightId'),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
      }
      debugPrint(
        'Get announcements failed: ${response.statusCode} ${response.body}',
      );
      return [];
    } catch (e) {
      debugPrint('Error fetching announcements: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> checkInBooking(int bookingId) async {
    final token = AuthService.token;
    if (token == null) return null;

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/bookings/$bookingId/check-in'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    }

    final message = _extractApiErrorMessage(response);
    debugPrint('Check-in booking failed: ${response.statusCode} $message');
    throw Exception(message);
  }

  static Future<Map<String, dynamic>?> getBoardingPass(
    String ticketNumber,
  ) async {
    final token = AuthService.token;
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/checkin/ticket/$ticketNumber'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    }

    final message = _extractApiErrorMessage(response);
    debugPrint('Get boarding pass failed: ${response.statusCode} $message');
    throw Exception(message);
  }

  /// Confirm (process) payment for a booking.
  ///
  /// Note: backend processes payment by booking PNR, so we resolve PNR
  /// via `/bookings/my` using the provided [bookingId].
  static Future<Map<String, dynamic>?> confirmPayment({
    required int bookingId,
    required String paymentMethod, // CARD / APPLE_PAY / GOOGLE_PAY
  }) async {
    try {
      final token = AuthService.token;
      if (token == null) return null;

      final myBookings = await _getMyBookingsRaw();
      final booking = myBookings.cast<dynamic>().firstWhere(
        (b) => b is Map && b['id'] == bookingId,
        orElse: () => null,
      );

      if (booking is! Map) {
        debugPrint('Booking $bookingId not found in /bookings/my');
        return null;
      }

      final bookingPnr = booking['pnr']?.toString();
      if (bookingPnr == null || bookingPnr.isEmpty) return null;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/payments/process'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'booking_pnr': bookingPnr,
          'idempotency_key': _uuidV4(),
          'payment_method': paymentMethod,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      debugPrint(
        'Confirm payment failed: ${response.statusCode} ${response.body}',
      );
      return null;
    } catch (e) {
      debugPrint('Error confirming payment: $e');
      return null;
    }
  }

  /// Confirm (process) payment for a booking by PNR.
  ///
  /// Use this when you already have the booking PNR from `createBooking`.
  static Future<Map<String, dynamic>?> confirmPaymentByPnr({
    required String bookingPnr,
    required String paymentMethod,
  }) async {
    try {
      final token = AuthService.token;
      if (token == null) return null;

      final pnr = bookingPnr.trim();
      if (pnr.isEmpty) return null;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/payments/process'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'booking_pnr': pnr,
          'idempotency_key': _uuidV4(),
          'payment_method': paymentMethod,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      final message = _extractApiErrorMessage(response);
      debugPrint(
        'Confirm payment (pnr) failed: ${response.statusCode} $message',
      );
      throw Exception(message);
    } catch (e) {
      debugPrint('Error confirming payment (pnr): $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getMyProfile() async {
    try {
      final token = AuthService.token;
      if (token == null) return null;

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/profile/'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      if (response.statusCode == 404) {
        return null;
      }

      debugPrint('Get profile failed: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getMyAnnouncements() async {
    try {
      final token = AuthService.token;
      if (token == null) return [];

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/announcements/my'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }

      debugPrint('Get announcements failed: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error fetching announcements: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> upsertMyProfile({
    required String firstName,
    required String lastName,
    String? phone,
    String? dateOfBirth,
    String? passportNumber,
    String? nationality,
  }) async {
    final token = AuthService.token;
    if (token == null) return null;

    final normalizedDob = _normalizeDateOnly(dateOfBirth);
    if (dateOfBirth != null &&
        dateOfBirth.trim().isNotEmpty &&
        normalizedDob == null) {
      throw Exception('Некорректная дата рождения. Используйте YYYY-MM-DD');
    }

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/profile/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'date_of_birth': normalizedDob,
        'passport_number': passportNumber,
        'nationality': nationality,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final message = _extractApiErrorMessage(response);
    debugPrint('Upsert profile failed: ${response.statusCode} $message');
    throw Exception(message);
  }

  // ==================== STAFF API ====================

  static Map<String, String> _staffAuthHeaders() {
    final token = AuthService.token;
    if (token == null) return const {};
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static Future<Map<String, dynamic>?> staffUpdateFlight(
    int flightId, {
    String? status,
    num? basePrice,
  }) async {
    final headers = _staffAuthHeaders();
    if (headers.isEmpty) return null;

    final body = <String, dynamic>{};
    if (status != null) body['status'] = status;
    if (basePrice != null) body['base_price'] = basePrice;

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/staff/flights/$flightId'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    }

    final message = _extractApiErrorMessage(response);
    debugPrint('Staff update flight failed: ${response.statusCode} $message');
    throw Exception(message);
  }

  static Future<Map<String, dynamic>> staffCreateAirplaneWithSeats({
    required String name,
    required String modelType,
    required int totalRows,
    required int seatsPerRow,
    required int extraLegroomRowsCount,
  }) async {
    final headers = _staffAuthHeaders();
    if (headers.isEmpty) {
      throw Exception('Not authenticated as staff');
    }

    final body = {
      'name': name,
      'model_type': modelType,
      'total_rows': totalRows,
      'seats_per_row': seatsPerRow,
      'extra_legroom_rows_count': extraLegroomRowsCount,
    };

    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/staff/airplanes'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception('Invalid response format');
    }

    final message = _extractApiErrorMessage(response);
    debugPrint('Staff create airplane failed: ${response.statusCode} $message');
    throw Exception(message);
  }

  static Future<Map<String, dynamic>?> staffUpdateAirplane(
    int airplaneId, {
    String? model,
    String? manufacturer,
    int? totalSeats,
  }) async {
    final headers = _staffAuthHeaders();
    if (headers.isEmpty) return null;

    final body = <String, dynamic>{};
    if (model != null && model.trim().isNotEmpty) body['model'] = model.trim();
    if (manufacturer != null && manufacturer.trim().isNotEmpty) {
      body['manufacturer'] = manufacturer.trim();
    }
    if (totalSeats != null) body['total_seats'] = totalSeats;

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/staff/airplanes/$airplaneId'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    }

    final message = _extractApiErrorMessage(response);
    debugPrint('Staff update airplane failed: ${response.statusCode} $message');
    throw Exception(message);
  }

  static Future<List<dynamic>> staffGetAnnouncementsForFlight(
    int flightId,
  ) async {
    final headers = _staffAuthHeaders();
    if (headers.isEmpty) return [];

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/staff/announcements/flight/$flightId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      return [];
    }

    final message = _extractApiErrorMessage(response);
    debugPrint(
      'Staff get announcements failed: ${response.statusCode} $message',
    );
    throw Exception(message);
  }

  static Future<Map<String, dynamic>?> staffCreateAnnouncement({
    required int flightId,
    required String message,
    required String type,
  }) async {
    final headers = _staffAuthHeaders();
    if (headers.isEmpty) return null;

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/staff/announcements'),
      headers: headers,
      body: jsonEncode({
        'flight_id': flightId,
        'message': message,
        'announcement_type': type,
      }),
    );

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    }

    final messageOut = _extractApiErrorMessage(response);
    debugPrint(
      'Staff create announcement failed: ${response.statusCode} $messageOut',
    );
    throw Exception(messageOut);
  }

  static Future<Map<String, dynamic>?> staffUpdateAnnouncement(
    int announcementId, {
    String? message,
    String? type,
  }) async {
    final headers = _staffAuthHeaders();
    if (headers.isEmpty) return null;

    final body = <String, dynamic>{};
    if (message != null && message.trim().isNotEmpty)
      body['message'] = message.trim();
    if (type != null && type.trim().isNotEmpty)
      body['announcement_type'] = type.trim();

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/staff/announcements/$announcementId'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    }

    final messageOut = _extractApiErrorMessage(response);
    debugPrint(
      'Staff update announcement failed: ${response.statusCode} $messageOut',
    );
    throw Exception(messageOut);
  }

  static Future<void> staffDeleteAnnouncement(int announcementId) async {
    final headers = _staffAuthHeaders();
    if (headers.isEmpty) return;

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/staff/announcements/$announcementId'),
      headers: headers,
    );

    if (response.statusCode == 204) return;

    final messageOut = _extractApiErrorMessage(response);
    debugPrint(
      'Staff delete announcement failed: ${response.statusCode} $messageOut',
    );
    throw Exception(messageOut);
  }

  static Future<List<dynamic>> staffListBookings() async {
    final headers = _staffAuthHeaders();
    if (headers.isEmpty) return [];

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/staff/bookings'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      return [];
    }

    final message = _extractApiErrorMessage(response);
    debugPrint('Staff list bookings failed: ${response.statusCode} $message');
    throw Exception(message);
  }

  static Future<Map<String, dynamic>?> staffUpdateBooking(
    int bookingId, {
    required String status,
  }) async {
    final headers = _staffAuthHeaders();
    if (headers.isEmpty) return null;

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/staff/bookings/$bookingId'),
      headers: headers,
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    }

    final message = _extractApiErrorMessage(response);
    debugPrint('Staff update booking failed: ${response.statusCode} $message');
    throw Exception(message);
  }

  static Future<List<dynamic>> staffListFlights() async {
    final headers = _staffAuthHeaders();
    if (headers.isEmpty) return [];

    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/staff/flights'), headers: headers)
        .timeout(_timeout);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      return [];
    }

    final message = _extractApiErrorMessage(response);
    debugPrint('Staff list flights failed: ${response.statusCode} $message');
    throw Exception(message);
  }

  static Future<Map<String, dynamic>?> staffUpdateFlightStatus({
    required int flightId,
    required String status,
    String? departureTime,
  }) async {
    final headers = _staffAuthHeaders();
    if (headers.isEmpty) return null;

    final body = <String, dynamic>{'status': status};
    if (departureTime != null) {
      body['departure_time'] = departureTime;
    }

    final response = await http
        .patch(
          Uri.parse('${ApiConfig.baseUrl}/staff/flights/$flightId'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    }

    final message = _extractApiErrorMessage(response);
    debugPrint(
      'Staff update flight status failed: ${response.statusCode} $message',
    );
    throw Exception(message);
  }

  static Future<Map<String, dynamic>?> staffCreateFlight({
    required String flightNumber,
    required int originId,
    required int destinationId,
    int? airplaneId,
    required String departureTime,
    required String arrivalTime,
    required double basePrice,  // Backend uses base_price
    String? terminal,
    String? gate,
    String status = 'SCHEDULED',
  }) async {
    final headers = _staffAuthHeaders();
    if (headers.isEmpty) return null;

    // CRITICAL: Ensure all IDs are int (not String)
    final body = {
      'flight_number': flightNumber,
      'origin_airport_id': originId,  // Backend expects origin_airport_id
      'destination_airport_id': destinationId,  // Backend expects destination_airport_id
      'departure_time': departureTime,
      'arrival_time': arrivalTime,
      'base_price': basePrice,  // Backend expects base_price
    };

    if (airplaneId != null) body['airplane_id'] = airplaneId;  // Already int
    if (terminal != null && terminal.isNotEmpty) body['terminal'] = terminal;
    if (gate != null && gate.isNotEmpty) body['gate'] = gate;

    // Debug: Print exact JSON being sent
    debugPrint('📤 Request body: ${jsonEncode(body)}');

    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/staff/flights'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('✅ Flight created successfully');
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    }

    final message = _extractApiErrorMessage(response);
    debugPrint('❌ Create flight failed: ${response.statusCode} $message');
    throw Exception(message);
  }

  static Future<List<dynamic>> staffListAirplanes() async {
    final headers = _staffAuthHeaders();
    if (headers.isEmpty) return [];

    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/staff/airplanes'),
          headers: headers,
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      return [];
    }

    final message = _extractApiErrorMessage(response);
    debugPrint('Staff list airplanes failed: ${response.statusCode} $message');
    throw Exception(message);
  }
}
