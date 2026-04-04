import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/hat.dart';
import 'hat_results_screen.dart';

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
  double? targetCrownHeight;

  HatShapeInfo? selectedBrimShape;
  String? targetBrimWidth;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructionsDialog();
    });
  }

  void _showInstructionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text(
            'How to Find Your Hat',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. First, select the type of hat you are looking for (Felt, Straw, Ballcap).'),
                SizedBox(height: 8),
                Text('2. Next, select the Crown Shape you want from the visual grid.'),
                SizedBox(height: 8),
                Text('3. Tap "Next: Details" to proceed.'),
                SizedBox(height: 8),
                Text('4. Optionally, select a Crown Height, Brim Shape, or Brim Width.'),
                SizedBox(height: 8),
                Text('5. Tap "Find Hats" to search our inventory for matches!'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Close',
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
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
          crownHeight: targetCrownHeight,
          brimShape: selectedBrimShape?.name,
          brimWidth: targetBrimWidth,
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
                  color: Color(0xFFC7B08B),
                  size: 28.8, // 24 * 1.2 = 28.8
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
            FilledButton(
               onPressed: _currentPageIndex < _pages.length - 1 ? _nextPage : _submitSearch,
               style: FilledButton.styleFrom(
                 padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
              ),
              child: Text(
                _navButtonText,
                style: const TextStyle(fontSize: 18),
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
                  'Select Hat Type',
                  style: GoogleFonts.cinzel(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () {
                  setState(() => selectedHatType = null);
                  _nextPage(overrideValidation: true);
                },
                child: const Text('Any Material Type'),
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
                elevation: isSelected ? 8 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      selectedHatType = typeInfo;
                      // Reset crown selection so stale shape from a different type is cleared
                      selectedCrownShape = null;
                    });
                    // Ballcap doesn't use crown/brim — go straight to results
                    if (typeInfo.name == 'Ballcap') {
                      _submitSearch();
                    } else {
                      _nextPage();
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image at the top
                      Expanded(
                        flex: 8, // Increased from 7
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Container(
                            color: Colors.white, // Match hat image background
                            padding: const EdgeInsets.all(0.0), // Removed padding entirely for max size
                            child: typeInfo.imagePath != 'assets/images/placeholder.png'
                              ? Image.asset(
                                  typeInfo.imagePath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.category,
                                    size: 48,
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                  ),
                                )
                              : Icon(
                                 Icons.search,
                                 size: 48,
                                 color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                              ),
                          ),
                        ),
                      ),
                      // Text underneath
                      Expanded(
                        flex: 2, // Reduced from 3
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.white,
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  typeInfo.name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  typeInfo.description,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    height: 1.1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
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
                  'Select Style',
                  style: GoogleFonts.cinzel(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
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
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          width: isSelected ? 3 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  color: Colors.white,
                  child: imagePath != null
                      ? Image.asset(imagePath, fit: BoxFit.contain)
                      : Icon(
                          icon ?? Icons.style,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.white,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
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
              const Expanded(
                child: Text(
                  'Select your desired Crown Shape below to get started.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () {
                  setState(() => selectedCrownShape = null);
                  _nextPage(overrideValidation: true);
                },
                child: const Text('Any Crown'),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: aspect, // Tighter ratio on wide screens to remove white space at the bottom
      ),
      itemCount: _currentCrownShapes.length,
      itemBuilder: (context, index) {
        final shape = _currentCrownShapes[index];
        final isSelected = selectedCrownShape?.name == shape.name;

        return Card(
          clipBehavior: Clip.antiAlias,
          color: Colors.white, // Force white background to match hat images
          elevation: isSelected ? 8 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
              width: 3,
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() => selectedCrownShape = shape);
              _nextPage(); // Automatically advance to next page on selection
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
                  child: Text(
                    shape.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzel(
                      fontWeight: FontWeight.w600,
                      fontSize: 20, // Reduced from 30 to prevent overflow in grid
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0, top: 0.0),
                    child: Image.asset(
                      shape.imagePath,
                      fit: BoxFit.contain, // Changed from cover to contain to ensure full image is visible when padded
                      alignment: Alignment.topCenter, // Align image to top to remove white space below title
                      errorBuilder: (context, error, stackTrace) {
                         return Container(
                           color: Colors.grey[200],
                           child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                         );
                      },
                    ),
                  ),
                ),
                if (shape.galleryImages.isNotEmpty)
                  Builder(
                    builder: (context) {
                      final ScrollController scrollController = ScrollController();
                      return SizedBox(
                        height: 70, // Reduced from 80
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
                                            width: 70, // Reduced from 80
                                            height: 70, // Reduced from 80
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
            value: targetCrownHeight,
            min: 4.25,
            max: 5.0,
            onChanged: (val) => setState(() => targetCrownHeight = val),
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
            value: targetBrimWidth,
            items: brimWidths,
            onChanged: (val) => setState(() => targetBrimWidth = val),
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
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: DropdownButtonFormField<String?>(
        decoration: InputDecoration(
          labelText: null,
          hintText: 'Select $label (Optional)',
          hintStyle: const TextStyle(color: Colors.black54),
          filled: true,
          fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      value: value,
      dropdownColor: Theme.of(context).scaffoldBackgroundColor,
      selectedItemBuilder: (BuildContext context) {
        return [null, ...items].map<Widget>((String? item) {
          return Text(
            item ?? '$label:',
            style: const TextStyle(color: Color(0xFF2B1D14), fontWeight: FontWeight.w600),
          );
        }).toList();
      },
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text('Any', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
        ),
        ...items.map((shape) {
          return DropdownMenuItem<String?>(
            value: shape,
            child: Text(shape, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
          );
        }).toList(),
      ],
      onChanged: onChanged,
     ),
    );
  }

  Widget _buildMeasurementDropdown({
    required String label,
    required double? value,
    required double min,
    required double max,
    required ValueChanged<double?> onChanged,
  }) {
    final List<double> increments = [];
    for (double i = min; i <= max + 0.01; i += 0.25) {
      increments.add(i);
    }
    
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: DropdownButtonFormField<double?>(
        decoration: InputDecoration(
          labelText: null,
          hintText: 'Select $label (Optional)',
          hintStyle: const TextStyle(color: Colors.black54),
          filled: true,
          fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      value: value,
      dropdownColor: Theme.of(context).scaffoldBackgroundColor,
      selectedItemBuilder: (BuildContext context) {
        return [null, ...increments].map<Widget>((double? val) {
          return Text(
            val == null ? '$label:' : formatMeasurement(val),
            style: const TextStyle(color: Color(0xFF2B1D14), fontWeight: FontWeight.w600),
          );
        }).toList();
      },
      items: [
        DropdownMenuItem<double?>(
          value: null,
          child: Text('Any', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
        ),
        ...increments.map((val) {
          return DropdownMenuItem<double?>(
            value: val,
            child: Text(formatMeasurement(val), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
          );
        }).toList(),
      ],
      onChanged: onChanged,
     ),
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
              const Expanded(
                child: Text(
                  'Now, select your preferred Brim Shape.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () {
                  setState(() => selectedBrimShape = null);
                  _nextPage(overrideValidation: true);
                },
                child: const Text('Any Brim'),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
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

        return Card(
          clipBehavior: Clip.antiAlias,
          color: Colors.white,
          elevation: isSelected ? 8 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
              width: 3,
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
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
                  child: Text(
                    shape.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzel(
                      fontWeight: FontWeight.w600,
                      fontSize: 20, // Reduced from 30 to prevent overflow in grid
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0, top: 0.0),
                    child: Image.asset(
                      shape.imagePath,
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                      errorBuilder: (context, error, stackTrace) {
                         return Container(
                           color: Colors.grey[200],
                           child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                         );
                      },
                    ),
                  ),
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
          ),
        ),
      ],
    );
  }
}
