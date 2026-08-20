abstract final class AppEnv {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static bool get usesRemoteApi => baseUrl.trim().isNotEmpty;
}
