// The base class for implementing a parser

import 'package:opengraph/src/models/og_media.dart';

mixin OpengraphKeys {
  static const keyTitle = 'title';
  static const keyDescription = 'description';
  static const keyImage = 'image';
  static const keyUrl = 'url';
  static const keyLocale = 'locale';
  static const keyType = 'type';
  static const keySiteName = 'siteName';
}

mixin BaseOpengraphParser {
  String? title;
  String? description;
  String? image;
  String? url;
  String? locale;
  String? type;
  String? siteName;

  OpengraphMetadata parse() {
    final m = OpengraphMetadata();
    m.title = title;
    m.description = description;
    m.image = image;
    m.url = url;
    m.locale = locale;
    m.type = type;
    m.siteName = siteName;
    return m;
  }
}

/// Container class for Metadata
class OpengraphMetadata with BaseOpengraphParser, OpengraphKeys {
  /// Structured `og:image` objects, in document order. [image] keeps the
  /// first usable image for backwards compatibility.
  List<OgImage> images = [];

  /// Structured `og:video` objects, in document order.
  List<OgVideo> videos = [];

  /// Structured `og:audio` objects, in document order.
  List<OgAudio> audios = [];

  /// Vertical-specific tags (`article:*`, `book:*`, `profile:*`, `music:*`,
  /// `video:*`) keyed by property name; properties may repeat.
  Map<String, List<String>> structuredTags = {};

  /// Favicon declared by the document, when any.
  String? faviconUrl;

  bool get hasAllMetadata {
    return (title != null &&
        description != null &&
        image != null &&
        url != null);
  }

  @override
  String toString() {
    return toMap().toString();
  }

  Map<String, String?> toMap() {
    return {
      OpengraphKeys.keyTitle: title,
      OpengraphKeys.keyDescription: description,
      OpengraphKeys.keyImage: image,
      OpengraphKeys.keyUrl: url,
      OpengraphKeys.keyLocale: locale,
      OpengraphKeys.keyType: type,
      OpengraphKeys.keySiteName: siteName,
    };
  }

  /// Serializes the base scalar fields only. The rich fields (images,
  /// videos, audios, structuredTags, faviconUrl) are not included — use
  /// `OpenGraphEntity.toJson` for a full serialization.
  Map<String, dynamic> toJson() {
    return toMap();
  }

  /// Restores the base scalar fields only; see [toJson].
  static OpengraphMetadata fromJson(Map<String, dynamic> json) {
    final m = OpengraphMetadata();
    m.title = json[OpengraphKeys.keyTitle];
    m.description = json[OpengraphKeys.keyDescription];
    m.image = json[OpengraphKeys.keyImage];
    m.url = json[OpengraphKeys.keyUrl];
    m.locale = json[OpengraphKeys.keyLocale];
    m.type = json[OpengraphKeys.keyType];
    m.siteName = json[OpengraphKeys.keySiteName];
    return m;
  }
}
