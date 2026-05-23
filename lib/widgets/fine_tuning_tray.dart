import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/hat.dart';

class FineTuningValues {
  const FineTuningValues({
    this.hatType,
    this.crownShape,
    this.brimShape,
    this.crownHeights = const [],
    this.brimWidths = const [],
  });

  final String? hatType;
  final String? crownShape;
  final String? brimShape;
  final List<double> crownHeights;
  final List<String> brimWidths;
}

/// Expandable tray for hat type, crown/brim shape, and measurement filters.
class FineTuningTray extends StatefulWidget {
  const FineTuningTray({
    super.key,
    required this.expanded,
    required this.onExpandedChanged,
    required this.hatType,
    required this.crownShape,
    required this.brimShape,
    required this.crownHeights,
    required this.brimWidths,
    required this.onChanged,
    this.hatTypeOptions = hatTypes,
    this.crownShapeOptions = crownShapes,
    this.brimShapeOptions = brimShapes,
    this.crownHeightOptions,
  });

  final List<double>? crownHeightOptions;

  List<double> get _resolvedCrownHeightOptions =>
      crownHeightOptions ?? defaultCrownHeightOptions();

  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final String? hatType;
  final String? crownShape;
  final String? brimShape;
  final List<double> crownHeights;
  final List<String> brimWidths;
  final ValueChanged<FineTuningValues> onChanged;
  final List<HatShapeInfo> hatTypeOptions;
  final List<HatShapeInfo> crownShapeOptions;
  final List<HatShapeInfo> brimShapeOptions;

  @override
  State<FineTuningTray> createState() => _FineTuningTrayState();
}

class _FineTuningTrayState extends State<FineTuningTray> {
  static const Color _espresso = Color(0xFF2D2926);
  static const Color _turquoise = Color(0xFF559C99);
  static const Color _surface = Color(0xFFF8F7F5);
  static const Color _border = Color(0xFFE8E5E1);
  static const double _panelMaxHeight = 300;

  final ScrollController _scrollController = ScrollController();
  bool _showScrollHint = false;

  TextStyle get _sheetTitleStyle => GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: _espresso,
      );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollHint);
  }

  @override
  void didUpdateWidget(covariant FineTuningTray oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded && !oldWidget.expanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollHint());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollHint() {
    if (!widget.expanded || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final canScroll = position.maxScrollExtent > 8;
    final notAtBottom = position.pixels < position.maxScrollExtent - 8;
    final show = canScroll && notAtBottom;
    if (show != _showScrollHint) {
      setState(() => _showScrollHint = show);
    }
  }

  void _emit({
    String? type,
    String? crown,
    String? brim,
    List<double>? heights,
    List<String>? widths,
  }) {
    widget.onChanged(
      FineTuningValues(
        hatType: type ?? widget.hatType,
        crownShape: crown ?? widget.crownShape,
        brimShape: brim ?? widget.brimShape,
        crownHeights: heights ?? widget.crownHeights,
        brimWidths: widths ?? widget.brimWidths,
      ),
    );
  }

  Future<void> _pickOption(
    BuildContext context, {
    required String title,
    required String? current,
    required List<HatShapeInfo> options,
    required ValueChanged<String?> onSelect,
  }) async {
    final picked = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: _sheetTitleStyle,
                    ),
                  ),
                  const Divider(height: 1, color: _border),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                      children: [
                        _sheetTile(
                          label: 'Any',
                          selected: current == null,
                          onTap: () => Navigator.pop(context, null),
                        ),
                        ...options.map(
                          (shape) => _sheetTile(
                            label: shape.name,
                            selected: current == shape.name,
                            onTap: () =>
                                Navigator.pop(context, shape.name),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (picked != current) onSelect(picked);
  }

  Widget _sheetTile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: selected ? _turquoise.withValues(alpha: 0.08) : null,
      leading: Icon(
        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
        color: selected ? _turquoise : Colors.grey.shade400,
      ),
      title: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: _espresso,
        ),
      ),
    );
  }

  Widget _scrollMoreHint() {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.92),
                    Colors.white,
                  ],
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 6),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: _espresso.withValues(alpha: 0.28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _expandedPanel(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: _panelMaxHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _espresso.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('Type', Icons.category_outlined),
                const SizedBox(height: 10),
                _shapeSelectorRow(
                  context,
                  label: 'Hat type',
                  value: widget.hatType ?? 'Any',
                  onTap: () => _pickOption(
                    context,
                    title: 'Hat type',
                    current: widget.hatType,
                    options: widget.hatTypeOptions,
                    onSelect: (v) => _emit(type: v),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Divider(height: 1, color: _border),
                ),
                _sectionLabel('Crown', Icons.architecture_outlined),
                const SizedBox(height: 10),
                _shapeSelectorRow(
                  context,
                  label: 'Shape',
                  value: widget.crownShape ?? 'Any',
                  onTap: () => _pickOption(
                    context,
                    title: 'Crown shape',
                    current: widget.crownShape,
                    options: widget.crownShapeOptions,
                    onSelect: (v) => _emit(crown: v),
                  ),
                ),
                const SizedBox(height: 16),
                _multiCheckboxSection<double>(
                  label: 'Height',
                  anySelected: widget.crownHeights.isEmpty,
                  onAny: () => _emit(heights: []),
                  options: widget._resolvedCrownHeightOptions,
                  isSelected: (v) => widget.crownHeights.contains(v),
                  labelFor: formatMeasurement,
                  onToggle: (v) {
                    final next = List<double>.from(widget.crownHeights);
                    if (next.contains(v)) {
                      next.remove(v);
                    } else {
                      next.add(v);
                    }
                    _emit(heights: next);
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Divider(height: 1, color: _border),
                ),
                _sectionLabel('Brim', Icons.waves_outlined),
                const SizedBox(height: 10),
                _shapeSelectorRow(
                  context,
                  label: 'Shape',
                  value: widget.brimShape ?? 'Any',
                  onTap: () => _pickOption(
                    context,
                    title: 'Brim shape',
                    current: widget.brimShape,
                    options: widget.brimShapeOptions,
                    onSelect: (v) => _emit(brim: v),
                  ),
                ),
                const SizedBox(height: 16),
                _multiCheckboxSection<String>(
                  label: 'Width',
                  anySelected: widget.brimWidths.isEmpty,
                  onAny: () => _emit(widths: []),
                  options: brimWidths,
                  isSelected: (v) => widget.brimWidths.contains(v),
                  labelFor: (v) => v,
                  onToggle: (v) {
                    final next = List<String>.from(widget.brimWidths);
                    if (next.contains(v)) {
                      next.remove(v);
                    } else {
                      next.add(v);
                    }
                    _emit(widths: next);
                  },
                ),
              ],
            ),
          ),
          if (_showScrollHint) _scrollMoreHint(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onExpandedChanged(!widget.expanded),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: widget.expanded
                    ? _turquoise.withValues(alpha: 0.1)
                    : _surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: widget.expanded ? _turquoise : _border,
                  width: widget.expanded ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: widget.expanded
                        ? _turquoise
                        : _espresso.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'FINE TUNING',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: widget.expanded ? _turquoise : _espresso,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: widget.expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: widget.expanded
                          ? _turquoise
                          : _espresso.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: _expandedPanel(context),
          ),
          crossFadeState: widget.expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }

  Widget _sectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _turquoise),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: _turquoise,
          ),
        ),
      ],
    );
  }

  Widget _shapeSelectorRow(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: _espresso.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _espresso,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.unfold_more_rounded,
                size: 20,
                color: _espresso.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _multiCheckboxSection<T>({
    required String label,
    required bool anySelected,
    required VoidCallback onAny,
    required List<T> options,
    required bool Function(T) isSelected,
    required String Function(T) labelFor,
    required ValueChanged<T> onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: _espresso.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _chipToggle(
              label: 'Any',
              selected: anySelected,
              onTap: onAny,
            ),
            ...options.map(
              (opt) => _chipToggle(
                label: labelFor(opt),
                selected: isSelected(opt),
                onTap: () => onToggle(opt),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chipToggle({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? Colors.white : _espresso,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: _turquoise,
      backgroundColor: _surface,
      side: BorderSide(
        color: selected ? _turquoise : _border,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }
}
