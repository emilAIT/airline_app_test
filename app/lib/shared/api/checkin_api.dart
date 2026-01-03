import '../models/boarding_pass.dart';
import 'api_client.dart';

class CheckinApi {
  final ApiClient client;

  CheckinApi(this.client);

  Future<void> checkIn(int ticketId) async {
    await client.post('/checkin/', body: {
      'ticket_id': ticketId,
    });
  }

  Future<BoardingPass> getBoardingPass(int ticketId) async {
    final response = await client.get('/checkin/boarding-pass/$ticketId');
    return BoardingPass.fromJson(response);
  }
}

