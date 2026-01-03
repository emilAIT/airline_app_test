import '../models/announcement.dart';
import 'api_client.dart';

class AnnouncementsApi {
  final ApiClient client;

  AnnouncementsApi(this.client);

  Future<List<Announcement>> getMyAnnouncements() async {
    final response = await client.get('/announcements/my-announcements');
    return (response as List)
        .map((json) => Announcement.fromJson(json))
        .toList();
  }

  Future<List<Announcement>> getFlightAnnouncements(int flightId) async {
    final response = await client.get('/announcements/flight/$flightId');
    return (response as List)
        .map((json) => Announcement.fromJson(json))
        .toList();
  }
}

