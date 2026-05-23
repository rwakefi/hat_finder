import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/moon_ridge_social_links.dart';

enum HomeSocialLinksLayout {
  bar,
  carouselColumn,
}

/// Social profile links for the home screen.
class HomeSocialLinks extends StatelessWidget {
  const HomeSocialLinks({
    super.key,
    this.layout = HomeSocialLinksLayout.bar,
  });

  final HomeSocialLinksLayout layout;

  static const Color _espresso = Color(0xFF2D2926);
  static const Color _surface = Color(0xFFFAF8F5);

  static const List<({String label, FaIconData icon, String url})> _links = [
    (
      label: 'Instagram',
      icon: FontAwesomeIcons.instagram,
      url: MoonRidgeSocialLinks.instagram,
    ),
    (
      label: 'TikTok',
      icon: FontAwesomeIcons.tiktok,
      url: MoonRidgeSocialLinks.tiktok,
    ),
    (
      label: 'Facebook',
      icon: FontAwesomeIcons.facebookF,
      url: MoonRidgeSocialLinks.facebook,
    ),
  ];

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onCarousel = layout == HomeSocialLinksLayout.carouselColumn;
    final iconColor = onCarousel
        ? Colors.white.withValues(alpha: 0.9)
        : _espresso.withValues(alpha: 0.38);

    final icons = [
      for (var i = 0; i < _links.length; i++)
        _SocialIconButton(
          label: _links[i].label,
          icon: _links[i].icon,
          color: iconColor,
          compact: onCarousel,
          onTap: () => _open(context, _links[i].url),
        ),
    ];

    final Widget links = onCarousel
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < icons.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                icons[i],
              ],
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < icons.length; i++) ...[
                if (i > 0) const SizedBox(width: 28),
                icons[i],
              ],
            ],
          );

    if (onCarousel) {
      return links;
    }

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return ColoredBox(
      color: _surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 10, 24, bottomInset > 0 ? 6 : 14),
        child: links,
      ),
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final FaIconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          customBorder: const CircleBorder(),
          splashColor: Colors.white24,
          highlightColor: Colors.white12,
          child: Padding(
            padding: EdgeInsets.all(compact ? 8 : 10),
            child: FaIcon(
              icon,
              size: compact ? 18 : 20,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
