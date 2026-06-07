import 'package:opengraph/src/models/og_media.dart';

/// OpenGraphEntity represents the OpenGraph protocol
/// Properties:
/// - title: Site title, example: "Open Graph protocol"
/// - description: Site description, example: "The Open Graph protocol enables any web page to become a rich object in a social graph."
/// - locale: Site locale, example: "en_US"
/// - type: Site type, example: "website"
/// - url: Site url, example: "http://ogp.me/"
/// - siteName: Site name, example: "Open Graph protocol"
/// - image: Site image, example: "http://ogp.me/logo.png"
class OpenGraphEntity {
  final String title;
  final String description;
  final String locale;
  final String type;
  final String url;
  final String siteName;
  final String image;

  /// All image objects declared by the page, in document order, with their
  /// structured properties (width/height/alt…). When the page declares no
  /// `og:image` objects but an image was found elsewhere, it contains that
  /// single image, so `images.first` is always usable when [image] is.
  final List<OgImage> images;

  /// All `og:video` objects declared by the page, in document order.
  final List<OgVideo> videos;

  /// All `og:audio` objects declared by the page, in document order.
  final List<OgAudio> audios;

  /// Vertical-specific OpenGraph tags (`article:*`, `book:*`, `profile:*`,
  /// `music:*`, `video:*`), keyed by property name. A property may appear
  /// several times (e.g. `article:tag`), hence the list values.
  final Map<String, List<String>> structuredTags;

  /// Favicon declared by the page (`<link rel="icon">` and friends),
  /// resolved to an absolute URL. Null when the page declares none.
  final String? faviconUrl;

  OpenGraphEntity({
    required this.title,
    required this.description,
    required this.locale,
    required this.type,
    required this.url,
    required this.siteName,
    required this.image,
    this.images = const [],
    this.videos = const [],
    this.audios = const [],
    this.structuredTags = const {},
    this.faviconUrl,
  });

  /// Create OpenGraphEntity from json
  factory OpenGraphEntity.fromJson(Map<String, dynamic> json) {
    return OpenGraphEntity(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      locale: json['locale'] ?? '',
      type: json['type'] ?? '',
      url: json['url'] ?? '',
      siteName: json['siteName'] ?? '',
      image: json['image'] ?? '',
      images: (json['images'] as List?)
              ?.map((e) => OgImage.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      videos: (json['videos'] as List?)
              ?.map((e) => OgVideo.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      audios: (json['audios'] as List?)
              ?.map((e) => OgAudio.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      structuredTags: (json['structuredTags'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), List<String>.from(value)),
          ) ??
          const {},
      faviconUrl: json['faviconUrl'],
    );
  }

  /// Convert OpenGraphEntity to json
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'locale': locale,
      'type': type,
      'url': url,
      'siteName': siteName,
      'image': image,
      if (images.isNotEmpty) 'images': images.map((e) => e.toJson()).toList(),
      if (videos.isNotEmpty) 'videos': videos.map((e) => e.toJson()).toList(),
      if (audios.isNotEmpty) 'audios': audios.map((e) => e.toJson()).toList(),
      if (structuredTags.isNotEmpty) 'structuredTags': structuredTags,
      if (faviconUrl != null) 'faviconUrl': faviconUrl,
    };
  }

  @override
  String toString() => 'OpenGraphEntity(${toJson().toString()})';
}
