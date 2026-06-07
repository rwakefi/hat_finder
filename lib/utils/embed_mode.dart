import 'package:flutter/foundation.dart';

/// True when Hat Finder runs inside a Shopify (or other) iframe.
///
/// Use `https://hatfinder.moonridgecompany.com/?embed=1` as the iframe `src`.
abstract final class EmbedMode {
  static bool get isActive =>
      kIsWeb && Uri.base.queryParameters['embed'] == '1';
}
