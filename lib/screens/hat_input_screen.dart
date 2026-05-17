import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/hat.dart';
import 'hat_results_screen.dart';
import 'dart:convert';
import 'dart:math' show pi;
import '../services/shopify_service.dart';

class HatInputScreen extends StatefulWidget {
  const HatInputScreen({super.key});

  @override
  State<HatInputScreen> createState() => _HatInputScreenState();
}

class _HatInputScreenState extends State<HatInputScreen> {
  final PageController _pageController = PageController();
  final PageController _crownCarouselController = PageController(viewportFraction: 0.76);
  final PageController _brimCarouselController = PageController(viewportFraction: 0.76);
  int _currentPageIndex = 0;
  int _currentCrownCarouselIndex = 0;
  int _currentBrimCarouselIndex = 0;
  int? _flippedCardIndex; // which crown card is showing history
  int? _flippedBrimCardIndex; // which brim card is showing history

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
        automaticallyImplyLeading: false,
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
                    setState(() {
                      _currentPageIndex = index;
                      _flippedCardIndex = null; // Reset flip when moving between main pages
                      _flippedBrimCardIndex = null;
                    });
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
              OutlinedButton(
                onPressed: _currentPageIndex > 0 ? _previousPage : () => Navigator.of(context).pop(),
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
                      final List<dynamic> products = snapshot.data!;
                      final Set<String> usedUrls = {};
                      
                      // Pre-process to find unique images for each style in the list
                      for (int i = 0; i < styles.length; i++) {
                        final styleName = styles[i]['name'];
                        String? foundUrl;
                        
                        if (styleName == 'Western') {
                          final westernProfiles = ['01', '1', '2', '11', '18', '33', '45', '48', '50', '72', '75', '77', '91', '94', '9G'];
                          foundUrl = products.firstWhere((p) {
                            final profile = _metaValue(p['stetsonProfile']);
                            final title = (p['title'] ?? '').toString().toLowerCase();
                            final handle = (p['handle'] ?? '').toString().toLowerCase();
                            final url = p['featuredImage']?['url'] as String?;
                            
                            // EXCLUDE OPEN ROADS from Western representative image
                            final isOpenRoad = title.contains('open road') || handle.contains('open-road');
                            
                            return westernProfiles.contains(profile) && 
                                   url != null && 
                                   !usedUrls.contains(url) && 
                                   !isOpenRoad;
                          }, orElse: () => null)?['featuredImage']?['url'];
                        } else if (styleName == 'City') {
                          foundUrl = products.firstWhere((p) {
                            final url = p['featuredImage']?['url'] as String?;
                            return _metaValue(p['city']).toLowerCase() == 'true' && 
                                   url != null && 
                                   !usedUrls.contains(url);
                          }, orElse: () => null)?['featuredImage']?['url'];
                        } else if (styleName == 'Outdoor') {
                          foundUrl = products.firstWhere((p) {
                            final url = p['featuredImage']?['url'] as String?;
                            return _metaValue(p['outdoors']).toLowerCase() == 'true' && 
                                   url != null && 
                                   !usedUrls.contains(url);
                          }, orElse: () => null)?['featuredImage']?['url'];
                        }
                        
                        if (foundUrl != null) {
                          usedUrls.add(foundUrl);
                          if (i == index) imageUrl = foundUrl;
                        }
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

  void _showShapeDetailSheet(BuildContext context, HatShapeInfo shape, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF2D2926),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      children: [
                        Text(
                          shape.name.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 3.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(width: 40, height: 2, color: const Color(0xFF559C99)),
                        const SizedBox(height: 12),
                        Text(
                          type == 'wearers' ? 'FAMOUS WEARERS' : 'THE SHAPE',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF559C99),
                            letterSpacing: 3.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Content
                  Expanded(
                    child: type == 'wearers'
                        ? _buildFamousWearersContent(shape, scrollController)
                        : _buildPhysicalDescriptionContent(shape, scrollController),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFamousWearersContent(HatShapeInfo shape, ScrollController controller) {
    if (shape.famousWearers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Famous wearers coming soon...',
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              color: Colors.white54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      itemCount: shape.famousWearers.length,
      separatorBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Divider(color: Colors.white12, height: 1),
      ),
      itemBuilder: (context, index) {
        final wearer = shape.famousWearers[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF559C99).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      wearer['name']?.substring(0, 1) ?? '?',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF559C99),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    wearer['name'] ?? '',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(
                wearer['context'] ?? '',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhysicalDescriptionContent(HatShapeInfo shape, ScrollController controller) {
    return SingleChildScrollView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF559C99).withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.straighten, color: Color(0xFF559C99), size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            shape.physicalDescription.isNotEmpty
                ? shape.physicalDescription
                : shape.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 17,
              color: Colors.white.withOpacity(0.85),
              height: 1.7,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualCrownSelection() {
    return FutureBuilder<List<dynamic>>(
      future: _allProductsFuture,
      builder: (context, snapshot) {
        List<HatShapeInfo> sortedShapes = List.from(_currentCrownShapes);
        Map<String, List<Map<String, String>>> shopifyProductsMap = {};
        
        if (snapshot.hasData) {
          try {
            for (var shape in sortedShapes) {
              final shopifyProducts = snapshot.data!
                  .where((p) {
                    final crown = _metaValue(p['crownShape']).toLowerCase();
                    final name = shape.name.toLowerCase();
                    return crown.contains(name.replaceAll("'s", "").trim()) || 
                           name.contains(crown.trim());
                  })
                  .where((p) => p['featuredImage']?['url'] != null)
                  .map((p) => {
                    'url': p['featuredImage']['url'] as String,
                    'title': (p['title'] ?? '') as String,
                  })
                  .toList();
              shopifyProductsMap[shape.name] = shopifyProducts;
            }
            
            sortedShapes.sort((a, b) {
              final aHasShopify = (shopifyProductsMap[a.name]?.isNotEmpty ?? false) ? 1 : 0;
              final bHasShopify = (shopifyProductsMap[b.name]?.isNotEmpty ?? false) ? 1 : 0;
              return bHasShopify.compareTo(aHasShopify);
            });
          } catch (e) {}
        }

        return Column(
          children: [
            // Header — minimal to maximize card space
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
              child: Text(
                'Select Crown Shape:',
                style: GoogleFonts.playfairDisplay(fontSize: 22, color: const Color(0xFF2D2926)),
              ),
            ),
            // Carousel — image fills the card edge-to-edge, with swipe hint arrows
            Expanded(
              child: Stack(
                children: [
                  PageView.builder(
                controller: _crownCarouselController,
                onPageChanged: (index) {
                  setState(() {
                    _currentCrownCarouselIndex = index;
                    _flippedCardIndex = null; // reset flip on swipe
                  });
                },
                itemCount: sortedShapes.length,
                itemBuilder: (context, index) {
                  final shape = sortedShapes[index];
                  final isSelected = selectedCrownShape?.name == shape.name;
                  final shopifyProducts = shopifyProductsMap[shape.name] ?? [];
                  final String? imageUrl = shopifyProducts.isNotEmpty ? shopifyProducts.first['url'] : null;
                  final String? productTitle = shopifyProducts.isNotEmpty ? shopifyProducts.first['title'] : null;
                  final bool isFlipped = _flippedCardIndex == index;
                  final bool isCentered = index == _currentCrownCarouselIndex;

                  return Padding(
                    padding: const EdgeInsets.only(left: 4.0, right: 4.0, top: 3.0, bottom: 20.0),
                    child: GestureDetector(
                      onTap: () {
                        if (!isCentered) {
                          // Tapped a peekaboo card — scroll to it instead of flipping
                          _crownCarouselController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                          return;
                        }
                        setState(() {
                          if (isFlipped) {
                            _flippedCardIndex = null; // flip back
                          } else {
                            _flippedCardIndex = index; // flip to history
                          }
                        });
                      },
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: isFlipped ? pi : 0),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOutCubic,
                        builder: (context, angle, _) {
                          // Determine which face to show
                          final showBack = angle > pi / 2;
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001) // perspective
                              ..rotateY(angle),
                            child: showBack
                                // ── BACK FACE (history) ──
                                ? Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()..rotateY(pi), // un-mirror text
                                    child: Card(
                                      clipBehavior: Clip.antiAlias,
                                      elevation: 0,
                                      color: const Color(0xFF2D2926),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: BorderSide(
                                          color: isSelected ? const Color(0xFF559C99) : const Color(0xFF3D3936),
                                          width: isSelected ? 3 : 1,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              shape.name.toUpperCase(),
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.montserrat(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: 3.0,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              width: 40,
                                              height: 2,
                                              color: const Color(0xFF559C99),
                                            ),
                                            const SizedBox(height: 14),
                                            Text(
                                              'THE HISTORY',
                                              style: GoogleFonts.montserrat(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF559C99),
                                                letterSpacing: 3.0,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Expanded(
                                              child: SingleChildScrollView(
                                                child: Text(
                                                  shape.history.isNotEmpty
                                                      ? shape.history
                                                      : shape.description,
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.playfairDisplay(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w400,
                                                    color: Colors.white.withOpacity(0.9),
                                                    height: 1.6,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            // ── Two info buttons ──
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    onPressed: () => _showShapeDetailSheet(context, shape, 'wearers'),
                                                    icon: const Icon(Icons.people_outline, size: 18),
                                                    label: Text(
                                                      'FAMOUS\nWEARERS',
                                                      textAlign: TextAlign.center,
                                                      style: GoogleFonts.montserrat(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: 1.5,
                                                        height: 1.3,
                                                      ),
                                                    ),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: Colors.white70,
                                                      side: const BorderSide(color: Colors.white24),
                                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    onPressed: () => _showShapeDetailSheet(context, shape, 'physical'),
                                                    icon: const Icon(Icons.straighten, size: 18),
                                                    label: Text(
                                                      'THE\nSHAPE',
                                                      textAlign: TextAlign.center,
                                                      style: GoogleFonts.montserrat(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: 1.5,
                                                        height: 1.3,
                                                      ),
                                                    ),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: Colors.white70,
                                                      side: const BorderSide(color: Colors.white24),
                                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            // ── Select button ──
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    selectedCrownShape = shape;
                                                    _flippedCardIndex = null;
                                                  });
                                                  _nextPage();
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF559C99),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(30),
                                                  ),
                                                  elevation: 0,
                                                ),
                                                child: Text(
                                                  'SELECT THIS SHAPE',
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 1.5,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'TAP TO FLIP BACK',
                                              style: GoogleFonts.montserrat(
                                                fontSize: 8,
                                                color: Colors.white30,
                                                letterSpacing: 2.0,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                // ── FRONT FACE (image) ──
                                : Card(
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
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        // Image — naturally sized to fit width, sits at top
                                        Flexible(
                                          fit: FlexFit.loose,
                                          child: Stack(
                                            children: [
                                              Transform.translate(
                                                offset: const Offset(0, -15), // Shifting hat up to reduce top dead space
                                                child: imageUrl != null
                                                    ? Image.network(imageUrl, fit: BoxFit.contain, alignment: Alignment.topCenter)
                                                    : Image.asset(shape.imagePath, fit: BoxFit.contain, alignment: Alignment.topCenter),
                                              ),
                                              // Product name overlay — subtle, below the hat
                                              if (productTitle != null && productTitle.isNotEmpty)
                                                Positioned(
                                                  bottom: 25,
                                                  left: 12,
                                                  right: 12,
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'Example:',
                                                        textAlign: TextAlign.center,
                                                        style: GoogleFonts.montserrat(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.grey[600],
                                                          letterSpacing: 1.5,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        productTitle,
                                                        textAlign: TextAlign.center,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: GoogleFonts.cormorantGaramond(
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.w600,
                                                          color: const Color(0xFF6B6058),
                                                          fontStyle: FontStyle.italic,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        // Label + description — pulled up tight under the hat
                                        Transform.translate(
                                          offset: const Offset(0, -16),
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                                            child: Column(
                                              children: [
                                                Text(
                                                  shape.name.toUpperCase(),
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w800,
                                                    color: const Color(0xFF2D2926),
                                                    letterSpacing: 1.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  shape.description,
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.3),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
                  // Left arrow — subtle swipe hint
                  if (_currentCrownCarouselIndex > 0)
                    Positioned(
                      left: 2,
                      top: 0,
                      bottom: 20,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            _crownCarouselController.previousPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.7),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Right arrow — subtle swipe hint
                  if (_currentCrownCarouselIndex < sortedShapes.length - 1)
                    Positioned(
                      right: 2,
                      top: 0,
                      bottom: 20,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            _crownCarouselController.nextPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.7),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Dots — hugging the bottom of the card
            Padding(
              padding: const EdgeInsets.only(top: 2.0, bottom: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  sortedShapes.length.clamp(0, 8),
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
            // Next Up + Skip — centered layout
            Padding(
              padding: const EdgeInsets.only(top: 6.0, bottom: 10.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    // Left spacer — matches SKIP width for centering
                    const SizedBox(width: 50),
                    // Center: Next Up label + hat name
                    Expanded(
                      child: (_currentCrownCarouselIndex + 1 < sortedShapes.length)
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  'NEXT UP: ',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[500],
                                    letterSpacing: 1.8,
                                  ),
                                ),
                                Text(
                                  sortedShapes[_currentCrownCarouselIndex + 1].name,
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2D2926),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox(),
                    ),
                    // Right: Skip
                    SizedBox(
                      width: 50,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => selectedCrownShape = null);
                          _nextPage(overrideValidation: true);
                        },
                        child: Text(
                          'SKIP',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF559C99),
                            letterSpacing: 1.8,
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFF559C99),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
                        value: _currentCrownShapes.contains(selectedCrownShape) ? selectedCrownShape : null,
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
                        value: brimShapes.contains(selectedBrimShape) ? selectedBrimShape : null,
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
    return FutureBuilder<List<dynamic>>(
      future: _allProductsFuture,
      builder: (context, snapshot) {
        List<HatShapeInfo> sortedShapes = List.from(brimShapes);
        Map<String, List<Map<String, String>>> shopifyProductsMap = {};

        if (snapshot.hasData) {
          try {
            for (var shape in sortedShapes) {
              final shopifyProducts = snapshot.data!
                  .where((p) {
                    final brimRaw = _metaValue(p['brimShape']).toLowerCase().trim();
                    final shapeName = shape.name.toLowerCase().trim();
                    if (brimRaw.isEmpty) return false;
                    // Exact match first
                    if (brimRaw == shapeName) return true;
                    // Normalize: strip "curl", "shape", apostrophes for fuzzy matching
                    final brimNorm = brimRaw.replaceAll(' curl', '').replaceAll("'s", '').replaceAll("'", '').trim();
                    final nameNorm = shapeName.replaceAll(' curl', '').replaceAll("'s", '').replaceAll("'", '').trim();
                    return brimNorm == nameNorm ||
                           brimRaw.contains(nameNorm) ||
                           nameNorm.contains(brimNorm);
                  })
                  .where((p) => p['featuredImage']?['url'] != null)
                  .map((p) => {
                    'url': p['featuredImage']['url'] as String,
                    'title': (p['title'] ?? '') as String,
                  })
                  .toList();
              shopifyProductsMap[shape.name] = shopifyProducts;
            }

            sortedShapes.sort((a, b) {
              final aHasShopify = (shopifyProductsMap[a.name]?.isNotEmpty ?? false) ? 1 : 0;
              final bHasShopify = (shopifyProductsMap[b.name]?.isNotEmpty ?? false) ? 1 : 0;
              return bHasShopify.compareTo(aHasShopify);
            });
          } catch (e) {}
        }

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
              child: Text(
                'Select Brim Shape:',
                style: GoogleFonts.playfairDisplay(fontSize: 22, color: const Color(0xFF2D2926)),
              ),
            ),
            // Carousel with swipe arrows
            Expanded(
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _brimCarouselController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentBrimCarouselIndex = index;
                        _flippedBrimCardIndex = null;
                      });
                    },
                    itemCount: sortedShapes.length,
                    itemBuilder: (context, index) {
                      final shape = sortedShapes[index];
                      final isSelected = selectedBrimShape?.name == shape.name;
                      final shopifyProducts = shopifyProductsMap[shape.name] ?? [];
                      final String? imageUrl = shopifyProducts.isNotEmpty ? shopifyProducts.first['url'] : null;
                      final String? productTitle = shopifyProducts.isNotEmpty ? shopifyProducts.first['title'] : null;
                      final bool isFlipped = _flippedBrimCardIndex == index;
                      final bool isCentered = index == _currentBrimCarouselIndex;

                      return Padding(
                        padding: const EdgeInsets.only(left: 4.0, right: 4.0, top: 3.0, bottom: 20.0),
                        child: GestureDetector(
                          onTap: () {
                            if (!isCentered) {
                              _brimCarouselController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut,
                              );
                              return;
                            }
                            setState(() {
                              if (isFlipped) {
                                _flippedBrimCardIndex = null;
                              } else {
                                _flippedBrimCardIndex = index;
                              }
                            });
                          },
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: isFlipped ? pi : 0),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOutCubic,
                            builder: (context, angle, _) {
                              final showBack = angle > pi / 2;
                              return Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateY(angle),
                                child: showBack
                                    // ── BACK FACE (history) ──
                                    ? Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()..rotateY(pi),
                                        child: Card(
                                          clipBehavior: Clip.antiAlias,
                                          elevation: 0,
                                          color: const Color(0xFF2D2926),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                            side: BorderSide(
                                              color: isSelected ? const Color(0xFF559C99) : const Color(0xFF3D3936),
                                              width: isSelected ? 3 : 1,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  shape.name.toUpperCase(),
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                    letterSpacing: 3.0,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Container(
                                                  width: 40,
                                                  height: 2,
                                                  color: const Color(0xFF559C99),
                                                ),
                                                const SizedBox(height: 14),
                                                Text(
                                                  'THE HISTORY',
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF559C99),
                                                    letterSpacing: 3.0,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Expanded(
                                                  child: SingleChildScrollView(
                                                    child: Text(
                                                      shape.history.isNotEmpty
                                                          ? shape.history
                                                          : shape.description,
                                                      textAlign: TextAlign.center,
                                                      style: GoogleFonts.playfairDisplay(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w400,
                                                        color: Colors.white.withOpacity(0.9),
                                                        height: 1.6,
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                // ── Two info buttons ──
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: OutlinedButton.icon(
                                                        onPressed: () => _showShapeDetailSheet(context, shape, 'wearers'),
                                                        icon: const Icon(Icons.people_outline, size: 18),
                                                        label: Text(
                                                          'FAMOUS\nWEARERS',
                                                          textAlign: TextAlign.center,
                                                          style: GoogleFonts.montserrat(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w700,
                                                            letterSpacing: 1.5,
                                                            height: 1.3,
                                                          ),
                                                        ),
                                                        style: OutlinedButton.styleFrom(
                                                          foregroundColor: Colors.white70,
                                                          side: const BorderSide(color: Colors.white24),
                                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: OutlinedButton.icon(
                                                        onPressed: () => _showShapeDetailSheet(context, shape, 'physical'),
                                                        icon: const Icon(Icons.straighten, size: 18),
                                                        label: Text(
                                                          'THE\nSHAPE',
                                                          textAlign: TextAlign.center,
                                                          style: GoogleFonts.montserrat(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w700,
                                                            letterSpacing: 1.5,
                                                            height: 1.3,
                                                          ),
                                                        ),
                                                        style: OutlinedButton.styleFrom(
                                                          foregroundColor: Colors.white70,
                                                          side: const BorderSide(color: Colors.white24),
                                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                // ── Select button ──
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        selectedBrimShape = shape;
                                                        _flippedBrimCardIndex = null;
                                                      });
                                                      _nextPage();
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFF559C99),
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(30),
                                                      ),
                                                      elevation: 0,
                                                    ),
                                                    child: Text(
                                                      'SELECT THIS SHAPE',
                                                      style: GoogleFonts.montserrat(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: 1.5,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'TAP TO FLIP BACK',
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 8,
                                                    color: Colors.white30,
                                                    letterSpacing: 2.0,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                    // ── FRONT FACE (image) ──
                                    : Card(
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
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            // Image with product name overlay
                                            Flexible(
                                              fit: FlexFit.loose,
                                              child: Stack(
                                                children: [
                                                  Transform.translate(
                                                    offset: const Offset(0, -15),
                                                    child: imageUrl != null
                                                        ? Image.network(imageUrl, fit: BoxFit.contain, alignment: Alignment.topCenter)
                                                        : Container(
                                                            color: Colors.grey[100],
                                                            child: const Center(child: Icon(Icons.straighten, size: 60, color: Color(0xFFD0C8C0))),
                                                          ),
                                                  ),
                                                  // Product name overlay
                                                  if (productTitle != null && productTitle.isNotEmpty)
                                                    Positioned(
                                                      bottom: 25,
                                                      left: 12,
                                                      right: 12,
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            'Example:',
                                                            textAlign: TextAlign.center,
                                                            style: GoogleFonts.montserrat(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w600,
                                                              color: Colors.grey[600],
                                                              letterSpacing: 1.5,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            productTitle,
                                                            textAlign: TextAlign.center,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: GoogleFonts.cormorantGaramond(
                                                              fontSize: 20,
                                                              fontWeight: FontWeight.w600,
                                                              color: const Color(0xFF6B6058),
                                                              fontStyle: FontStyle.italic,
                                                              letterSpacing: 0.5,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            // Label + description
                                            Transform.translate(
                                              offset: const Offset(0, -16),
                                              child: Padding(
                                                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      shape.name.toUpperCase(),
                                                      textAlign: TextAlign.center,
                                                      style: GoogleFonts.montserrat(
                                                        fontSize: 24,
                                                        fontWeight: FontWeight.w800,
                                                        color: const Color(0xFF2D2926),
                                                        letterSpacing: 1.5,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      shape.description,
                                                      textAlign: TextAlign.center,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.3),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  // Left arrow
                  if (_currentBrimCarouselIndex > 0)
                    Positioned(
                      left: 2, top: 0, bottom: 20,
                      child: Center(
                        child: GestureDetector(
                          onTap: () => _brimCarouselController.previousPage(
                            duration: const Duration(milliseconds: 350), curve: Curves.easeInOut),
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.7),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))],
                            ),
                            child: Icon(Icons.chevron_left_rounded, size: 18, color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    ),
                  // Right arrow
                  if (_currentBrimCarouselIndex < sortedShapes.length - 1)
                    Positioned(
                      right: 2, top: 0, bottom: 20,
                      child: Center(
                        child: GestureDetector(
                          onTap: () => _brimCarouselController.nextPage(
                            duration: const Duration(milliseconds: 350), curve: Curves.easeInOut),
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.7),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))],
                            ),
                            child: Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Dots
            Padding(
              padding: const EdgeInsets.only(top: 2.0, bottom: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  sortedShapes.length.clamp(0, 9),
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _currentBrimCarouselIndex ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: i == _currentBrimCarouselIndex ? const Color(0xFF2D2926) : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ),
            // Next Up + Skip — centered layout
            Padding(
              padding: const EdgeInsets.only(top: 6.0, bottom: 10.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    const SizedBox(width: 50),
                    Expanded(
                      child: (_currentBrimCarouselIndex + 1 < sortedShapes.length)
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  'NEXT UP: ',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12, fontWeight: FontWeight.w600,
                                    color: Colors.grey[500], letterSpacing: 1.8,
                                  ),
                                ),
                                Text(
                                  sortedShapes[_currentBrimCarouselIndex + 1].name,
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 20, fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2D2926), fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox(),
                    ),
                    SizedBox(
                      width: 50,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => selectedBrimShape = null);
                          _nextPage(overrideValidation: true);
                        },
                        child: Text(
                          'SKIP',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.montserrat(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: const Color(0xFF559C99), letterSpacing: 1.8,
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFF559C99),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
