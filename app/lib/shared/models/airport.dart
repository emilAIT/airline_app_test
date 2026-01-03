class Airport {
  final int id;
  final String code;
  final String name;
  final String city;
  final String country;

  Airport({
    required this.id,
    required this.code,
    required this.name,
    required this.city,
    required this.country,
  });

  factory Airport.fromJson(Map<String, dynamic> json) {
    return Airport(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'city': city,
      'country': country,
    };
  }
  
  String get displayName => '$city ($code)';
}

