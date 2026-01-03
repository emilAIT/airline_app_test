import 'dart:convert';
import '../models/announcement_model.dart';
import 'api_service.dart';

class AnnouncementService {
  final ApiService _apiService;
  
  AnnouncementService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  Future<List<AnnouncementPublic>> getAnnouncementsByFlight(String flightId) async {
    try {
      final response = await _apiService.get(
        '/announcements/flight/$flightId',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = AnnouncementsPublic.fromJson(jsonDecode(response.body));
        return data.data;
      } else {
        throw Exception('Failed to get announcements: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get announcements error: $e');
    }
  }

  Future<List<AnnouncementPublic>> getMyAnnouncements() async {
    try {
      final response = await _apiService.get(
        '/announcements/me',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = AnnouncementsPublic.fromJson(jsonDecode(response.body));
        return data.data;
      } else {
        throw Exception('Failed to get announcements: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get announcements error: $e');
    }
  }

  Future<List<AnnouncementPublic>> getAllAnnouncements({int skip = 0, int limit = 100}) async {
    try {
      print('AnnouncementService: Getting all announcements (skip=$skip, limit=$limit)');
      
      // FastAPI requires args and kwargs query parameters due to custom_generate_unique_id
      final response = await _apiService.get(
        '/announcements/all',
        queryParams: {
          'skip': skip.toString(),
          'limit': limit.toString(),
          'args': '',
          'kwargs': '',
        },
        requiresAuth: true,
      );

      print('AnnouncementService: Response status: ${response.statusCode}');
      print('AnnouncementService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonBody = jsonDecode(response.body);
          print('AnnouncementService: Parsed JSON: $jsonBody');
          final data = AnnouncementsPublic.fromJson(jsonBody);
          print('AnnouncementService: Got ${data.data.length} announcements');
          // Return empty list if data is null or empty
          return data.data ?? [];
        } catch (e) {
          print('AnnouncementService: JSON parsing error: $e');
          print('AnnouncementService: Response body: ${response.body}');
          // If parsing fails, return empty list
          return [];
        }
      } else if (response.statusCode == 404 || response.statusCode == 403) {
        // If 404 or 403, return empty list instead of error
        print('AnnouncementService: No announcements found or access denied, returning empty list');
        return [];
      } else {
        print('AnnouncementService: Error response: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get all announcements: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('AnnouncementService: Error getting all announcements: $e');
      // If it's a network error or similar, return empty list instead of throwing
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        print('AnnouncementService: Network error, returning empty list');
        return [];
      }
      // For other errors, still throw but with better message
      throw Exception('Get all announcements error: $e');
    }
  }

  Future<AnnouncementPublic> getAnnouncement(String announcementId) async {
    try {
      final response = await _apiService.get(
        '/announcements/$announcementId',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return AnnouncementPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get announcement: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get announcement error: $e');
    }
  }

  Future<AnnouncementPublic> createAnnouncement(AnnouncementCreate create) async {
    try {
      final response = await _apiService.post(
        '/announcements',
        body: create.toJson(),
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return AnnouncementPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create announcement: ${response.body}');
      }
    } catch (e) {
      throw Exception('Create announcement error: $e');
    }
  }

  Future<AnnouncementPublic> updateAnnouncement(String announcementId, AnnouncementUpdate update) async {
    try {
      final response = await _apiService.patch(
        '/announcements/$announcementId',
        body: update.toJson(),
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return AnnouncementPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update announcement: ${response.body}');
      }
    } catch (e) {
      throw Exception('Update announcement error: $e');
    }
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      final response = await _apiService.delete(
        '/announcements/$announcementId',
        requiresAuth: true,
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete announcement: ${response.body}');
      }
    } catch (e) {
      throw Exception('Delete announcement error: $e');
    }
  }
}

