/// Structured OpenGraph media objects.
///
/// The OpenGraph protocol allows several images, videos and audios per
/// page, each with optional structured properties (`og:image:width`,
/// `og:image:alt`, `og:video:type`…) that follow their root tag in
/// document order.
library;

/// Common fields of every OpenGraph media object.
abstract class OgMedia {
  /// Absolute URL of the media (relative URLs are resolved by the parser).
  final String url;

  /// `og:*:secure_url` — https variant when the page declares one.
  final String? secureUrl;

  /// `og:*:type` — MIME type, e.g. `image/jpeg` or `video/mp4`.
  final String? type;

  const OgMedia({required this.url, this.secureUrl, this.type});

  Map<String, dynamic> toJson() => {
        'url': url,
        if (secureUrl != null) 'secureUrl': secureUrl,
        if (type != null) 'type': type,
      };

  @override
  String toString() => '$runtimeType(${toJson()})';
}

/// An `og:image` object with its structured properties.
class OgImage extends OgMedia {
  /// `og:image:width` in pixels, when declared.
  final int? width;

  /// `og:image:height` in pixels, when declared.
  final int? height;

  /// `og:image:alt` — accessible description of the image.
  final String? alt;

  const OgImage({
    required super.url,
    super.secureUrl,
    super.type,
    this.width,
    this.height,
    this.alt,
  });

  factory OgImage.fromJson(Map<String, dynamic> json) => OgImage(
        url: json['url'] ?? '',
        secureUrl: json['secureUrl'],
        type: json['type'],
        width: json['width'],
        height: json['height'],
        alt: json['alt'],
      );

  OgImage copyWith({String? url, String? secureUrl}) => OgImage(
        url: url ?? this.url,
        secureUrl: secureUrl ?? this.secureUrl,
        type: type,
        width: width,
        height: height,
        alt: alt,
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (alt != null) 'alt': alt,
      };
}

/// An `og:video` object with its structured properties.
class OgVideo extends OgMedia {
  /// `og:video:width` in pixels, when declared.
  final int? width;

  /// `og:video:height` in pixels, when declared.
  final int? height;

  const OgVideo({
    required super.url,
    super.secureUrl,
    super.type,
    this.width,
    this.height,
  });

  factory OgVideo.fromJson(Map<String, dynamic> json) => OgVideo(
        url: json['url'] ?? '',
        secureUrl: json['secureUrl'],
        type: json['type'],
        width: json['width'],
        height: json['height'],
      );

  OgVideo copyWith({String? url, String? secureUrl}) => OgVideo(
        url: url ?? this.url,
        secureUrl: secureUrl ?? this.secureUrl,
        type: type,
        width: width,
        height: height,
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      };
}

/// An `og:audio` object with its structured properties.
class OgAudio extends OgMedia {
  const OgAudio({required super.url, super.secureUrl, super.type});

  factory OgAudio.fromJson(Map<String, dynamic> json) => OgAudio(
        url: json['url'] ?? '',
        secureUrl: json['secureUrl'],
        type: json['type'],
      );

  OgAudio copyWith({String? url, String? secureUrl}) => OgAudio(
        url: url ?? this.url,
        secureUrl: secureUrl ?? this.secureUrl,
        type: type,
      );
}
