import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:opengraph/src/models/open_graph_entity.dart';

/// How the preview card arranges its image and texts.
enum OpenGraphLayout {
  /// Full-bleed image with the texts overlaid at the bottom (default).
  overlay,

  /// Square image on the left, texts on the right — compact rows in lists.
  horizontal,
}

/// WidgetOpenGraph Widget
/// Internal widget to show the OpenGraphEntity data
/// This widget is used by OpenGraphPreview
class WidgetOpenGraph extends StatelessWidget {
  /// OpenGraphEntity data
  final OpenGraphEntity data;

  /// Height of the widget
  final double height;

  /// Is production mode
  final bool isProduction;

  /// Border radius of the widget
  final double borderRadius;

  /// Custom widget shown when there is no og:image (or it fails to load),
  /// instead of the default bundled image.
  final Widget? fallbackImage;

  /// Whether the text overlay uses a blur effect. Disable it in long lists
  /// for better scrolling performance ([BackdropFilter] is expensive).
  final bool enableBlur;

  /// Style merged over the default title style (white, bold).
  final TextStyle? titleStyle;

  /// Style merged over the default description style (white).
  final TextStyle? descriptionStyle;

  /// Style merged over the default host style (white54).
  final TextStyle? hostStyle;

  /// Maximum lines for the title (default: 1).
  final int titleMaxLines;

  /// Maximum lines for the description (default: 2).
  final int descriptionMaxLines;

  /// Color of the panel behind the texts (default: 50% black).
  final Color overlayColor;

  /// How the image fits its box (default: [BoxFit.fitWidth] in the overlay
  /// layout, [BoxFit.cover] suits the horizontal one).
  final BoxFit imageFit;

  /// Called when the card is tapped, e.g. to open the URL.
  final VoidCallback? onTap;

  /// Arrangement of image and texts (default: [OpenGraphLayout.overlay]).
  final OpenGraphLayout layout;

  /// [WidgetOpenGraph] is a widget to show the OpenGraphEntity data
  /// [data] is the OpenGraphEntity data to show in the widget
  /// [height] is the height of the widget
  /// [isProduction] is a flag to show the image or a default image
  /// [borderRadius] is the border radius of the widget
  /// [fallbackImage] replaces the default image when there is no og:image
  /// [enableBlur] toggles the blur effect behind the text overlay
  const WidgetOpenGraph({
    super.key,
    required this.data,
    required this.height,
    required this.isProduction,
    required this.borderRadius,
    this.fallbackImage,
    this.enableBlur = true,
    this.titleStyle,
    this.descriptionStyle,
    this.hostStyle,
    this.titleMaxLines = 1,
    this.descriptionMaxLines = 2,
    this.overlayColor = const Color(0x80000000),
    this.imageFit = BoxFit.fitWidth,
    this.onTap,
    this.layout = OpenGraphLayout.overlay,
  });

  static const TextStyle _defaultTitleStyle =
      TextStyle(color: Colors.white, fontWeight: FontWeight.bold);
  static const TextStyle _defaultDescriptionStyle =
      TextStyle(color: Colors.white);
  static const TextStyle _defaultHostStyle = TextStyle(color: Colors.white54);

  /// Default image shown when there is no og:image or it fails to load.
  Widget _fallbackImage(BuildContext context,
      {required double width, required BoxFit fit}) {
    return fallbackImage ??
        Image.asset(
          "assets/notfound.jpeg",
          package: 'opengraph',
          width: width,
          height: height,
          fit: fit,
        );
  }

  /// Builds the preview image supporting http(s) urls and `data:` URIs.
  ///
  /// `data:image/...;base64,...` images are decoded with [Image.memory]
  /// because [Image.network] throws "No host specified" for them. Broken
  /// urls fall back to the default image instead of crashing.
  ///
  /// Images are decoded at display size (cacheWidth) so huge og:images do
  /// not cause jank while scrolling.
  Widget _buildImage(BuildContext context,
      {required double width, required BoxFit fit}) {
    final image = data.image;
    final cacheWidth = (width * MediaQuery.of(context).devicePixelRatio)
        .clamp(1, double.maxFinite)
        .round();

    if (image.isEmpty) {
      return _fallbackImage(context, width: width, fit: fit);
    }

    if (image.startsWith('data:')) {
      Uint8List? bytes;
      try {
        bytes = Uri.parse(image).data?.contentAsBytes();
      } catch (_) {
        bytes = null;
      }
      if (bytes == null || bytes.isEmpty) {
        return _fallbackImage(context, width: width, fit: fit);
      }
      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) =>
            _fallbackImage(context, width: width, fit: fit),
      );
    }

    return Image.network(
      image,
      fit: fit,
      width: width,
      height: height,
      cacheWidth: cacheWidth,
      errorBuilder: (context, error, stackTrace) =>
          _fallbackImage(context, width: width, fit: fit),
    );
  }

  List<Widget> _texts() {
    return [
      if (data.title != "")
        Text(data.title,
            style: _defaultTitleStyle.merge(titleStyle),
            maxLines: titleMaxLines,
            overflow: TextOverflow.ellipsis),
      if (data.description != "")
        Text(data.description,
            style: _defaultDescriptionStyle.merge(descriptionStyle),
            maxLines: descriptionMaxLines,
            overflow: TextOverflow.ellipsis),
      Text(Uri.parse(data.url).host, style: _defaultHostStyle.merge(hostStyle)),
    ];
  }

  Widget _overlayLayout(BuildContext context) {
    final overlay = Container(
      color: overlayColor,
      padding: const EdgeInsets.all(5.0),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _texts()),
    );

    return Stack(
      children: [
        if (isProduction)
          _buildImage(context,
              width: MediaQuery.of(context).size.width, fit: imageFit),
        Positioned(
          bottom: 0.0,
          left: 0.0,
          right: 0.0,
          child: Padding(
            padding: EdgeInsets.all(borderRadius / 2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius / 2),
              child: enableBlur
                  ? BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: overlay,
                    )
                  : overlay,
            ),
          ),
        ),
      ],
    );
  }

  Widget _horizontalLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isProduction)
          SizedBox(
            width: height,
            child: _buildImage(context,
                width: height,
                fit: imageFit == BoxFit.fitWidth ? BoxFit.cover : imageFit),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _texts(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      height: height,
      width: MediaQuery.of(context).size.width,
      child: layout == OpenGraphLayout.horizontal
          ? _horizontalLayout(context)
          : _overlayLayout(context),
    );

    if (onTap == null) return content;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }
}
