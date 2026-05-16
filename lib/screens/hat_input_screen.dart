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
  int _currentPageIndex = 0;

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
              'assets/images/logo.png', 
              height: 55.0, // Made bigger
              color: const Color(0xFFCBB593), // Color from the front page (Home Screen)
            ),
            const SizedBox(height: 2),
            Text(
              'HAT FINDER',
              style: GoogleFonts.playfairDisplaySc(
                fontSize: 16, // Made bigger
                color: const Color(0xFFCBB593),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
        leading: _currentPageIndex > 0
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back, 
                  color: Color(0xFFC7B08B),
                  size: 28.8, // 24 * 1.2 = 28.8
                ),
                onPressed: _previousPage,
              )
            : null,
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
      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
               onPressed: _currentPageIndex < _pages.length - 1 ? _nextPage : _submitSearch,
               style: TextButton.styleFrom(
                 padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                 foregroundColor: Colors.white, // White text and icon
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _navButtonText.toUpperCase(),
                    style: GoogleFonts.playfairDisplaySc(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    size: 24,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualHatTypeSelection() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int columns = screenWidth > 700 ? 4 : (screenWidth < 400 ? 1 : 2);
    final double aspect = screenWidth > 700 ? 1.1 : (screenWidth < 400 ? 1.4 : 0.75);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Select a Material:',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplaySc(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF5F0E8),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  setState(() => selectedHatType = null);
                  _nextPage(overrideValidation: true);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFCBB593),
                  side: const BorderSide(color: Color(0xFFCBB593), width: 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2), // Sharp corners
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'ANY MATERIAL TYPE',
                  style: GoogleFonts.playfairDisplaySc(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: aspect,
                          child: _buildHatTypeCard(hatTypes[0]),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: aspect,
                          child: _buildHatTypeCard(hatTypes[1]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: (screenWidth - 48) / 2,
                        child: AspectRatio(
                          aspectRatio: aspect,
                          child: _buildHatTypeCard(hatTypes[2]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHatTypeCard(HatShapeInfo typeInfo) {
    final isSelected = selectedHatType == typeInfo;
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2), // Sharp corners
        side: BorderSide(
          color: isSelected ? const Color(0xFFCBB593) : Colors.transparent,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(2),
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
            // Full-bleed Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2)),
                child: typeInfo.imagePath != 'assets/images/placeholder.png'
                    ? Image.asset(
                        typeInfo.imagePath,
                        fit: BoxFit.cover, // Fill the card
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.white,
                          child: const Icon(Icons.category, size: 48, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.white,
                        child: const Icon(Icons.search, size: 48, color: Colors.grey),
                      ),
              ),
            ),
            // Text at the bottom
            Container(
              color: const Color(0xFF2B1D14),
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                typeInfo.name.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.tenorSans(
                  fontSize: 16,
                  color: const Color(0xFFCBB593),
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualWesternSelection() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int columns = screenWidth > 700 ? 4 : (screenWidth < 400 ? 1 : 2);
    final double aspect = screenWidth > 700 ? 1.1 : (screenWidth < 400 ? 1.4 : 0.75);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Select Style:',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplaySc(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF5F0E8),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  setState(() => selectedWesternStyle = null);
                  _nextPage(overrideValidation: true);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFCBB593),
                  side: const BorderSide(color: Color(0xFFCBB593), width: 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2), // Sharp corners
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'ANY STYLE',
                  style: GoogleFonts.playfairDisplaySc(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _allProductsFuture,
            builder: (context, snapshot) {
              String? westernImageUrl;
              String? cityImageUrl;
              String? outdoorImageUrl;

              if (snapshot.hasData) {
                final Set<String> usedUrls = {};
                final List<String> westernProfiles = ['01', '1', '2', '11', '18', '33', '45', '48', '50', '72', '75', '77', '91', '94', '9G'];
                
                try {
                  westernImageUrl = snapshot.data!.firstWhere((p) {
                    final profile = _metaValue(p['stetsonProfile']);
                    final url = p['featuredImage']?['url'];
                    final title = (p['title'] ?? '').toString().toLowerCase();
                    return westernProfiles.contains(profile) && 
                           url != null && 
                           !usedUrls.contains(url) &&
                           !title.contains('open road');
                  }, orElse: () => null)?['featuredImage']?['url'];
                  if (westernImageUrl != null) usedUrls.add(westernImageUrl!);
                } catch (_) {}

                try {
                  cityImageUrl = snapshot.data!.firstWhere((p) {
                    final isCity = _metaValue(p['city']).toLowerCase();
                    final url = p['featuredImage']?['url'];
                    return isCity == 'true' && url != null && !usedUrls.contains(url);
                  }, orElse: () => null)?['featuredImage']?['url'];
                  if (cityImageUrl != null) usedUrls.add(cityImageUrl!);
                } catch (_) {}

                try {
                  outdoorImageUrl = snapshot.data!.firstWhere((p) {
                    final isOutdoor = _metaValue(p['outdoors']).toLowerCase();
                    final url = p['featuredImage']?['url'];
                    return isOutdoor == 'true' && url != null && !usedUrls.contains(url);
                  }, orElse: () => null)?['featuredImage']?['url'];
                  if (outdoorImageUrl != null) usedUrls.add(outdoorImageUrl!);
                } catch (_) {}
              }

              return GridView.count(
                crossAxisCount: columns,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildStyleCard('Western', 'Classic cowboy and western styles.', fallbackImagePath: 'assets/images/western.jpg', imageUrl: westernImageUrl),
                  _buildStyleCard('City', 'Fedoras, trilbys, and other dress hats.', fallbackImagePath: 'assets/images/city.png', imageUrl: cityImageUrl),
                  _buildStyleCard('Outdoor', 'Sun hats, safari hats, and adventure gear.', fallbackImagePath: 'assets/images/outdoor.png', imageUrl: outdoorImageUrl),
                ],
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
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2), // Sharp corners
        side: BorderSide(
          color: isSelected ? const Color(0xFFCBB593) : Colors.transparent,
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
              color: const Color(0xFF2B1D14),
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                name.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.tenorSans(
                  fontSize: 16,
                  color: const Color(0xFFCBB593),
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final int columns = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);
    final double aspect = screenWidth > 900 ? 0.8 : (screenWidth > 600 ? 0.75 : 0.55);

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Select Crown Shape:',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplaySc(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF5F0E8),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    setState(() => selectedCrownShape = null);
                    _nextPage(overrideValidation: true);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFCBB593),
                    side: const BorderSide(color: Color(0xFFCBB593), width: 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2), // Sharp corners
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    'ANY CROWN SHAPE',
                    style: GoogleFonts.playfairDisplaySc(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<List<dynamic>>(
            future: _allProductsFuture,
            builder: (context, snapshot) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: aspect,
                ),
                itemCount: _currentCrownShapes.length,
                itemBuilder: (context, index) {
                  final shape = _currentCrownShapes[index];
                  final isSelected = selectedCrownShape?.name == shape.name;

                  // Find matching product image
                  String? imageUrl;
                  if (snapshot.hasData) {
                    try {
                      final matchingProduct = snapshot.data!.firstWhere(
                        (p) => _metaValue(p['crownShape']).toLowerCase().contains(shape.name.toLowerCase()),
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
                    elevation: isSelected ? 4 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2), // Sharp corners for luxury feel
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFCBB593) : Colors.transparent,
                        width: 2,
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
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Full-bleed Image
                                imageUrl != null
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
                                // Dark Overlay for readability
                                Container(
                                  color: Colors.black.withOpacity(0.3), // Soft dark overlay
                                ),
                                // Text on top
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      shape.name.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.tenorSans(
                                        fontSize: 22,
                                        color: Colors.white,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (shape.galleryImages.isNotEmpty)
                            Builder(
                              builder: (context) {
                                final ScrollController scrollController = ScrollController();
                                return SizedBox(
                                  height: 70,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.chevron_left),
                                        onPressed: () {
                                          scrollController.animateTo(
                                            scrollController.offset - 100,
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                      ),
                                      Expanded(
                                        child: ListView.builder(
                                          controller: scrollController,
                                          scrollDirection: Axis.horizontal,
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          itemCount: shape.galleryImages.length,
                                          itemBuilder: (context, galleryIndex) {
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 8.0),
                                              child: GestureDetector(
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return Dialog(
                                                        backgroundColor: Colors.transparent,
                                                        insetPadding: const EdgeInsets.all(16),
                                                        child: Stack(
                                                          alignment: Alignment.center,
                                                          children: [
                                                            InteractiveViewer(
                                                              panEnabled: true,
                                                              minScale: 0.5,
                                                              maxScale: 4,
                                                              child: Image.asset(
                                                                shape.galleryImages[galleryIndex],
                                                                fit: BoxFit.contain,
                                                                errorBuilder: (context, error, stackTrace) => Container(
                                                                  color: Colors.white,
                                                                  child: const Padding(
                                                                    padding: EdgeInsets.all(32.0),
                                                                    child: Icon(Icons.image, size: 100, color: Colors.grey),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            Positioned(
                                                              top: 8,
                                                              right: 8,
                                                              child: Container(
                                                                decoration: const BoxDecoration(
                                                                  color: Colors.black54,
                                                                  shape: BoxShape.circle,
                                                                ),
                                                                child: IconButton(
                                                                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                                                  onPressed: () {
                                                                    Navigator.of(context).pop();
                                                                  },
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.asset(
                                                    shape.galleryImages[galleryIndex],
                                                    width: 70,
                                                    height: 70,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => Container(
                                                      width: 80,
                                                      height: 80,
                                                      color: Colors.grey[200],
                                                      child: const Icon(Icons.image, size: 30, color: Colors.grey),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_right),
                                        onPressed: () {
                                          scrollController.animateTo(
                                            scrollController.offset + 100,
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }
                            ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
                            color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
                            child: Text(
                              shape.description,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.8) 
                                    : Colors.black54,
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
        ],
      ),
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
                style: GoogleFonts.playfairDisplaySc(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF5F0E8),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  setState(() => selectedBrimShape = null);
                  _nextPage(overrideValidation: true);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFCBB593),
                  side: const BorderSide(color: Color(0xFFCBB593), width: 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2), // Sharp corners
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'ANY BRIM SHAPE',
                  style: GoogleFonts.playfairDisplaySc(
                    fontSize: 14,
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
                    elevation: isSelected ? 4 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2), // Sharp corners
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFCBB593) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() => selectedBrimShape = shape);
                        _nextPage();
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Full-bleed Image
                          imageUrl != null
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
                          // Dark Overlay for readability
                          Container(
                            color: Colors.black.withOpacity(0.3), // Soft dark overlay
                          ),
                          // Text on top
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                shape.name.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.tenorSans(
                                  fontSize: 22,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
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
