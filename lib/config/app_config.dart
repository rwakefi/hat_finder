class AppConfig {
  static const productionApiBaseUrl =
      'https://hatfinder-production.up.railway.app';

  static const _apiBaseUrlOverride = String.fromEnvironment(
    'HAT_FINDER_API_BASE_URL',
  );

  static String get apiBaseUrl =>
      _apiBaseUrlOverride.isEmpty ? productionApiBaseUrl : _apiBaseUrlOverride;
}
