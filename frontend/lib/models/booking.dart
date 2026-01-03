import 'flight.dart';
import 'ticket.dart';

class Booking {
  final int id;
  final String pnr;
  final String status;
  final List<Ticket> tickets;
  final Flight? flight;

  Booking({
    required this.id,
    required this.pnr,
    required this.status,
    required this.tickets,
    this.flight,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    var rawTickets = json['tickets'];
    List<Ticket> parsedTickets = [];
    
    if (rawTickets is List) {
      for (var t in rawTickets) {
        if (t is Map<String, dynamic>) {
          parsedTickets.add(Ticket.fromJson(t));
        } else if (t is int) {
          // If it's just an ID, create a placeholder ticket
          parsedTickets.add(Ticket(
            id: t,
            pnr: (json['pnr_code'] ?? json['pnr'] ?? '').toString(),
            passengerName: '',
            seat: 'Loading...',
          ));
        }
      }
    }

    return Booking(
      id: json['id'],
      pnr: (json['pnr_code'] ?? json['pnr'] ?? '').toString(),
      status: json['status'] ?? 'CREATED',
      tickets: parsedTickets,
      flight: json['flight'] != null ? Flight.fromJson(json['flight']) : null,
    );
  }
}
