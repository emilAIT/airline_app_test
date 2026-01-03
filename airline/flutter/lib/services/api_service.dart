import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // For Android emulator use: http://10.0.2.2:8001
  // For iOS simulator use: http://127.0.0.1:8001
  // For physical device use your computer's IP address
  // Для симулятора iOS:
  static const String baseUrl = "http://127.0.0.1:8000";

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print(
      '[AUTH DEBUG] getToken() called, token ${token != null ? "EXISTS (${token.length} chars)" : "IS NULL"}',
    );
    return token;
  }

  Future<Map<String, String>> getHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (requiresAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        print('[AUTH DEBUG] Authorization header SET');
      } else {
        print('[AUTH DEBUG] WARNING: No token for authenticated request!');
      }
    }
    return headers;
  }

  Future<http.Response> get(String endpoint, {bool requiresAuth = true}) async {
    print('[API DEBUG] GET $endpoint (auth=$requiresAuth)');
    final headers = await getHeaders(requiresAuth: requiresAuth);
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    print('[API DEBUG] GET $endpoint -> ${response.statusCode}');
    if (response.statusCode >= 400) {
      throw Exception('Request failed: ${response.body}');
    }
    return response;
  }

  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      print('[API DEBUG] POST $endpoint (auth=$requiresAuth)');
      final headers = await getHeaders(requiresAuth: requiresAuth);
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('[API DEBUG] POST $endpoint -> ${response.statusCode}');

      // Handle redirects and empty responses
      if (response.statusCode == 307 || response.statusCode == 302) {
        throw Exception(
          'Unexpected redirect (${response.statusCode}). Please check backend route configuration.',
        );
      }

      if (response.statusCode >= 400) {
        final errorBody = response.body;
        print('[API DEBUG] POST Error: ${response.statusCode} - $errorBody');
        throw Exception('Request failed (${response.statusCode}): $errorBody');
      }

      // SAFETY: Check for empty response body before JSON parsing
      if (response.body.isEmpty) {
        throw Exception(
          'Empty response body from server (status: ${response.statusCode})',
        );
      }

      return response;
    } catch (e) {
      print('[API DEBUG] POST Exception for $endpoint: $e');
      rethrow;
    }
  }

  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    final headers = await getHeaders(requiresAuth: requiresAuth);
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode >= 400) {
      throw Exception('Request failed: ${response.body}');
    }

    // SAFETY: Check for empty response body
    if (response.body.isEmpty) {
      throw Exception(
        'Empty response body from server (status: ${response.statusCode})',
      );
    }

    return response;
  }

  Future<http.Response> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    final headers = await getHeaders(requiresAuth: requiresAuth);
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    if (response.statusCode >= 400 && response.statusCode != 204) {
      throw Exception('Request failed: ${response.body}');
    }
    return response;
  }

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    print('[AUTH DEBUG] login() called for email: $email');
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body:
          'username=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}',
    );
    print('[AUTH DEBUG] login() response: ${response.statusCode}');
    if (response.statusCode != 200) {
      throw Exception('Login failed: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['access_token']);
    print('[AUTH DEBUG] Token saved! Length: ${data['access_token'].length}');

    return data;
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String fullName,
  ) async {
    final response = await post('/auth/register/', {
      'email': email,
      'password': password,
      'full_name': fullName,
      'role': 'PASSENGER',
    }, requiresAuth: false);
    return jsonDecode(response.body);
  }

  // Helper to decode JWT token (simple version - just get role)
  String? getRoleFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      // Add padding if needed
      String normalized = payload;
      switch (payload.length % 4) {
        case 1:
          normalized += '===';
          break;
        case 2:
          normalized += '==';
          break;
        case 3:
          normalized += '=';
          break;
      }
      final decoded = utf8.decode(base64.decode(normalized));
      final Map<String, dynamic> json = jsonDecode(decoded);
      return json['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Flights
  Future<List<dynamic>> getFlights({
    int? originId,
    int? destinationId,
    String? departureDate,
  }) async {
    final queryParams = <String>[];
    if (originId != null) queryParams.add('origin_id=$originId');
    if (destinationId != null) queryParams.add('destination_id=$destinationId');
    if (departureDate != null) queryParams.add('departure_date=$departureDate');

    final query = queryParams.isEmpty ? '' : '?${queryParams.join('&')}';

    final response = await get('/flights$query', requiresAuth: false);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getFlight(int flightId) async {
    final response = await get('/flights/$flightId', requiresAuth: false);
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getAirports() async {
    final response = await get('/flights/airports', requiresAuth: false);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getSeatMap(int flightId) async {
    final response = await get(
      '/flights/$flightId/seat-map',
      requiresAuth: false,
    );
    return jsonDecode(response.body);
  }

  // Passenger Profile
  Future<Map<String, dynamic>> getProfile() async {
    final response = await get('/passenger/profile');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createProfile(
    Map<String, dynamic> profileData,
  ) async {
    final response = await post('/passenger/profile', profileData);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    final response = await put('/passenger/profile', profileData);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> checkProfileComplete() async {
    final response = await get('/passenger/profile/complete');
    return jsonDecode(response.body);
  }

  // Bookings
  Future<Map<String, dynamic>> createBooking(
    Map<String, dynamic> bookingData,
  ) async {
    final response = await post('/bookings/', bookingData);
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getMyBookings() async {
    final response = await get('/bookings/');
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getPendingBookings() async {
    final bookings = await getMyBookings();
    final now = DateTime.now().toUtc();
    return (bookings).where((b) {
      if (b['status'] != 'CREATED') return false;
      if (b['hold_until'] == null) return false;
      var dateStr = b['hold_until'];
      if (!dateStr.endsWith('Z')) dateStr += 'Z';
      final holdUntil = DateTime.parse(dateStr);
      return holdUntil.isAfter(now);
    }).toList();
  }

  // Notifications
  Future<List<dynamic>> getNotifications() async {
    final response = await get('/notifications/');
    return jsonDecode(response.body);
  }

  Future<int> getUnreadNotificationCount() async {
    final response = await get('/notifications/unread/count');
    final data = jsonDecode(response.body);
    return data['count'] ?? 0;
  }

  Future<void> markNotificationRead(int notificationId) async {
    await put('/notifications/$notificationId/read', {});
  }

  Future<Map<String, dynamic>> getBooking(int bookingId) async {
    final response = await get('/bookings/$bookingId');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getBookingByPnr(String pnr) async {
    final response = await get('/bookings/pnr/$pnr');
    return jsonDecode(response.body);
  }

  Future<void> cancelBooking(int bookingId) async {
    await delete('/bookings/$bookingId/');
  }

  Future<Map<String, dynamic>> getCancellationInfo(int bookingId) async {
    final response = await get('/bookings/$bookingId/cancel-info');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> cancelBookingWithRefund(
    int bookingId, {
    required String method, // CARD or APPLE_PAY
    String? cardNumber,
    String? cardHolder,
    int? expiryMonth,
    int? expiryYear,
    String? cvv,
  }) async {
    final body = <String, dynamic>{'method': method};
    if (method == 'CARD') {
      body['refund_card_number'] = cardNumber;
      body['card_holder'] = cardHolder;
      body['expiry_month'] = expiryMonth;
      body['expiry_year'] = expiryYear;
      body['cvv'] = cvv;
    }
    final response = await post('/bookings/$bookingId/cancel', body);
    return jsonDecode(response.body);
  }

  // Payments
  Future<Map<String, dynamic>> createPaymentIntent(
    int bookingId,
    String method,
  ) async {
    final body = <String, dynamic>{'method': method};
    final response = await post('/payments/booking/$bookingId/intent/', body);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> processPayment(
    int bookingId,
    String method, {
    String? cardNumber,
    String? cardHolder,
    int? expiryMonth,
    int? expiryYear,
    String? cvv,
    String? paymentIntentId,
  }) async {
    final body = <String, dynamic>{'method': method};

    // For Stripe, send payment_intent_id
    if (method == 'CARD' && paymentIntentId != null) {
      body['transaction_id'] = paymentIntentId;
    } else if (method == 'CARD') {
      // Legacy: card details (will be replaced by Stripe)
      body['card_number'] = cardNumber;
      body['card_holder'] = cardHolder;
      body['expiry_month'] = expiryMonth;
      body['expiry_year'] = expiryYear;
      body['cvv'] = cvv;
    }

    final response = await post('/payments/booking/$bookingId/', body);
    return jsonDecode(response.body);
  }

  // Check-in
  Future<Map<String, dynamic>> checkIn(int ticketId) async {
    final response = await post('/checkin/', {'ticket_id': ticketId});
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getBoardingPass(int ticketId) async {
    final response = await get('/checkin/ticket/$ticketId/boarding-pass');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getTicket(int ticketId) async {
    final response = await get('/bookings/ticket/$ticketId');
    return jsonDecode(response.body);
  }

  // Announcements
  Future<List<dynamic>> getAnnouncements({int? flightId}) async {
    final query = flightId != null ? '?flight_id=$flightId' : '';
    final response = await get('/announcements$query');
    return jsonDecode(response.body);
  }

  // Photos
  Future<List<dynamic>> getPhotos({
    String? category,
    String? entityType,
    int? entityId,
  }) async {
    final queryParams = <String>[];
    if (category != null) queryParams.add('category=$category');
    if (entityType != null) queryParams.add('entity_type=$entityType');
    if (entityId != null) queryParams.add('entity_id=$entityId');

    final query = queryParams.isEmpty ? '' : '?${queryParams.join('&')}';
    final response = await get('/photos$query', requiresAuth: false);
    return jsonDecode(response.body);
  }

  // Staff endpoints
  // Airports
  Future<List<dynamic>> getStaffAirports() async {
    final response = await get('/staff/airports');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createAirport(
    Map<String, dynamic> airportData,
  ) async {
    final response = await post('/staff/airports/', airportData);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> uploadPhoto({
    required String filePath,
    required String category,
    String? entityType,
    int? entityId,
  }) async {
    final uri = Uri.parse('$baseUrl/photos/');
    final request = http.MultipartRequest('POST', uri);

    // add auth header
    final token = await getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // add fields
    request.fields['category'] = category;
    if (entityType != null) request.fields['entity_type'] = entityType;
    if (entityId != null) request.fields['entity_id'] = entityId.toString();

    // add file
    final file = await http.MultipartFile.fromPath('file', filePath);
    request.files.add(file);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 400) {
      throw Exception('Upload failed: ${response.body}');
    }
    return jsonDecode(response.body);
  }

  Future<void> deletePhoto(int photoId) async {
    await delete('/photos/$photoId/');
  }

  // Airplanes
  Future<List<dynamic>> getStaffAirplanes() async {
    final response = await get('/staff/airplanes');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createAirplane(
    Map<String, dynamic> airplaneData,
  ) async {
    final response = await post('/staff/airplanes/', airplaneData);
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getStaffFlights() async {
    final response = await get('/staff/flights');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createFlight(
    Map<String, dynamic> flightData,
  ) async {
    final response = await post('/staff/flights/', flightData);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateFlight(
    int flightId,
    Map<String, dynamic> flightData,
  ) async {
    final response = await put('/staff/flights/$flightId/', flightData);
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getStaffBookings({int? flightId, String? pnr}) async {
    final queryParams = <String>[];
    if (flightId != null) queryParams.add('flight_id=$flightId');
    if (pnr != null) queryParams.add('pnr=$pnr');

    final query = queryParams.isEmpty ? '' : '?${queryParams.join('&')}';

    final response = await get('/staff/bookings$query');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<void> cancelBookingStaff(int bookingId) async {
    await delete('/staff/bookings/$bookingId/');
  }

  Future<Map<String, dynamic>> reassignSeat(
    int bookingId,
    int ticketId,
    String newSeat,
  ) async {
    final response = await put('/staff/bookings/$bookingId/reassign-seat/', {
      'ticket_id': ticketId,
      'new_seat': newSeat,
    });
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createAnnouncement(
    Map<String, dynamic> announcementData,
  ) async {
    // Мы принудительно добавляем priority, если его забыли во фронтенде
    if (!announcementData.containsKey('priority')) {
      announcementData['priority'] = 'LOW'; // Ставим по дефолту LOW
    }

    // Также бэкенд может просить тип анонса, если его нет
    if (!announcementData.containsKey('type')) {
      announcementData['type'] = 'GENERAL';
    }

    final response = await post('/staff/announcements/', announcementData);
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getStaffAnnouncements({int? flightId}) async {
    final query = flightId != null ? '?flight_id=$flightId' : '';
    final response = await get('/staff/announcements$query');
    return jsonDecode(response.body);
  }
}
