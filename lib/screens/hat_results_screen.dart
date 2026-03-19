import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/shopify_service.dart';
import '../models/hat.dart';

class HatResultsScreen extends StatefulWidget {
  final String? hatType;
  final String? crownShape;
  final double? crownHeight;
  final String? brimShape;
  final String? brimWidth;

  const HatResultsScreen({
    super.key,
    this.hatType,
    this.crownShape,
    this.crownHeight,
    this.brimShape,
    this.brimWidth,
  });

  @override
  State<HatResultsScreen> createState() => _HatResultsScreenState();
}

class _HatResultsScreenState extends State<HatResultsScreen> {
  late Future<List<dynamic>> _hatsFuture;

  @override
  void initState() {
    super.initState();
    _hatsFuture = ShopifyService.searchHats(
      hatType: widget.hatType,
      crownShape: widget.crownShape,
      crownHeight: widget.crownHeight,
      brimShape: widget.brimShape,
      brimWidth: widget.brimWidth,
    );
  }

  String _metaValue(dynamic entry) {
    if (entry == null || entry['value'] == null) return '—';
    try {
      final parsed = jsonDecode(entry['value'] as String);
      if (parsed is List && parsed.isNotEmpty) return parsed.first.toString();
      return parsed.toString();
    } catch (_) {
      return entry['value'].toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo.png',
          height: 55.2, // Increased by 15% from 48
          color: const Color(0xFFC7B08B),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchSummary(),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _hatsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Checking Shopify Inventory...'),
                      ],
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No matches found for any of these dimensions in your store right now.\n\n(Try adjusting the shapes or sizes)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }

                final hats = snapshot.data!;
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 2,
                    crossAxisSpacing: 18, // Increased spacing
                    mainAxisSpacing: 18,
                    mainAxisExtent: widget.hatType == 'Ballcap' ? 560 : 600, // Reduced based on new spacing
                  ),
                  itemCount: hats.length,
                  itemBuilder: (context, index) {
                    final hat = hats[index];
                    final title = hat['title'] ?? 'Unknown Hat';
                    final imageUrl = hat['featuredImage']?['url'];

                    // Metafield values
                    final crownShape = _metaValue(hat['crownShape']);
                    final crownHeight = _metaValue(hat['crownHeight']);
                    final material = _metaValue(hat['material']);
                    final brimShape = _metaValue(hat['brimShape']);
                    final brimWidth = _metaValue(hat['brimWidth']);
                    final backstrap = _metaValue(hat['backstrap']);
                    final isBallcap = widget.hatType == 'Ballcap';

                    String priceStr = '';
                    try {
                      final variant = hat['variants']?['edges']?[0]?['node'];
                      if (variant != null) {
                        final amount = variant['price']['amount'];
                        priceStr = '\$${double.parse(amount).toStringAsFixed(2)}';
                      }
                    } catch (e) {
                      debugPrint('Price parse error for "$title": $e');
                    }

                    final String? productUrl = hat['onlineStoreUrl'];

                    Future<void> openProduct() async {
                      if (productUrl != null && productUrl.isNotEmpty) {
                        final Uri url = Uri.parse(productUrl);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open product page.')),
                          );
                        }
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Product link is unavailable.')),
                        );
                      }
                    }

                    return Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFCF9F5), Color(0xFFF5F0E8)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: openProduct,
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Title at the very top
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                              child: Text(
                                title,
                                style: GoogleFonts.cinzel(
                                  fontSize: 22, // Increased from 18
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2B1D14), // Darker for better contrast
                                  height: 1.2, // Improved line spacing
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Hero image section
                            SizedBox(
                              height: 220, // Reduced from 260
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Soft shadow under image
                                  if (imageUrl != null)
                                    Positioned.fill(
                                      top: 40,
                                      bottom: 20,
                                      child: Center(
                                        child: Container(
                                          width: 220,
                                          height: 180,
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 40,
                                                spreadRadius: 5,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  imageUrl != null
                                      ? Center(
                                          child: Image.network(
                                            imageUrl,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.grey, size: 48),
                                          ),
                                        )
                                      : const Icon(Icons.image, color: Colors.grey, size: 48),
                                ],
                              ),
                            ),
                            // Attributes Section
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: isBallcap
                                    ? [
                                        _buildAttribute('Material', material, Icons.layers),
                                        _buildAttribute('Brim Width', brimWidth, Icons.straighten),
                                        _buildAttribute('Backstrap', backstrap, Icons.settings_backup_restore),
                                      ]
                                    : [
                                        _buildAttribute('Crown Shape', crownShape, Icons.architecture),
                                        _buildAttribute('Crown Height', crownHeight, Icons.vertical_align_top),
                                        _buildAttribute('Material', material, Icons.layers),
                                        _buildAttribute('Brim Shape', brimShape, Icons.waves),
                                        _buildAttribute('Brim Width', brimWidth, Icons.straighten),
                                      ],
                              ),
                            ),
                            const Spacer(),
                            // Price + CTA row
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (priceStr.isNotEmpty)
                                    Expanded(
                                      child: Text(
                                        priceStr,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF2B1D14), // High contrast
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  else
                                    const SizedBox(),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: openProduct,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFC7B08B),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                      elevation: 3,
                                    ),
                                    child: const Text('Shop Now →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), // Refined text
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttribute(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2), // Tighter vertical spacing
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF8A7060).withOpacity(0.6)),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 13, // Sans-serif default
              color: Color(0xFF8A7060),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13, // Sans-serif default
                fontWeight: FontWeight.w600,
                color: Color(0xFF2B1D14),
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSummary() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 16,
        runSpacing: 16,
        children: [
          _buildSummaryChip('Type', widget.hatType ?? 'Any'),
          _buildSummaryChip('Crown', '${widget.crownShape ?? 'Any'} (${widget.crownHeight != null ? formatMeasurement(widget.crownHeight!) : 'Any'})'),
          _buildSummaryChip('Brim', '${widget.brimShape ?? 'Any'} (${widget.brimWidth ?? 'Any'})'),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
