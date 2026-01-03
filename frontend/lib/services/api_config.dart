class ApiConfig {
  /// Configure at runtime with:
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000/api/v1
  ///
  /// Defaults to localhost for web/desktop development.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );
}
