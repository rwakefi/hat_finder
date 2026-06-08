import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_breakpoints.dart';

/// Primary app navigation — bottom bar on mobile, top bar on desktop web.
class MoonRidgeBottomNav extends StatefulWidget {
  const MoonRidgeBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.layout = AppNavLayout.bottom,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final AppNavLayout layout;

  @override
  State<MoonRidgeBottomNav> createState() => _MoonRidgeBottomNavState();
}

enum AppNavLayout { bottom, top }

class _MoonRidgeBottomNavState extends State<MoonRidgeBottomNav> {
  late int _visualSelectedIndex = widget.selectedIndex;

  static const _barColor = Color(0xFF1C1917);
  static const _active = Color(0xFFB8860B);
  static const _inactive = Color(0xFF9E9890);
  static const _accent = Color(0xFF559C99);

  static const _labelSlotHeight = 26.0;
  static const _labelFontSize = 11.0;

  static const _tabs = <_NavTab>[
    _NavTab.label('Home'),
    _NavTab.stacked(topLine: 'Find', bottomLine: 'Hats', topLabel: 'Find Hats'),
    _NavTab.stacked(
      topLine: 'Head',
      bottomLine: 'Shape',
      topLabel: 'Head Shape',
    ),
    _NavTab.label('Shop'),
    _NavTab.stacked(
      topLine: 'Events /',
      bottomLine: 'Connect',
      topLabel: 'Events / Connect',
    ),
  ];

  @override
  void didUpdateWidget(covariant MoonRidgeBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex ||
        widget.selectedIndex != _visualSelectedIndex) {
      _visualSelectedIndex = widget.selectedIndex;
    }
  }

  void _handleTap(int index) {
    setState(() => _visualSelectedIndex = index);
    widget.onSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.layout == AppNavLayout.top) {
      return _buildTopBar(context);
    }
    return _buildBottomBar(context);
  }

  Widget _buildTopBar(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _barColor,
        border: Border(
          bottom: BorderSide(color: Color(0x22FFFFFF)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_tabs.length, (index) {
                return _TopNavTabItem(
                  label: _tabs[index].displayLabel(topBar: true),
                  active: index == _visualSelectedIndex,
                  onTap: () => _handleTap(index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isLaptop = AppBreakpoints.isLaptop(context);

    return ColoredBox(
      color: _barColor,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isLaptop ? 24 : 16,
          isLaptop ? 8 : 10,
          isLaptop ? 24 : 16,
          bottomInset > 0 ? 8 : (isLaptop ? 10 : 12),
        ),
        child: SizedBox(
          height: _labelSlotHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(_tabs.length, (index) {
              return Expanded(
                child: _BottomNavTabItem(
                  tab: _tabs[index],
                  active: index == _visualSelectedIndex,
                  onTap: () => _handleTap(index),
                  labelSlotHeight: _labelSlotHeight,
                  activeColor: _active,
                  inactiveColor: _inactive,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TopNavTabItem extends StatelessWidget {
  const _TopNavTabItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.2,
                  color: active
                      ? _MoonRidgeBottomNavState._active
                      : _MoonRidgeBottomNavState._inactive,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 2,
                width: active ? 28 : 0,
                decoration: BoxDecoration(
                  color: _MoonRidgeBottomNavState._accent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavTabItem extends StatelessWidget {
  const _BottomNavTabItem({
    required this.tab,
    required this.active,
    required this.onTap,
    required this.labelSlotHeight,
    required this.activeColor,
    required this.inactiveColor,
  });

  final _NavTab tab;
  final bool active;
  final VoidCallback onTap;
  final double labelSlotHeight;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final labelStyle = GoogleFonts.montserrat(
      fontSize: _MoonRidgeBottomNavState._labelFontSize,
      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
      letterSpacing: 0.2,
      color: active ? activeColor : inactiveColor,
      height: 1.15,
    );

    return Semantics(
      button: true,
      selected: active,
      label: tab.semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: labelSlotHeight,
          child: Center(
            child: tab.isStacked
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tab.topLine!,
                        textAlign: TextAlign.center,
                        style: labelStyle,
                      ),
                      Text(
                        tab.bottomLine!,
                        textAlign: TextAlign.center,
                        style: labelStyle,
                      ),
                    ],
                  )
                : Text(
                    tab.label!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  const _NavTab.label(this.label)
      : topLine = null,
        bottomLine = null,
        topLabel = null;

  const _NavTab.stacked({
    required this.topLine,
    required this.bottomLine,
    required this.topLabel,
  }) : label = null;

  final String? label;
  final String? topLine;
  final String? bottomLine;
  final String? topLabel;

  bool get isStacked => topLine != null && bottomLine != null;

  String displayLabel({required bool topBar}) {
    if (topBar) {
      return topLabel ?? label ?? '$topLine $bottomLine';
    }
    return label ?? topLine ?? '';
  }

  String get semanticsLabel =>
      topLabel ?? label ?? (isStacked ? '$topLine $bottomLine' : '');
}
