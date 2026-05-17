import 'dart:convert';
import 'package:flutter/material.dart';
import 'shop_webview_screen.dart';
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
  String? _selectedColor;

  // Brand colors — consistent with the rest of the app & moonridgecompany.com
  static const Color _espresso = Color(0xFF2D2926);
  static const Color _turquoise = Color(0xFF559C99);
  static const Color _white = Colors.white;
  static const Color _offWhite = Color(0xFFF8F7F5);
  static const Color _borderGrey = Color(0xFFE8E5E1);

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
      backgroundColor: _white,
      appBar: AppBar(
        backgroundColor: _white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 90,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _espresso, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/Moon Ridge Header Logo.png',
              height: 45.0,
            ),
            const SizedBox(height: 2),
            Text(
              'RESULTS',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: _espresso,
                letterSpacing: 3.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Turquoise progress accent line
          Container(height: 3, color: _turquoise),
          _buildSearchSummary(),
          Divider(height: 1, color: _borderGrey),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _hatsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: _turquoise),
                        const SizedBox(height: 24),
                        Text(
                          'Finding Your Perfect Hat...',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: _espresso.withOpacity(0.5),
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 56, color: _espresso.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text(
                            'No Matches Found',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _espresso,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your shape or size filters.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: _espresso.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final hats = snapshot.data!;

                // Extract unique colors from returned products
                final Set<String> availableColors = {};
                for (final hat in hats) {
                  final color = _metaValue(hat['color']);
                  if (color != '—' && color.isNotEmpty) {
                    availableColors.add(color);
                  }
                }
                final sortedColors = availableColors.toList()..sort();

                // Filter by selected color
                final filteredHats = _selectedColor == null
                    ? hats
                    : hats.where((hat) {
                        final color = _metaValue(hat['color']);
                        return color.toLowerCase() == _selectedColor!.toLowerCase();
                      }).toList();

                return Column(
                  children: [
                    // Color filter bar
                    if (sortedColors.isNotEmpty)
                      Container(
                        color: _white,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Row(
                          children: [
                            Icon(Icons.palette_outlined, size: 16, color: _espresso.withOpacity(0.4)),
                            const SizedBox(width: 8),
                            Text(
                              'COLOR',
                              style: GoogleFonts.montserrat(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: _turquoise,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 32,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    // "All" chip
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: GestureDetector(
                                        onTap: () => setState(() => _selectedColor = null),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _selectedColor == null ? _turquoise : _white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: _selectedColor == null ? _turquoise : _borderGrey,
                                            ),
                                          ),
                                          child: Text(
                                            'All',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: _selectedColor == null ? _white : _espresso,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Color chips
                                    ...sortedColors.map((color) {
                                      final isSelected = _selectedColor == color;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: GestureDetector(
                                          onTap: () => setState(() => _selectedColor = color),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isSelected ? _turquoise : _white,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isSelected ? _turquoise : _borderGrey,
                                              ),
                                            ),
                                            child: Text(
                                              color,
                                              style: GoogleFonts.montserrat(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected ? _white : _espresso,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (sortedColors.isNotEmpty)
                      Divider(height: 1, color: _borderGrey),
                    // Grid
                    Expanded(
                      child: filteredHats.isEmpty
                          ? Center(
                              child: Text(
                                'No hats in this color.',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: _espresso.withOpacity(0.4),
                                ),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.48,
                              ),
                              itemCount: filteredHats.length,
                              itemBuilder: (context, index) {
                                return _buildHatCard(filteredHats[index]);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHatCard(dynamic hat) {
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

    void openProduct() {
      if (productUrl != null && productUrl.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShopWebViewScreen(
              url: productUrl,
              title: title,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product link is unavailable.')),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderGrey, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: openProduct,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero image
            Expanded(
              flex: 5,
              child: Container(
                color: _offWhite,
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        alignment: const Alignment(0.0, -0.1),
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(Icons.image_outlined,
                              color: _espresso.withOpacity(0.15), size: 36),
                        ),
                      )
                    : Center(
                        child: Icon(Icons.image_outlined,
                            color: _espresso.withOpacity(0.15), size: 36),
                      ),
              ),
            ),
            // Title + Price + CTA
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _espresso,
                        letterSpacing: 1.0,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Price
                    if (priceStr.isNotEmpty)
                      Text(
                        priceStr,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _turquoise,
                        ),
                      ),
                    const Spacer(),
                    // Compact attributes
                    if (!isBallcap) ...[
                      _buildAttribute('Crown', crownShape),
                      _buildAttribute('Brim', brimShape),
                    ] else ...[
                      _buildAttribute('Material', material),
                    ],
                    const Spacer(),
                    // CTA row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final success = await DatabaseService.saveHat(
                              name: title,
                              price: priceStr,
                              url: productUrl,
                              brand: widget.westernStyle,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      success ? 'Added to Registry' : 'Failed to save.'),
                                  backgroundColor: success ? _turquoise : Colors.red,
                                ),
                              );
                            }
                          },
                          child: Icon(Icons.bookmark_border_rounded,
                              color: _espresso.withOpacity(0.4), size: 20),
                        ),
                        const Spacer(),
                        Text(
                          'VIEW →',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _turquoise,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttribute(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _espresso.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _espresso,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSummary() {
    return Container(
      color: _offWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 20,
        runSpacing: 10,
        children: [
          _buildSummaryChip('Type', widget.hatType ?? 'Any'),
          if (widget.westernStyle != null)
            _buildSummaryChip('Style', widget.westernStyle!),
          _buildSummaryChip(
              'Crown',
              '${widget.crownShape ?? 'Any'} (${widget.crownHeights != null ? widget.crownHeights!.map((h) => formatMeasurement(h)).join(", ") : 'Any'})'),
          _buildSummaryChip(
              'Brim',
              '${widget.brimShape ?? 'Any'} (${widget.brimWidths != null ? widget.brimWidths!.join(", ") : 'Any'})'),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.montserrat(
            fontSize: 10,
            color: _turquoise,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _espresso,
          ),
        ),
      ],
    );
  }
}
