import '../models/airplane.dart';
import '../models/flight.dart';
import '../models/announcement.dart';
import '../models/booking.dart';
import '../models/ticket.dart';
import 'api_client.dart';

class StaffApi {
  final ApiClient client;

  StaffApi(this.client);

  // Airplanes
  Future<Airplane> createAirplane(Map<String, dynamic> airplaneData) async {
    final response = await client.post('/staff/airplanes', body: airplaneData);
    return Airplane.fromJson(response);
  }

  Future<List<Airplane>> getAirplanes() async {
    final response = await client.get('/staff/airplanes');
    return (response as List).map((json) => Airplane.fromJson(json)).toList();
  }

  Future<List<Airplane>> getAllAirplanes() async {
    return getAirplanes();
  }

  Future<Airplane> getAirplane(int airplaneId) async {
    final response = await client.get('/staff/airplanes/$airplaneId');
    return Airplane.fromJson(response);
  }

  Future<Airplane> updateAirplane(int airplaneId, Map<String, dynamic> airplaneData) async {
    final response = await client.patch('/staff/airplanes/$airplaneId', body: airplaneData);
    return Airplane.fromJson(response);
  }

  // Flights
  Future<Flight> createFlight(Map<String, dynamic> flightData) async {
    final response = await client.post('/staff/flights', body: flightData);
    return Flight.fromJson(response);
  }

  Future<List<Flight>> getAllFlights() async {
    final response = await client.get('/staff/flights');
    return (response as List).map((json) => Flight.fromJson(json)).toList();
  }

  Future<Flight> getFlightById(int flightId) async {
    final response = await client.get('/staff/flights/$flightId');
    return Flight.fromJson(response);
  }

  Future<Flight> updateFlight(int flightId, Map<String, dynamic> flightData) async {
    final response = await client.put('/staff/flights/$flightId', body: flightData);
    return Flight.fromJson(response);
  }

  Future<void> deleteFlight(int flightId) async {
    await client.delete('/staff/flights/$flightId');
  }

  // Announcements
  Future<Announcement> createAnnouncement(Map<String, dynamic> announcementData) async {
    final response = await client.post('/staff/announcements', body: announcementData);
    return Announcement.fromJson(response);
  }

  Future<List<Announcement>> getAllAnnouncements() async {
    final response = await client.get('/staff/announcements');
    return (response as List).map((json) => Announcement.fromJson(json)).toList();
  }

  Future<void> deleteAnnouncement(int announcementId) async {
    await client.delete('/staff/announcements/$announcementId');
  }

  // Bookings
  Future<List<Booking>> getAllBookings() async {
    final response = await client.get('/staff/bookings');
    return (response as List).map((json) => Booking.fromJson(json)).toList();
  }

  Future<List<Booking>> getFlightBookings(int flightId) async {
    final response = await client.get('/staff/bookings/flight/$flightId');
    return (response as List).map((json) => Booking.fromJson(json)).toList();
  }

  Future<Booking> searchBooking(String pnr) async {
    final response = await client.get('/staff/bookings/$pnr');
    return Booking.fromJson(response);
  }

  Future<Booking> cancelBooking(int bookingId) async {
    final response = await client.post('/staff/bookings/$bookingId/cancel');
    return Booking.fromJson(response);
  }

  Future<Ticket> reassignSeat({
    required int ticketId,
    required String newSeatNumber,
  }) async {
    final response = await client.post('/staff/bookings/reassign-seat', body: {
      'ticket_id': ticketId,
      'new_seat_number': newSeatNumber,
    });
    return Ticket.fromJson(response);
  }
}

