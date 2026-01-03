import 'dart:convert';
import '../models/ticket_model.dart';
import 'api_service.dart';

class TicketService {
  final ApiService _apiService;
  
  TicketService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  Future<TicketPublic> getTicket(String ticketId) async {
    try {
      final response = await _apiService.get(
        '/tickets/$ticketId',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return TicketPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get ticket: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get ticket error: $e');
    }
  }

  Future<List<TicketPublic>> getTicketsByBooking(String bookingId) async {
    try {
      final response = await _apiService.get(
        '/tickets/booking/$bookingId',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TicketPublic.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get tickets: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get tickets error: $e');
    }
  }

  Future<TicketPublic> searchTicketByNumber(String ticketNumber) async {
    try {
      final response = await _apiService.get(
        '/tickets/search/by-number/$ticketNumber',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return TicketPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to search ticket: ${response.body}');
      }
    } catch (e) {
      throw Exception('Search ticket error: $e');
    }
  }

  Future<List<TicketPublic>> getAllTickets({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _apiService.get(
        '/tickets/',
        queryParams: {
          'skip': skip.toString(),
          'limit': limit.toString(),
          'args': '',
          'kwargs': '',
        },
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = TicketsPublic.fromJson(jsonDecode(response.body));
        return data.data;
      } else {
        throw Exception('Failed to get all tickets: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get all tickets error: $e');
    }
  }
}

