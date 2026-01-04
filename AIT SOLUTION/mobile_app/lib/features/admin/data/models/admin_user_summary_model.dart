import 'package:ait_airlines/features/admin/domain/entities/admin_user_summary.dart';

class AdminUserSummaryModel extends AdminUserSummary {
  const AdminUserSummaryModel({
    required int id,
    required String email,
    required String role,
    required String status,
    String? firstName,
    String? lastName,
    List<LinkedItem> flights = const [],
    List<LinkedItem> airplanes = const [],
  }) : super(
          id: id,
          email: email,
          role: role,
          status: status,
          firstName: firstName,
          lastName: lastName,
          flights: flights,
          airplanes: airplanes,
        );

  factory AdminUserSummaryModel.fromJson(Map<String, dynamic> json) {
    List<dynamic> flightsJson = json['flights'] ?? [];
    List<dynamic> airplanesJson = json['airplanes'] ?? [];

    return AdminUserSummaryModel(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      flights: flightsJson
          .map((f) => LinkedItem(id: f['id'] ?? 0, label: f['number']?.toString() ?? ''))
          .toList(),
      airplanes: airplanesJson
          .map((a) => LinkedItem(id: a['id'] ?? 0, label: a['registration']?.toString() ?? ''))
          .toList(),
    );
  }
}

