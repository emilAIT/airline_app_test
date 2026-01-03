// HTTP client service for all backend API calls.
//
// Uses Dio with interceptors for JWT auth token management.
// Platform-aware base URL (localhost for web, 10.0.2.2 for Android).
//
// Provides methods for:
// - Auth (login, register, getCurrentUser)
// - Flights (search, details, seat map)
// - Bookings (create, list, cancel)
// - Payments (process, history)
// - Check-in (check-in, boarding pass)
// - Staff/Admin operations
// - Notifications
//
// Part of: Flutter Frontend / Services
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiService {
  // Platform-aware baseUrl
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    }
    // For specific mobile platforms (only relevant if not web)
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000/api';
      case TargetPlatform.iOS:
        return 'http://localhost:8000/api';
      default:
        // Fallback for other platforms (macOS, Windows, Linux)
        return 'http://localhost:8000/api';
    }
  }
  late Dio _dio;
  SharedPreferences? _prefs;

  ApiService({SharedPreferences? prefs}) : _prefs = prefs {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptor for auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await _ensurePrefs();
          final token = _prefs?.getString('access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired or invalid
            await _ensurePrefs();
            await _prefs?.remove('access_token');
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Update token when user logs in
  void updateToken(String? token) async {
    _prefs ??= await SharedPreferences.getInstance();
    if (token != null) {
      await _prefs!.setString('access_token', token);
    } else {
      await _prefs!.remove('access_token');
    }
  }
  
  // Initialize prefs if not already initialized
  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

        // Auth endpoints
        Future<Response> register(String email, String password, {String? role, int? assignedAirplaneId}) async {
          final data = <String, dynamic>{
            'email': email,
            'password': password,
          };
          if (role != null) {
            data['role'] = role;
          }
          if (assignedAirplaneId != null) {
            data['assigned_airplane_id'] = assignedAirplaneId;
          }
          return await _dio.post('/auth/register', data: data);
        }

  Future<Response> login(String email, String password) async {
    return await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> getCurrentUser() async {
    return await _dio.get('/auth/me');
  }

  // Airport endpoints
  Future<Response> getAirports() async {
    return await _dio.get('/flights/airports');
  }

  Future<Response> createAirport(Map<String, dynamic> airportData) async {
    return await _dio.post('/staff/airports', data: airportData);
  }

  Future<Response> deleteAirport(int airportId) async {
    return await _dio.delete('/staff/airports/$airportId');
  }

  Future<Response> getAirportFlights(int airportId) async {
    return await _dio.get('/staff/airports/$airportId/flights');
  }

  // Flight endpoints
  Future<Response> searchFlights({
    int? originAirportId,
    int? destinationAirportId,
    String? departureDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (originAirportId != null) {
      queryParams['origin_airport_id'] = originAirportId;
    }
    if (destinationAirportId != null) {
      queryParams['destination_airport_id'] = destinationAirportId;
    }
    if (departureDate != null) {
      queryParams['departure_date'] = departureDate;
    }
    return await _dio.get('/flights/search', queryParameters: queryParams);
  }

  Future<Response> getFlightDetails(int flightId) async {
    return await _dio.get('/flights/$flightId');
  }

  Future<Response> getSeatMap(int flightId) async {
    return await _dio.get('/flights/$flightId/seat-map');
  }

  // Passenger endpoints
  Future<Response> createProfile(Map<String, dynamic> profileData) async {
    return await _dio.post('/passengers/profile', data: profileData);
  }

  Future<Response> getProfiles() async {
    return await _dio.get('/passengers/profiles');
  }

  Future<Response> getProfileById(int profileId) async {
    return await _dio.get('/passengers/profile/$profileId');
  }

  Future<Response> updateProfile(int profileId, Map<String, dynamic> profileData) async {
    return await _dio.put('/passengers/profile/$profileId', data: profileData);
  }

  Future<Response> deleteProfile(int profileId) async {
    return await _dio.delete('/passengers/profile/$profileId');
  }

  // Backward compatibility helper - gets the "main" profile (first one)
  Future<Response> getProfile() async {
    final response = await getProfiles();
    final List list = response.data;
    if (list.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: Response(
          requestOptions: response.requestOptions,
          statusCode: 404,
          data: {'detail': 'Profile not found'},
        ),
      );
    }
    return Response(
      data: list.first,
      statusCode: 200,
      requestOptions: response.requestOptions,
    );
  }

  // Booking endpoints
  Future<Response> createBooking(Map<String, dynamic> bookingData) async {
    return await _dio.post('/bookings', data: bookingData);
  }

  Future<Response> getMyBookings() async {
    return await _dio.get('/bookings');
  }

  Future<Response> getBookingDetails(int bookingId) async {
    return await _dio.get('/bookings/$bookingId');
  }

  Future<Response> getBookingByPnr(String pnr) async {
    return await _dio.get('/bookings/pnr/$pnr');
  }

  Future<Response> cancelBooking(int bookingId) async {
    return await _dio.put('/bookings/$bookingId/cancel');
  }

  // Payment endpoints
  Future<Response> processPayment(Map<String, dynamic> paymentData) async {
    return await _dio.post('/payments', data: paymentData);
  }

  Future<Response> getMyPayments() async {
    return await _dio.get('/payments/my');
  }

  Future<Response> getAllPayments() async {
    return await _dio.get('/staff/payments');
  }

  // Check-in endpoints
  Future<Response> checkIn(int ticketId) async {
    return await _dio.post('/checkin/ticket/$ticketId');
  }

  Future<Response> getBoardingPass(int ticketId) async {
    return await _dio.get('/checkin/ticket/$ticketId/boarding-pass');
  }

        // Announcement endpoints
        Future<Response> getMyAnnouncements() async {
          return await _dio.get('/announcements/my-flights');
        }

        Future<Response> getFlightAnnouncements(int flightId) async {
          return await _dio.get('/announcements/flight/$flightId');
        }

        // Staff/Admin endpoints
        Future<Response> getStaffFlights() async {
          return await _dio.get('/staff/flights');
        }

        Future<Response> createStaffFlight(Map<String, dynamic> flightData) async {
          return await _dio.post('/staff/flights', data: flightData);
        }

        Future<Response> updateStaffFlight(int flightId, Map<String, dynamic> flightData) async {
          return await _dio.put('/staff/flights/$flightId', data: flightData);
        }

        Future<Response> deleteStaffFlight(int flightId) async {
          return await _dio.delete('/staff/flights/$flightId');
        }

        Future<Response> getStaffAirplanes() async {
          return await _dio.get('/staff/airplanes');
        }

        Future<Response> createStaffAirplane(Map<String, dynamic> airplaneData) async {
          return await _dio.post('/staff/airplanes', data: airplaneData);
        }

        Future<Response> updateStaffAirplane(int airplaneId, Map<String, dynamic> airplaneData) async {
          return await _dio.put('/staff/airplanes/$airplaneId', data: airplaneData);
        }

        Future<Response> deleteStaffAirplane(int airplaneId) async {
          return await _dio.delete('/staff/airplanes/$airplaneId');
        }

        Future<Response> getStaffBookings({int? flightId, String? pnr}) async {
          final queryParams = <String, dynamic>{};
          if (flightId != null) queryParams['flight_id'] = flightId;
          if (pnr != null) queryParams['pnr'] = pnr;
          return await _dio.get('/staff/bookings', queryParameters: queryParams);
        }

        Future<Response> getStaffBookingDetails(int bookingId) async {
          return await _dio.get('/staff/bookings/$bookingId');
        }

        Future<Response> cancelStaffBooking(int bookingId) async {
          return await _dio.put('/staff/bookings/$bookingId/cancel');
        }

        Future<Response> deleteStaffBooking(int bookingId) async {
          return await _dio.delete('/staff/bookings/$bookingId');
        }

  Future<Response> promoteUserToStaff(int userId) async {
    return await _dio.post('/staff/users/$userId/promote-to-staff');
  }

        Future<Response> createStaffAnnouncement(Map<String, dynamic> announcementData) async {
          return await _dio.post('/staff/announcements', data: announcementData);
        }

        Future<Response> deleteStaffAnnouncement(int id) async {
          return await _dio.delete('/staff/announcements/$id');
        }

  Future<Response> getSeatTemplates() async {
    return await _dio.get('/staff/seat-templates');
  }

  Future<Response> createSeatTemplate(Map<String, dynamic> templateData) async {
    return await _dio.post('/staff/seat-templates', data: templateData);
  }

  Future<Response> getStaffUsers({String? role, bool? isApproved}) async {
          final queryParams = <String, dynamic>{};
          if (role != null) queryParams['role'] = role;
          if (isApproved != null) queryParams['is_approved'] = isApproved;
          return await _dio.get('/staff/users', queryParameters: queryParams);
        }

        Future<Response> getStaffAnnouncements({int? flightId}) async {
          final queryParams = <String, dynamic>{};
          if (flightId != null) queryParams['flight_id'] = flightId;
          return await _dio.get('/staff/announcements', queryParameters: queryParams);
        }
        // Staff Approval Methods
  Future<List<dynamic>> getPendingStaff() async {
    try {
      final response = await _dio.get('/admin/staff/pending');
      return response.data;
    } catch (e) {
      print('Error fetching pending staff: $e');
      return [];
    }
  }

  Future<bool> approveStaff(int userId) async {
    try {
      await _dio.post(
        '/admin/staff/$userId/approve',
      );
      return true;
    } catch (e) {
      print('Error approving staff: $e');
      return false;
    }
  }

  Future<bool> rejectStaff(int userId) async {
    try {
      await _dio.delete('/admin/staff/$userId/reject');
      return true;
    } catch (e) {
      print('Error rejecting staff: $e');
      return false;
    }
  }

  Future<bool> deleteStaffUser(int userId) async {
    try {
      await _dio.delete('/admin/staff/$userId');
      return true;
    } catch (e) {
      print('Error deleting staff: $e');
      return false;
    }
  }

  Future<bool> deleteUser(int userId) async {
    try {
      await _dio.delete('/admin/users/$userId');
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // Helper to fetch airplanes for assignment (Admin Only)
  Future<List<dynamic>> getAllAirplanes() async {
    try {
      final response = await _dio.get('/staff/airplanes'); 
      return response.data;
    } catch (e) {
      print('Error fetching airplanes: $e');
      return [];
    }
  }

  // Notification endpoints
  Future<Response> getNotifications() async {
    return await _dio.get('/notifications');
  }

  Future<Response> markNotificationAsRead(int notificationId) async {
    return await _dio.patch('/notifications/$notificationId/read');
  }

  Future<Response> markAllNotificationsAsRead() async {
    return await _dio.post('/notifications/mark-all-read');
  }
}

