import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../screens/shop_webview_screen.dart';

/// Builds and opens Moon Ridge Shopify product URLs.
class StorefrontLinks {
  StorefrontLinks._();

  static String? productUrlFor(dynamic product) {
    final direct = product['onlineStoreUrl'] as String?;
    if (direct != null && direct.isNotEmpty) return direct;

    final handle = product['handle'] as String?;
    if (handle != null && handle.isNotEmpty) {
      return '${AppConfig.publicStoreUrl}/products/$handle';
    }
    return null;
  }

  static String withVariant(String baseUrl, String variantGid) {
    final variantId = variantGid.split('/').last;
    final uri = Uri.parse(baseUrl);
    return uri.replace(
      queryParameters: {...uri.queryParameters, 'variant': variantId},
    ).toString();
  }

  static Future<void> openProductPage(
    BuildContext context, {
    required String url,
    required String title,
  }) async {
    final uri = Uri.parse(url);

    if (kIsWeb) {
      final launched = await launchUrl(
        uri,
        webOnlyWindowName: '_blank',
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the product page.')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShopWebViewScreen(
          url: url,
          title: title,
        ),
      ),
    );
  }
}
