import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom bar with text tabs and active mark.
class MoonRidgeBottomNav extends StatelessWidget {
  const MoonRidgeBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _barColor = Color(0xFF1C1917);
  static const _active = Colors.white;
  static const _inactive = Color(0xFF9E9890);

  /// Fixed slot so single-line and stacked labels share the same height.
  static const _labelSlotHeight = 34.0;
  static const _indicatorSlotHeight = 14.0;
  static const _labelIndicatorGap = 8.0;
  static const _tabColumnHeight =
      _labelSlotHeight + _labelIndicatorGap + _indicatorSlotHeight;
  static const _labelFontSize = 13.0;

  static const _tabs = <_NavTab>[
    _NavTab.label('Home'),
    _NavTab.label('Find Hat'),
    _NavTab.stacked(topLine: 'Head', bottomLine: 'Shape'),
    _NavTab.label('Shop'),
    _NavTab.label('Connect'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ColoredBox(
      color: _barColor,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, bottomInset > 0 ? 10 : 16),
        child: SizedBox(
          height: _tabColumnHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(_tabs.length, (index) {
              return Expanded(
                child: _NavTabItem(
                  tab: _tabs[index],
                  active: index == selectedIndex,
                  onTap: () => onSelected(index),
                  labelSlotHeight: _labelSlotHeight,
                  indicatorSlotHeight: _indicatorSlotHeight,
                  labelIndicatorGap: _labelIndicatorGap,
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

class _NavTabItem extends StatelessWidget {
  const _NavTabItem({
    required this.tab,
    required this.active,
    required this.onTap,
    required this.labelSlotHeight,
    required this.indicatorSlotHeight,
    required this.labelIndicatorGap,
    required this.activeColor,
    required this.inactiveColor,
  });

  final _NavTab tab;
  final bool active;
  final VoidCallback onTap;
  final double labelSlotHeight;
  final double indicatorSlotHeight;
  final double labelIndicatorGap;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final labelStyle = GoogleFonts.montserrat(
      fontSize: MoonRidgeBottomNav._labelFontSize,
      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
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
            SizedBox(height: labelIndicatorGap),
            SizedBox(
              height: indicatorSlotHeight,
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: active ? 1 : 0,
                  child: const _NavActiveMark(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTab {
  const _NavTab.label(this.label)
      : topLine = null,
        bottomLine = null;

  const _NavTab.stacked({required this.topLine, required this.bottomLine})
      : label = null;

  final String? label;
  final String? topLine;
  final String? bottomLine;

  bool get isStacked => topLine != null && bottomLine != null;

  String get semanticsLabel =>
      isStacked ? '$topLine $bottomLine' : label!;
}

class _NavActiveMark extends StatelessWidget {
  const _NavActiveMark();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(12, 12),
      painter: _FourPointMarkPainter(color: Colors.white),
    );
  }
}

class _FourPointMarkPainter extends CustomPainter {
  _FourPointMarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.62, size.height * 0.38)
      ..lineTo(size.width, size.height * 0.5)
      ..lineTo(size.width * 0.62, size.height * 0.62)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(size.width * 0.38, size.height * 0.62)
      ..lineTo(0, size.height * 0.5)
      ..lineTo(size.width * 0.38, size.height * 0.38)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FourPointMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
