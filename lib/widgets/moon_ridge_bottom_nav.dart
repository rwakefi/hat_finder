import 'package:flutter/foundation.dart';
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
  static const _active = Color(0xFFD4A843);
  static const _inactive = Color(0xFF9E9890);

  static const _labelSlotHeight = 36.0;
  static const _labelFontSize = 13.0;

  static const _surface = Color(0xFFFAF8F5);
  static const _border = Color(0xFFE8E5E1);

  static const _tabs = <_NavTab>[
    _NavTab.label('Home', icon: Icons.home_rounded),
    _NavTab.stacked(
      topLine: 'Find',
      bottomLine: 'Hats',
      topLabel: 'Find Hats',
      icon: Icons.search_rounded,
    ),
    _NavTab.stacked(
      topLine: 'Head',
      bottomLine: 'Shape',
      topLabel: 'Head Shape',
      icon: Icons.face_retouching_natural_rounded,
    ),
    _NavTab.label('Shop', icon: Icons.shopping_bag_outlined),
    _NavTab.stacked(
      topLine: 'Events /',
      bottomLine: 'Connect',
      topLabel: 'Events / Connect',
      icon: Icons.event_rounded,
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
      decoration: BoxDecoration(
        color: _surface,
        border: Border(
          bottom: BorderSide(color: _barColor.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: _barColor.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_tabs.length, (index) {
                    return _TopNavTabItem(
                      tab: _tabs[index],
                      active: index == _visualSelectedIndex,
                      onTap: () => _handleTap(index),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final hasHomeIndicator = MediaQuery.paddingOf(context).bottom > 0;
    final isLaptop = AppBreakpoints.isLaptop(context);
    final isMobileWeb = kIsWeb && !AppBreakpoints.useWebTopNavigation(context);

    // Apple HIG tab bar content is 49pt; we use a fixed label slot plus padding.
    final labelSlotHeight = isMobileWeb ? 40.0 : _labelSlotHeight;
    final topPadding = isMobileWeb ? 12.0 : 11.0;
    // Extra gap above the home indicator — SafeArea supplies the system inset.
    final extraBottomPadding = hasHomeIndicator
        ? (isMobileWeb ? 8.0 : 6.0)
        : (isMobileWeb ? 10.0 : (isLaptop ? 10.0 : 8.0));

    return ColoredBox(
      color: _barColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isLaptop ? 24 : 16,
            topPadding,
            isLaptop ? 24 : 16,
            extraBottomPadding,
          ),
          child: SizedBox(
            height: labelSlotHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(_tabs.length, (index) {
                return Expanded(
                  child: _BottomNavTabItem(
                    tab: _tabs[index],
                    active: index == _visualSelectedIndex,
                    onTap: () => _handleTap(index),
                    labelSlotHeight: labelSlotHeight,
                    activeColor: _active,
                    inactiveColor: _inactive,
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopNavTabItem extends StatelessWidget {
  const _TopNavTabItem({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  final _NavTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = tab.displayLabel(topBar: true);
    final iconColor = active
        ? _MoonRidgeBottomNavState._active
        : _MoonRidgeBottomNavState._inactive;

    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? _MoonRidgeBottomNavState._active.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: active
                  ? Border.all(
                      color: _MoonRidgeBottomNavState._active
                          .withValues(alpha: 0.35),
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tab.icon, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.3,
                    color: iconColor,
                  ),
                ),
              ],
            ),
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
      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
      letterSpacing: 0.8,
      color: active ? activeColor : inactiveColor,
      height: 1.1,
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
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
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
                    ),
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
  const _NavTab.label(this.label, {required this.icon})
      : topLine = null,
        bottomLine = null,
        topLabel = null;

  const _NavTab.stacked({
    required this.topLine,
    required this.bottomLine,
    required this.topLabel,
    required this.icon,
  }) : label = null;

  final String? label;
  final String? topLine;
  final String? bottomLine;
  final String? topLabel;
  final IconData icon;

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
