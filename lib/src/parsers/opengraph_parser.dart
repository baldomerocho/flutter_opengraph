import 'package:html/dom.dart';
import 'package:opengraph/src/models/og_media.dart';
import 'package:opengraph/src/utils/util.dart';

import 'base_parser.dart';

/// Takes a [Document] and parses [OpengraphMetadata] from `<meta property='og:*'>` tags
class OpengraphParser with BaseOpengraphParser {
  final Document? _document;
  OpengraphParser(this._document);

  /// Vertical-specific OpenGraph namespaces collected into
  /// [OpengraphMetadata.structuredTags].
  static final RegExp _verticalTag =
      RegExp(r'^(article|book|profile|music|video):');

  /// Get [OpengraphMetadata.title] from 'og:title'
  @override
  String? get title => getProperty(
        _document,
        property: 'og:title',
      );

  /// Get [OpengraphMetadata.description] from 'og:description'
  @override
  String? get description => getProperty(
        _document,
        property: 'og:description',
      );

  /// Get [OpengraphMetadata.image] from 'og:image'
  @override
  String? get image => getProperty(
        _document,
        property: 'og:image',
      );

  /// Get [OpengraphMetadata.url] from 'og:url'
  @override
  String? get url => getProperty(
        _document,
        property: 'og:url',
      );

  /// Get [OpengraphMetadata.locale] from 'og:locale'
  @override
  String? get locale => getProperty(
        _document,
        property: 'og:locale',
      );

  /// Get [OpengraphMetadata.type] from 'og:type'
  @override
  String? get type => getProperty(
        _document,
        property: 'og:type',
      );

  /// Get [OpengraphMetadata.siteName] from 'og:site_name'
  @override
  String? get siteName => getProperty(
        _document,
        property: 'og:site_name',
      );

  /// All `<meta property>` tags in document order, used to group the
  /// structured objects of the protocol. Scans the whole document, like
  /// the scalar getters (`getProperty`) do.
  List<Element> get _propertyMetas =>
      _document?.querySelectorAll('meta[property]') ?? const [];

  /// Groups the structured properties of a [root] tag (`og:image`,
  /// `og:video`, `og:audio`) following the OpenGraph protocol: a root tag
  /// opens a new object and its `:sub` properties attach to the last
  /// opened one. `og:image:url` is equivalent to the root tag, so it
  /// confirms the current object instead of opening another.
  List<Map<String, String>> _collectObjects(String root) {
    final objects = <Map<String, String>>[];
    for (final meta in _propertyMetas) {
      final property = meta.attributes['property'];
      final content = meta.attributes['content'];
      if (property == null || content == null || content.isEmpty) continue;
      if (property == root) {
        objects.add({'url': content});
      } else if (property == '$root:url') {
        if (objects.isEmpty) {
          objects.add({'url': content});
        } else {
          objects.last['url'] = content;
        }
      } else if (property.startsWith('$root:') && objects.isNotEmpty) {
        objects.last[property.substring(root.length + 1)] = content;
      }
    }
    return objects;
  }

  /// All `og:image` objects with their structured properties.
  List<OgImage> get images => _collectObjects('og:image')
      .map((o) => OgImage(
            url: o['url'] ?? '',
            secureUrl: o['secure_url'],
            type: o['type'],
            width: int.tryParse(o['width'] ?? ''),
            height: int.tryParse(o['height'] ?? ''),
            alt: o['alt'],
          ))
      .toList();

  /// All `og:video` objects with their structured properties.
  List<OgVideo> get videos => _collectObjects('og:video')
      .map((o) => OgVideo(
            url: o['url'] ?? '',
            secureUrl: o['secure_url'],
            type: o['type'],
            width: int.tryParse(o['width'] ?? ''),
            height: int.tryParse(o['height'] ?? ''),
          ))
      .toList();

  /// All `og:audio` objects with their structured properties.
  List<OgAudio> get audios => _collectObjects('og:audio')
      .map((o) => OgAudio(
            url: o['url'] ?? '',
            secureUrl: o['secure_url'],
            type: o['type'],
          ))
      .toList();

  /// Vertical tags (`article:author`, `article:tag`, `book:isbn`…), with
  /// repeated properties accumulated in document order.
  Map<String, List<String>> get structuredTags {
    final tags = <String, List<String>>{};
    for (final meta in _propertyMetas) {
      final property = meta.attributes['property'];
      final content = meta.attributes['content'];
      if (property == null || content == null || content.isEmpty) continue;
      if (_verticalTag.hasMatch(property)) {
        tags.putIfAbsent(property, () => []).add(content);
      }
    }
    return tags;
  }

  @override
  OpengraphMetadata parse() {
    final metadata = super.parse();
    metadata.images = images;
    metadata.videos = videos;
    metadata.audios = audios;
    metadata.structuredTags = structuredTags;
    return metadata;
  }

  @override
  String toString() => parse().toString();
}
