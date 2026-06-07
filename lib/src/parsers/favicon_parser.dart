import 'package:html/dom.dart';

/// Extracts the favicon declared by a [Document] head.
///
/// Used as the last image fallback of the extraction chain: when no
/// metadata format provides an image, the favicon still gives the preview
/// something recognizable to show.
class FaviconParser {
  final Document? _document;
  FaviconParser(this._document);

  /// The best favicon href declared by the document, or null when there is
  /// none. Prefers `apple-touch-icon` (typically 180×180) over the generic
  /// `icon`/`shortcut icon`, which is often a tiny 16×16.
  String? get faviconUrl {
    final links =
        _document?.head?.querySelectorAll('link[rel][href]') ?? const [];
    String? generic;
    String? touch;
    for (final link in links) {
      final rel = link.attributes['rel']?.toLowerCase().trim();
      final href = link.attributes['href'];
      if (rel == null || href == null || href.isEmpty) continue;
      if (rel == 'apple-touch-icon' || rel == 'apple-touch-icon-precomposed') {
        touch ??= href;
      } else if (rel == 'icon' || rel == 'shortcut icon') {
        generic ??= href;
      }
    }
    return touch ?? generic;
  }

  @override
  String toString() => 'FaviconParser(faviconUrl: $faviconUrl)';
}
