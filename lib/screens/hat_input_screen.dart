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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a Hat Type first.')),
        );
        return;
      }
      bool hasWestern = (selectedHatType?.name == 'Felt' || selectedHatType?.name == 'Straw');
      int westernIndex = hasWestern ? 1 : -1;
      int crownIndex = hasWestern ? 2 : 1;
      int brimIndex = hasWestern ? 3 : 2;

      if (_currentPageIndex == westernIndex && selectedWesternStyle == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a Style first.')),
        );
        return;
      }
      if (_currentPageIndex == crownIndex && selectedCrownShape == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a Crown Shape first.')),
        );
        return;
      }
      if (_currentPageIndex == brimIndex && selectedBrimShape == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a Brim Shape first.')),
        );
        return;
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
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo.png', 
          height: _currentPageIndex > 0 ? 55.2 : 46.0, // Increased by 15%
          color: _currentPageIndex > 0 ? const Color(0xFFC7B08B) : null,
        ),
        centerTitle: true,
        leading: _currentPageIndex > 0
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back, 
                  color: Color(0xFFA88467),
                  size: 28.8,
                ),
                onPressed: _previousPage,
              )
            : null,
      ),
      body: SafeArea(
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
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: (_currentPageIndex + 1) / _pages.length.toDouble(),
      backgroundColor: Colors.grey[200],
      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA88467)),
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
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color(0xFF312110),
        border: Border(
          top: BorderSide(color: const Color(0xFFA88467).withOpacity(0.2)),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
               onPressed: _currentPageIndex < _pages.length - 1 ? _nextPage : _submitSearch,
               style: FilledButton.styleFrom(
                 backgroundColor: const Color(0xFFA88467),
                 foregroundColor: Colors.white,
                 padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 60),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
              ),
              child: Text(
                _navButtonText.toUpperCase(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2.0),
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
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'SELECT MATERIAL',
                  style: GoogleFonts.tenorSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2.5,
                    color: const Color(0xFFA88467),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  setState(() => selectedHatType = null);
                  _nextPage(overrideValidation: true);
                },
                child: const Text('SKIPS TO ALL →', style: TextStyle(color: Color(0xFFA88467), letterSpacing: 1.5)),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Choose a material or start a general search.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: aspect,
            ),
            itemCount: hatTypes.length,
            itemBuilder: (context, index) {
              final typeInfo = hatTypes[index];
              final isSelected = selectedHatType == typeInfo;

              return Card(
                elevation: 0,
                color: const Color(0xFF312110),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFFA88467) : const Color(0xFFA88467).withOpacity(0.1),
                    width: isSelected ? 2 : 1,
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
                        flex: 8,
                        child: Container(
                          color: Colors.white.withOpacity(0.05),
                          child: typeInfo.imagePath != 'assets/images/placeholder.png'
                            ? Image.asset(
                                typeInfo.imagePath,
                                fit: BoxFit.contain,
                              )
                            : const Icon(Icons.search, size: 48, color: Color(0xFFA88467)),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                typeInfo.name.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.tenorSans(
                                  fontWeight: FontWeight.w400,
                                  color: isSelected ? const Color(0xFFA88467) : const Color(0xFFE8D9C8),
                                  fontSize: 16,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                typeInfo.description,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lora(
                                  fontSize: 11,
                                  color: const Color(0xFFE8D9C8).withOpacity(0.6),
                                  height: 1.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
      ],
    );
  }

  Widget _buildVisualWesternSelection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'SELECT HERITAGE',
                  style: GoogleFonts.tenorSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2.5,
                    color: const Color(0xFFA88467),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Choose between a traditional Western look or other styles.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : (MediaQuery.of(context).size.width < 400 ? 1 : 2),
            padding: const EdgeInsets.all(16),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: MediaQuery.of(context).size.width > 700 ? 1.1 : (MediaQuery.of(context).size.width < 400 ? 1.4 : 0.75),
            children: [
              _buildStyleCard('Western', 'Classic cowboy and western styles.', imagePath: 'assets/images/western.jpg'),
              _buildStyleCard('Not Western', 'Fedoras, trilbys, and other dress hats.', imagePath: 'assets/images/not_western.jpg'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStyleCard(String name, String description, {String? imagePath, IconData? icon}) {
    final isSelected = selectedWesternStyle == name;
    return Card(
      elevation: 0,
      color: const Color(0xFF312110),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: BorderSide(
          color: isSelected ? const Color(0xFFA88467) : const Color(0xFFA88467).withOpacity(0.1),
          width: isSelected ? 2 : 1,
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
              flex: 8,
              child: Container(
                color: Colors.white.withOpacity(0.05),
                child: imagePath != null
                    ? Image.asset(imagePath, fit: BoxFit.cover)
                    : Icon(
                        icon ?? Icons.style,
                        size: 48,
                        color: const Color(0xFFA88467),
                      ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name.toUpperCase(),
                      style: GoogleFonts.tenorSans(
                        fontWeight: FontWeight.w400,
                        color: isSelected ? const Color(0xFFA88467) : const Color(0xFFE8D9C8),
                        fontSize: 16,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontSize: 11,
                        color: const Color(0xFFE8D9C8).withOpacity(0.6),
                      ),
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

  Widget _buildVisualCrownSelection() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int columns = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);
    final double aspect = screenWidth > 900 ? 0.8 : (screenWidth > 600 ? 0.75 : 0.55);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'SELECT CROWN',
                  style: GoogleFonts.tenorSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2.5,
                    color: const Color(0xFFA88467),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  setState(() => selectedCrownShape = null);
                  _nextPage(overrideValidation: true);
                },
                child: const Text('ANY SHAPE →', style: TextStyle(color: Color(0xFFA88467), letterSpacing: 1.5)),
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
                    color: const Color(0xFF312110),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFA88467) : const Color(0xFFA88467).withOpacity(0.1),
                        width: isSelected ? 2 : 1,
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
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            child: Text(
                              shape.name.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.tenorSans(
                                fontWeight: FontWeight.w400,
                                fontSize: 18,
                                letterSpacing: 1.5,
                                color: isSelected ? const Color(0xFFA88467) : const Color(0xFFE8D9C8),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0, top: 0.0),
                              child: imageUrl != null
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.topCenter,
                                    errorBuilder: (context, error, stackTrace) => Image.asset(
                                      shape.imagePath,
                                      fit: BoxFit.contain,
                                      alignment: Alignment.topCenter,
                                    ),
                                  )
                                : Image.asset(
                                    shape.imagePath,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.topCenter,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                    ),
                                  ),
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
        ),
      ],
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
          Icon(icon, color: const Color(0xFFA88467)),
          const SizedBox(width: 12),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.tenorSans(
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFA88467),
                  letterSpacing: 2.0,
                  fontSize: 20,
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
                  activeColor: const Color(0xFFA88467),
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
                    activeColor: const Color(0xFFA88467),
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
                  activeColor: const Color(0xFFA88467),
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
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'SELECT BRIM',
                  style: GoogleFonts.tenorSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2.5,
                    color: const Color(0xFFA88467),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  setState(() => selectedBrimShape = null);
                  _nextPage(overrideValidation: true);
                },
                child: const Text('ANY SHAPE →', style: TextStyle(color: Color(0xFFA88467), letterSpacing: 1.5)),
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
                    color: const Color(0xFF312110),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFA88467) : const Color(0xFFA88467).withOpacity(0.1),
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
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            child: Text(
                              shape.name.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.tenorSans(
                                fontWeight: FontWeight.w400,
                                fontSize: 18,
                                letterSpacing: 1.5,
                                color: isSelected ? const Color(0xFFA88467) : const Color(0xFFE8D9C8),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: imageUrl != null
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.topCenter,
                                    errorBuilder: (context, error, stackTrace) => Image.asset(
                                      shape.imagePath,
                                      fit: BoxFit.contain,
                                      alignment: Alignment.topCenter,
                                    ),
                                  )
                                : Image.asset(
                                    shape.imagePath,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.topCenter,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.only(bottom: 16, left: 12, right: 12),
                            child: Text(
                              shape.description,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lora(
                                fontSize: 12,
                                color: const Color(0xFFE8D9C8).withOpacity(0.6),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
