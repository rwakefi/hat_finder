class AppConfig {
  static const shopifyStoreDomain = 'raftermhatco.myshopify.com';
  static const publicStoreUrl = 'https://moonridgecompany.com';
  static const hatFinderUrl = 'https://hatfinder.moonridgecompany.com';
  static const hatFinderEmbedUrl = '$hatFinderUrl/?embed=1';
  static const storefrontApiToken = '0eb766e2857fd651ebbbd51d00404ea2';
  static const storefrontApiUrl =
      'https://raftermhatco.myshopify.com/api/2024-01/graphql.json';

  /// Railway backend — serves Shopify admin metafield validation lists.
  static const hatFinderApiBaseUrl = String.fromEnvironment(
    'HAT_FINDER_API_BASE_URL',
    defaultValue: 'https://hatfinder-production.up.railway.app',
  );
}
