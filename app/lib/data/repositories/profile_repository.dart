import '../../core/api_client.dart';
import '../../domain/entities/passenger_profile.dart';
import '../models/passenger_profile_model.dart';

abstract class ProfileRepository {
  Future<PassengerProfile?> getProfile();
  Future<PassengerProfile?> getMyProfile();
  Future<PassengerProfile> createProfile(Map<String, dynamic> profileData);
  Future<PassengerProfile> updateProfile(PassengerProfile profile);
}

class ProfileRepositoryImpl implements ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepositoryImpl(this._apiClient);

  @override
  Future<PassengerProfile?> getProfile() async {
    try {
      final response = await _apiClient.get('/auth/profile');
      if (response == null) return null;
      return PassengerProfileModel.fromJson(response);
    } catch (e) {
      // Return null for any error (403 for staff users, 404 for missing profile, etc.)
      print('Profile fetch error (expected for staff users): $e');
      return null;
    }
  }

  @override
  Future<PassengerProfile> createProfile(Map<String, dynamic> profileData) async {
    final response = await _apiClient.post(
      '/auth/profile',
      body: profileData,
    );
    return PassengerProfileModel.fromJson(response);
  }

  @override
  Future<PassengerProfile?> getMyProfile() async {
    return getProfile();
  }

  @override
  Future<PassengerProfile> updateProfile(PassengerProfile profile) async {
    // Convert profile to JSON
    final profileData = PassengerProfileModel(
      id: profile.id,
      userId: profile.userId,
      firstName: profile.firstName,
      lastName: profile.lastName,
      passportNumber: profile.passportNumber,
      dateOfBirth: profile.dateOfBirth,
      nationality: profile.nationality,
      phoneNumber: profile.phoneNumber,
    ).toJson();
    
    final response = await _apiClient.post(
      '/auth/profile',
      body: profileData,
    );
    return PassengerProfileModel.fromJson(response);
  }
}
