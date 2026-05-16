import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/shopify_service.dart';
import '../services/database_service.dart';
import '../models/hat.dart';

class HatResultsScreen extends StatefulWidget {
  final String? hatType;
  final String? westernStyle;
  final String? crownShape;
  final List<double>? crownHeights;
  final String? brimShape;
  final List<String>? brimWidths;

  const HatResultsScreen({
    super.key,
    this.hatType,
    this.westernStyle,
    this.crownShape,
    this.crownHeights,
    this.brimShape,
    this.brimWidths,
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
      westernStyle: widget.westernStyle,
      crownShape: widget.crownShape,
      crownHeights: widget.crownHeights,
      brimShape: widget.brimShape,
      brimWidths: widget.brimWidths,
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
        title: Text(
          'MOON RIDGE',
          style: GoogleFonts.tenorSans(
            letterSpacing: 6.0,
            fontSize: 20,
            color: const Color(0xFFA88467),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A3525), // Softer, warmer brown
              Color(0xFF1E140E), // Deeper brown
            ],
          ),
        ),
        child: Column(
          children: [
            _buildSearchSummary(),
            const Divider(height: 1, color: Color(0xFFA88467)),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
              future: _hatsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFA88467)),
                        SizedBox(height: 24),
                        Text(
                          'Consulting Master Inventory...',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            letterSpacing: 1.2,
                          ),
                        ),
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
                        'No matches found for any of these dimensions in our collection right now.\n\n(Try adjusting the shapes or sizes)',
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
                    crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : (MediaQuery.of(context).size.width > 550 ? 2 : 1),
                    crossAxisSpacing: 24, 
                    mainAxisSpacing: 24,
                    mainAxisExtent: MediaQuery.of(context).size.width > 550 ? (widget.hatType == 'Ballcap' ? 660 : 700) : 620, 
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
                        final priceData = variant['price'];
                        if (priceData is String) {
                          priceStr = '\$${double.parse(priceData).toStringAsFixed(2)}';
                        } else if (priceData != null && priceData['amount'] != null) {
                          final amount = priceData['amount'];
                          priceStr = '\$${double.parse(amount.toString()).toStringAsFixed(2)}';
                        }
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
                        color: const Color(0xFF312110),
                        borderRadius: BorderRadius.circular(0), // Sharp edges for premium feel
                        border: Border.all(
                          color: const Color(0xFFA88467).withOpacity(0.3),
                          width: 1.0,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: openProduct,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Title at the very top
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                              child: Text(
                                title.toUpperCase(),
                                style: GoogleFonts.tenorSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFFA88467),
                                  height: 1.2,
                                  letterSpacing: 2.0,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Hero image section
                            Expanded(
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      Color(0xFFF5F0E8), // Soft Off-White/Cream center
                                      Color(0xFFCBB593), // Tan edges
                                    ],
                                    radius: 0.85,
                                  ),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    imageUrl != null
                                        ? Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(32.0),
                                              child: Image.network(
                                                imageUrl,
                                                fit: BoxFit.contain,
                                                errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.grey, size: 48),
                                              ),
                                            ),
                                          )
                                        : const Icon(Icons.image, color: Colors.grey, size: 48),
                                  ],
                                ),
                              ),
                            ),
                            // Attributes Section
                            Container(
                              color: const Color(0xFFE8D9C8).withOpacity(0.05),
                              padding: const EdgeInsets.all(16),
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
                            // Price + CTA row
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (priceStr.isNotEmpty)
                                    Text(
                                      priceStr,
                                      style: GoogleFonts.lora(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFFE8D9C8),
                                      ),
                                    )
                                  else
                                    const SizedBox(),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.bookmark_border, color: Color(0xFFA88467)),
                                    onPressed: () async {
                                      final success = await DatabaseService.saveHat(
                                        name: title,
                                        price: priceStr,
                                        url: productUrl,
                                        brand: widget.westernStyle,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(success ? 'Added to Registry' : 'Failed to save.'),
                                            backgroundColor: success ? const Color(0xFFA88467) : Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  TextButton(
                                    onPressed: openProduct,
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFFA88467),
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                    child: const Text('VIEW DETAILS →', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
    ),);
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
      color: const Color(0xFF2B1D14).withOpacity(0.5),
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 16,
        runSpacing: 16,
        children: [
          _buildSummaryChip('Type', widget.hatType ?? 'Any'),
          if (widget.westernStyle != null)
            _buildSummaryChip('Style', widget.westernStyle!),
          _buildSummaryChip('Crown', '${widget.crownShape ?? 'Any'} (${widget.crownHeights != null ? widget.crownHeights!.map((h) => formatMeasurement(h)).join(", ") : 'Any'})'),
          _buildSummaryChip('Brim', '${widget.brimShape ?? 'Any'} (${widget.brimWidths != null ? widget.brimWidths!.join(", ") : 'Any'})'),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFCBB593), fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFF5F0E8))),
      ],
    );
  }
}
