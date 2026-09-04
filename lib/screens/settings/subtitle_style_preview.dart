import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../../services/settings_service.dart';
import '../../widgets/settings_builder.dart';
import 'settings_utils.dart';

/// Live sample of the current subtitle styling, so the knobs below it can be
/// judged by eye instead of by number.
///
/// An approximation, deliberately: the real thing is drawn by libass or the
/// platform text renderer against real video. Size and border are expressed by
/// mpv relative to a 720-high window, so both are scaled by this widget's own
/// height to keep the sample proportionate to what plays back.
class SubtitleStylePreview extends StatelessWidget {
  const SubtitleStylePreview({super.key, this.height = defaultHeight});

  /// Tall enough to judge outline weight and background opacity, short enough
  /// that pinning it still leaves the options below it readable on a phone.
  static const double defaultHeight = 180;

  final double height;

  /// mpv sizes `sub-font-size` and `sub-border-size` against a 720-high window.
  static const double _referenceHeight = 720;

  static final List<Pref<Object?>> watchedPrefs = [
    SettingsService.subtitleFontSize,
    SettingsService.subtitleTextColor,
    SettingsService.subtitleBorderSize,
    SettingsService.subtitleBorderColor,
    SettingsService.subtitleBackgroundColor,
    SettingsService.subtitleBackgroundOpacity,
    SettingsService.subtitleBold,
    SettingsService.subtitleItalic,
    SettingsService.subtitlePosition,
  ];

  @override
  Widget build(BuildContext context) {
    return SettingsBuilder(
      prefs: watchedPrefs,
      builder: (context) {
        final settings = SettingsService.instance;
        final scale = 1 / _referenceHeight;
        final fontSize = settings.read(SettingsService.subtitleFontSize) * scale;
        final borderSize = settings.read(SettingsService.subtitleBorderSize) * scale;
        final textColor = hexToColor(settings.read(SettingsService.subtitleTextColor));
        final borderColor = hexToColor(settings.read(SettingsService.subtitleBorderColor));
        final backgroundOpacity = settings.read(SettingsService.subtitleBackgroundOpacity) / 100;
        final backgroundColor = hexToColor(
          settings.read(SettingsService.subtitleBackgroundColor),
        ).withValues(alpha: backgroundOpacity);
        final bold = settings.read(SettingsService.subtitleBold);
        final italic = settings.read(SettingsService.subtitleItalic);
        // 0 % is the top of the frame, 100 % the bottom — the same reading as
        // the position tile's own labels.
        final position = settings.read(SettingsService.subtitlePosition) / 100;

        return SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              // Height-driven rather than width-driven: the preview is pinned, so
              // its height is the scarce dimension and the 16:9 frame is sized
              // from it instead of from the page width.
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    fit: .expand,
                    children: [
                      const _PreviewBackdrop(),
                      Align(
                        // -1 is the top edge, 1 the bottom: the same 0-100 range
                        // mapped onto Alignment's own axis.
                        alignment: Alignment(0, position * 2 - 1),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: constraints.maxHeight * 0.04),
                          child: _SampleLine(
                            text: t.subtitlingStyling.previewSample,
                            fontSize: fontSize * constraints.maxHeight,
                            borderSize: borderSize * constraints.maxHeight,
                            textColor: textColor,
                            borderColor: borderColor,
                            backgroundColor: backgroundColor,
                            bold: bold,
                            italic: italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Keeps the preview on screen while the options that change it scroll past.
/// Judging a colour or an outline against a sample you have scrolled away from
/// is exactly the problem the preview exists to remove.
class SubtitleStylePreviewHeader extends SliverPersistentHeaderDelegate {
  const SubtitleStylePreviewHeader({this.height = SubtitleStylePreview.defaultHeight});

  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Opaque: rows scroll underneath, and a translucent header would let their
    // text read as part of the sample.
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SubtitleStylePreview(height: height),
    );
  }

  @override
  bool shouldRebuild(SubtitleStylePreviewHeader oldDelegate) => oldDelegate.height != height;
}

/// Stands in for video. Deliberately not flat: a subtitle that disappears over
/// one part of the picture and not another is exactly the problem this preview
/// exists to expose, so the sample is judged against both a light and a dark
/// area.
class _PreviewBackdrop extends StatelessWidget {
  const _PreviewBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: .topLeft,
          end: .bottomRight,
          colors: [Color(0xFF1B2430), Color(0xFF8C93A0), Color(0xFF0B0D12)],
          stops: [0, 0.55, 1],
        ),
      ),
    );
  }
}

class _SampleLine extends StatelessWidget {
  const _SampleLine({
    required this.text,
    required this.fontSize,
    required this.borderSize,
    required this.textColor,
    required this.borderColor,
    required this.backgroundColor,
    required this.bold,
    required this.italic,
  });

  final String text;
  final double fontSize;
  final double borderSize;
  final Color textColor;
  final Color borderColor;
  final Color backgroundColor;
  final bool bold;
  final bool italic;

  TextStyle get _base => TextStyle(
    fontSize: fontSize,
    fontWeight: bold ? .bold : .normal,
    fontStyle: italic ? .italic : .normal,
    height: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    // Flutter has no text-stroke property, so the outline is a second copy of
    // the same string painted underneath in stroke mode — the standard trick,
    // and the reason both copies must keep identical metrics.
    final outline = borderSize <= 0
        ? null
        : Text(
            text,
            textAlign: .center,
            style: _base.copyWith(
              foreground: Paint()
                ..style = .stroke
                ..strokeWidth = borderSize * 2
                ..strokeJoin = .round
                ..color = borderColor,
            ),
          );

    return DecoratedBox(
      decoration: BoxDecoration(color: backgroundColor),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: fontSize * 0.3, vertical: fontSize * 0.1),
        child: Stack(
          alignment: .center,
          children: [
            ?outline,
            Text(
              text,
              textAlign: .center,
              style: _base.copyWith(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
