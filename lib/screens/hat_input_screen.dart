import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/hat.dart';
import 'hat_results_screen.dart';
import 'dart:convert';
import '../services/shopify_service.dart';

class HatInputScreen extends StatefulWidget {
  const HatInputScreen({super.key});

  @override
  State<HatInputScreen> createState() => _HatInputScreenState();
}

class _HatInputScreenState extends State<HatInputScreen> {
  final PageController _pageController = PageController();
  final PageController _crownCarouselController = PageController(viewportFraction: 0.78);
  int _currentPageIndex = 0;
  int _currentCrownCarouselIndex = 0;

  HatShapeInfo? selectedHatType;
  String? selectedWesternStyle;

  HatShapeInfo? selectedCrownShape;
  List<double> targetCrownHeights = [];

  HatShapeInfo? selectedBrimShape;
  List<String> targetBrimWidths = [];

  late Future<List<dynamic>> _allProductsFuture;

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

  /// Returns the correct crown shape list based on the selected hat type.
  List<HatShapeInfo> get _currentCrownShapes {
    final typeName = selectedHatType?.name;
    if (typeName == 'Felt') return feltCrownShapes;
    if (typeName == 'Straw') return strawCrownShapes;
    // Ballcap or Any: show all crowns (felt + straw merged, deduplicated by name)
    final seen = <String>{};
    return [...feltCrownShapes, ...strawCrownShapes]
        .where((s) => seen.add(s.name))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _allProductsFuture = ShopifyService.searchHats();
  }



  @override
  void dispose() {
    _pageController.dispose();
    _crownCarouselController.dispose();
    super.dispose();
  }

  List<Widget> get _pages {
    final pages = <Widget>[_buildVisualHatTypeSelection()];
    if (selectedHatType?.name == 'Felt' || selectedHatType?.name == 'Straw') {
      pages.add(_buildVisualWesternSelection());
    }
    pages.addAll([
      _buildVisualCrownSelection(),
      _buildVisualBrimSelection(),
      _buildDetailsSelection(),
    ]);
    return pages;
  }

  void _nextPage({bool overrideValidation = false}) {
    FocusScope.of(context).unfocus();
    if (!overrideValidation) {
      if (_currentPageIndex == 0 && selectedHatType == null) {
        setState(() {
          selectedHatType = hatTypes.first;
        });
      }
      bool hasWestern = (selectedHatType?.name == 'Felt' || selectedHatType?.name == 'Straw');
      int westernIndex = hasWestern ? 1 : -1;
      int crownIndex = hasWestern ? 2 : 1;
      int brimIndex = hasWestern ? 3 : 2;

      if (_currentPageIndex == westernIndex && selectedWesternStyle == null) {
        setState(() {
          selectedWesternStyle = 'Western';
        });
      }
      if (_currentPageIndex == crownIndex && selectedCrownShape == null) {
        setState(() {
          selectedCrownShape = _currentCrownShapes.first;
        });
      }
      if (_currentPageIndex == brimIndex && selectedBrimShape == null) {
        setState(() {
          selectedBrimShape = brimShapes.first;
        });
      }
    }
    
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    FocusScope.of(context).unfocus();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _submitSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HatResultsScreen(
          hatType: selectedHatType?.name,
          westernStyle: selectedWesternStyle,
          crownShape: selectedCrownShape?.name,
          crownHeights: targetCrownHeights.isNotEmpty ? targetCrownHeights : null,
          brimShape: selectedBrimShape?.name,
          brimWidths: targetBrimWidths.isNotEmpty ? targetBrimWidths : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 90,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              Image.asset(
                'assets/images/Moon Ridge Header Logo.png', 
                height: 55.0, 
              ),
              const SizedBox(height: 2),
              Text(
                'HAT FINDER',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: const Color(0xFF2D2926),
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        centerTitle: true,
        leading: null,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white, // Clean, airy background
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildProgressBar(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Disable swipe to force using buttons
                  onPageChanged: (index) {
                    setState(() => _currentPageIndex = index);
                  },
                  children: _pages,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: (_currentPageIndex + 1) / _pages.length.toDouble(),
      backgroundColor: Colors.grey[200],
      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF559C99)), // Turquoise accent
    );
  }

  String get _navButtonText {
    if (_currentPageIndex >= _pages.length - 1) return 'Find Hats';
    bool hasWestern = (selectedHatType?.name == 'Felt' || selectedHatType?.name == 'Straw');
    if (_currentPageIndex == 0) return hasWestern ? 'Next: Style' : 'Next: Crown Shape';
    int westernIndex = hasWestern ? 1 : -1;
    int crownIndex = hasWestern ? 2 : 1;
    if (_currentPageIndex == westernIndex) return 'Next: Crown Shape';
    if (_currentPageIndex == crownIndex) return 'Next: Brim Shape';
    return 'Next: Details';
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_currentPageIndex > 0) ...[
                OutlinedButton(
                  onPressed: _previousPage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2D2926),
                    side: const BorderSide(color: Color(0xFF2D2926), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'BACK',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              ElevatedButton(
                 onPressed: _currentPageIndex < _pages.length - 1 ? _nextPage : _submitSearch,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: const Color(0xFF2D2926),
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(30),
                   ),
                   elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _navButtonText.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _currentPageIndex < _pages.length - 1 
                          ? Icons.arrow_forward 
                          : Icons.check,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisualHatTypeSelection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              Text(
                'Select a Material:',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D2926),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  setState(() => selectedHatType = null);
                  _nextPage(overrideValidation: true);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2D2926),
                  side: const BorderSide(color: Color(0xFF2D2926), width: 1.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: Text(
                  'ANY MATERIAL',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72, // Tall and elegant
            children: hatTypes.map((typeInfo) {
              final isSelected = selectedHatType == typeInfo;
              return Card(
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF559C99) : Colors.grey.shade200,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedHatType = typeInfo;
                      selectedCrownShape = null;
                    });
                    if (typeInfo.name == 'Ballcap') {
                      _submitSearch();
                    } else {
                      _nextPage();
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: typeInfo.imagePath != 'assets/images/placeholder.png'
                            ? Image.asset(
                                typeInfo.imagePath,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey[50],
                                child: const Icon(Icons.category, size: 48, color: Colors.grey),
                              ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        color: Colors.white,
                        child: Text(
                          typeInfo.name.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2D2926),
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualWesternSelection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              Text(
                'Select Style:',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D2926),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  setState(() => selectedWesternStyle = null);
                  _nextPage(overrideValidation: true);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2D2926),
                  side: const BorderSide(color: Color(0xFF2D2926), width: 1.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: Text(
                  'ANY STYLE',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _allProductsFuture,
            builder: (context, snapshot) {
              final styles = [
                {'name': 'Western', 'desc': 'Classic cowboy styles.', 'fallback': 'assets/images/western.jpg'},
                {'name': 'City', 'desc': 'Fedoras and dress hats.', 'fallback': null},
                {'name': 'Outdoor', 'desc': 'Sun and adventure hats.', 'fallback': null},
              ];

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: styles.length,
                itemBuilder: (context, index) {
                  final style = styles[index];
                  final name = style['name'] as String;
                  final isSelected = selectedWesternStyle == name;
                  
                  String? imageUrl;
                  if (snapshot.hasData) {
                    try {
                      if (name == 'Western') {
                        final westernProfiles = ['01', '1', '2', '11', '18', '33', '45', '48', '50', '72', '75', '77', '91', '94', '9G'];
                        imageUrl = snapshot.data!.firstWhere((p) {
                          final profile = _metaValue(p['stetsonProfile']);
                          return westernProfiles.contains(profile) && p['featuredImage']?['url'] != null;
                        }, orElse: () => null)?['featuredImage']?['url'];
                      } else if (name == 'City') {
                        imageUrl = snapshot.data!.firstWhere((p) {
                          return _metaValue(p['city']).toLowerCase() == 'true' && p['featuredImage']?['url'] != null;
                        }, orElse: () => null)?['featuredImage']?['url'];
                      } else if (name == 'Outdoor') {
                        imageUrl = snapshot.data!.firstWhere((p) {
                          return _metaValue(p['outdoors']).toLowerCase() == 'true' && p['featuredImage']?['url'] != null;
                        }, orElse: () => null)?['featuredImage']?['url'];
                      }
                    } catch (_) {}
                  }

                  return Card(
                    elevation: 0,
                    clipBehavior: Clip.antiAlias,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF559C99) : Colors.grey.shade200,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedWesternStyle = name;
                          selectedCrownShape = null;
                        });
                        _nextPage();
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: imageUrl != null
                                ? Image.network(imageUrl, fit: BoxFit.cover)
                                : (style['fallback'] != null
                                    ? Image.asset(style['fallback'] as String, fit: BoxFit.cover)
                                    : Container(
                                        color: Colors.grey[50],
                                        child: const Icon(Icons.style, size: 48, color: Colors.grey),
                                      )),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            color: Colors.white,
                            child: Text(
                              name.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2D2926),
                                letterSpacing: 2.0,
                              ),
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
    );
  }

  Widget _buildStyleCard(String name, String description, {String? fallbackImagePath, String? imageUrl, IconData? icon}) {
    final isSelected = selectedWesternStyle == name;
    return Card(
      elevation: isSelected ? 0 : 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Soft rounded
        side: BorderSide(
          color: isSelected ? const Color(0xFF559C99) : Colors.grey.shade300, // Turquoise selection
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(2),
        onTap: () {
          setState(() {
            selectedWesternStyle = name;
            selectedCrownShape = null;
          });
          _nextPage();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Full-bleed Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2)),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (_, __, ___) => _buildFallbackImage(fallbackImagePath, icon),
                      )
                    : _buildFallbackImage(fallbackImagePath, icon),
              ),
            ),
            // Text at the bottom
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                name.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: const Color(0xFF2D2926),
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage(String? fallbackImagePath, IconData? icon) {
    return fallbackImagePath != null
        ? Image.asset(
            fallbackImagePath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.white,
              child: const Icon(Icons.category, size: 48, color: Colors.grey),
            ),
          )
        : Container(
            color: Colors.white,
            child: Icon(icon ?? Icons.category, size: 48, color: Colors.grey),
          );
  }

  Widget _buildVisualCrownSelection() {
    return FutureBuilder<List<dynamic>>(
      future: _allProductsFuture,
      builder: (context, snapshot) {
        List<HatShapeInfo> sortedShapes = List.from(_currentCrownShapes);
        Map<String, List<String>> shopifyImagesMap = {};
        
        if (snapshot.hasData) {
          try {
            for (var shape in sortedShapes) {
              final shopifyImages = snapshot.data!
                  .where((p) {
                    final crown = _metaValue(p['crownShape']).toLowerCase();
                    final name = shape.name.toLowerCase();
                    return crown.contains(name.replaceAll("'s", "").trim()) || 
                           name.contains(crown.trim());
                  })
                  .map((p) => p['featuredImage']?['url'] as String?)
                  .whereType<String>()
                  .toList();
              shopifyImagesMap[shape.name] = shopifyImages;
            }
            
            sortedShapes.sort((a, b) {
              final aHasShopify = (shopifyImagesMap[a.name]?.isNotEmpty ?? false) ? 1 : 0;
              final bHasShopify = (shopifyImagesMap[b.name]?.isNotEmpty ?? false) ? 1 : 0;
              return bHasShopify.compareTo(aHasShopify);
            });
          } catch (e) {}
        }

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Text(
                    'Select Crown Shape:',
                    style: GoogleFonts.playfairDisplay(fontSize: 26, color: const Color(0xFF2D2926)),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      setState(() => selectedCrownShape = null);
                      _nextPage(overrideValidation: true);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2D2926),
                      side: const BorderSide(color: Color(0xFF2D2926)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                    child: Text('ANY CROWN SHAPE', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ],
              ),
            ),
            // Carousel — viewportFraction < 1 so the next card peeks in
            Expanded(
              child: PageView.builder(
                controller: _crownCarouselController,
                onPageChanged: (index) => setState(() => _currentCrownCarouselIndex = index),
                itemCount: sortedShapes.length,
                itemBuilder: (context, index) {
                  final shape = sortedShapes[index];
                  final isSelected = selectedCrownShape?.name == shape.name;
                  final shopifyImages = shopifyImagesMap[shape.name] ?? [];
                  final String? imageUrl = shopifyImages.isNotEmpty ? shopifyImages.first : null;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 10.0),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF559C99) : Colors.grey.shade200,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() => selectedCrownShape = shape);
                          _nextPage();
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Image takes ~70% of the card
                            Expanded(
                              flex: 5,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: imageUrl != null
                                      ? Image.network(imageUrl, fit: BoxFit.cover)
                                      : Image.asset(shape.imagePath, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                            // Label + description
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                              child: Column(
                                children: [
                                  Text(
                                    shape.name.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF2D2926),
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    shape.description,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Page indicator dots
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  sortedShapes.length.clamp(0, 8), // Show max 8 dots
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _currentCrownCarouselIndex ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: i == _currentCrownCarouselIndex
                          ? const Color(0xFF2D2926)
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ),
            // "Next Up" label
            if (_currentCrownCarouselIndex + 1 < sortedShapes.length)
              Padding(
                padding: const EdgeInsets.only(top: 6.0, bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'NEXT UP:  ',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                        letterSpacing: 2.0,
                      ),
                    ),
                    Text(
                      sortedShapes[_currentCrownCarouselIndex + 1].name,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        color: const Color(0xFF2D2926),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailsSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Crown', Icons.architecture),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: selectedCrownShape != null 
                      ? Image.asset(selectedCrownShape!.imagePath, fit: BoxFit.cover)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Crown Shape:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      DropdownButton<HatShapeInfo?>(
                        value: selectedCrownShape,
                        isExpanded: false,
                        isDense: true,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                        hint: const Text('Any', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        selectedItemBuilder: (BuildContext context) {
                          return <HatShapeInfo?>[null, ..._currentCrownShapes].map<Widget>((HatShapeInfo? item) {
                            return Text(
                              item?.name ?? 'Any',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            );
                          }).toList();
                        },
                        items: [
                          const DropdownMenuItem<HatShapeInfo?>(
                            value: null,
                            child: Text('Any', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          ..._currentCrownShapes.map((shape) {
                            return DropdownMenuItem<HatShapeInfo?>(
                              value: shape,
                              child: Text(shape.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() => selectedCrownShape = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildMeasurementDropdown(
            label: 'Crown Height',
            selectedItems: targetCrownHeights,
            min: 4.25,
            max: 5.0,
            onChanged: (val) => setState(() => targetCrownHeights = val),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          _buildSectionHeader('Brim', Icons.waves),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: selectedBrimShape != null 
                      ? Image.asset(selectedBrimShape!.imagePath, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Brim Shape:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      DropdownButton<HatShapeInfo?>(
                        value: selectedBrimShape,
                        isExpanded: false,
                        isDense: true,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                        hint: const Text('Any', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        selectedItemBuilder: (BuildContext context) {
                          return <HatShapeInfo?>[null, ...brimShapes].map<Widget>((HatShapeInfo? item) {
                            return Text(
                              item?.name ?? 'Any',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            );
                          }).toList();
                        },
                        items: [
                          const DropdownMenuItem<HatShapeInfo?>(
                            value: null,
                            child: Text('Any', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          ...brimShapes.map((shape) {
                            return DropdownMenuItem<HatShapeInfo?>(
                              value: shape,
                              child: Text(shape.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() => selectedBrimShape = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildDropdown(
            label: 'Brim Width',
            selectedItems: targetBrimWidths,
            items: brimWidths,
            onChanged: (val) => setState(() => targetBrimWidths = val),
          ),
          const SizedBox(height: 50), // Padding to prevent the button from covering the last item
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<String> selectedItems,
    required List<String> items,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16.0,
          runSpacing: 4.0,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: selectedItems.isEmpty,
                  onChanged: (val) {
                    if (val == true) {
                      onChanged([]);
                    }
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                GestureDetector(
                  onTap: () => onChanged([]),
                  child: const Text('Any', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            ...items.map((item) {
              final isSelected = selectedItems.contains(item);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (val) {
                      final newItems = List<String>.from(selectedItems);
                      if (val == true) {
                        newItems.add(item);
                      } else {
                        newItems.remove(item);
                      }
                      onChanged(newItems);
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  GestureDetector(
                    onTap: () {
                      final newItems = List<String>.from(selectedItems);
                      if (isSelected) {
                        newItems.remove(item);
                      } else {
                        newItems.add(item);
                      }
                      onChanged(newItems);
                    },
                    child: Text(item, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildMeasurementDropdown({
    required String label,
    required List<double> selectedItems,
    required double min,
    required double max,
    required ValueChanged<List<double>> onChanged,
  }) {
    final List<double> increments = [];
    for (double i = min; i <= max + 0.01; i += 0.25) {
      increments.add(i);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16.0,
          runSpacing: 4.0,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: selectedItems.isEmpty,
                  onChanged: (val) {
                    if (val == true) {
                      onChanged([]);
                    }
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                GestureDetector(
                  onTap: () => onChanged([]),
                  child: const Text('Any', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            ...increments.map((val) {
              final isSelected = selectedItems.contains(val);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (checked) {
                      final newItems = List<double>.from(selectedItems);
                      if (checked == true) {
                        newItems.add(val);
                      } else {
                        newItems.remove(val);
                      }
                      onChanged(newItems);
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  GestureDetector(
                    onTap: () {
                      final newItems = List<double>.from(selectedItems);
                      if (isSelected) {
                        newItems.remove(val);
                      } else {
                        newItems.add(val);
                      }
                      onChanged(newItems);
                    },
                    child: Text(formatMeasurement(val), style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }
  Widget _buildVisualBrimSelection() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int columns = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);
    final double aspect = screenWidth > 900 ? 0.8 : (screenWidth > 600 ? 0.75 : 0.65);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Select Brim Shape:',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  color: const Color(0xFF2D2926),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  setState(() => selectedBrimShape = null);
                  _nextPage(overrideValidation: true);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2D2926),
                  side: const BorderSide(color: Color(0xFF2D2926), width: 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Pill
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'ANY BRIM SHAPE',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _allProductsFuture,
            builder: (context, snapshot) {
              return GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: aspect,
                ),
                itemCount: brimShapes.length,
                itemBuilder: (context, index) {
                  final shape = brimShapes[index];
                  final isSelected = selectedBrimShape?.name == shape.name;

                  // Find matching product image
                  String? imageUrl;
                  if (snapshot.hasData) {
                    try {
                      final matchingProduct = snapshot.data!.firstWhere(
                        (p) => _metaValue(p['brimShape']).toLowerCase().contains(shape.name.toLowerCase()),
                        orElse: () => null,
                      );
                      imageUrl = matchingProduct?['featuredImage']?['url'];
                    } catch (e) {
                      print('Error finding matching image: \$e');
                    }
                  }

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    color: Colors.white,
                    elevation: isSelected ? 0 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Soft rounded
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF559C99) : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() => selectedBrimShape = shape);
                        _nextPage();
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                              child: imageUrl != null
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover, // Fill the card
                                    alignment: Alignment.center,
                                    errorBuilder: (context, error, stackTrace) => Image.asset(
                                      shape.imagePath,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.center,
                                    ),
                                  )
                                : Image.asset(
                                    shape.imagePath,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                    ),
                                  ),
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              shape.name.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: const Color(0xFF2D2926),
                                letterSpacing: 1.0,
                                fontWeight: FontWeight.w600,
                              ),
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
    );
  }
}
