import '../models/user.dart';
import '../models/passenger_profile.dart';
import 'api_client.dart';

class AuthApi {
  final ApiClient client;

  AuthApi(this.client);

  Future<Map<String, dynamic>> register(String email, String password) async {
    final response = await client.post('/auth/register', body: {
      'email': email,
      'password': password,
    });
    return {
      'user': User.fromJson(response),
      'token': null, // Registration doesn't return token, need to login
    };
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await client.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    return response as Map<String, dynamic>;
  }

  Future<PassengerProfile> getProfile() async {
    final response = await client.get('/auth/profile');
    return PassengerProfile.fromJson(response);
  }

  Future<PassengerProfile> updateProfile(Map<String, dynamic> profileData) async {
    final response = await client.put('/auth/profile', body: profileData);
    return PassengerProfile.fromJson(response);
  }
}

