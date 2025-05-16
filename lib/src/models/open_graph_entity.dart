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

  OpenGraphEntity({
    required this.title,
    required this.description,
    required this.locale,
    required this.type,
    required this.url,
    required this.siteName,
    required this.image,
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
    };
  }

  @override
  String toString() => 'OpenGraphEntity(${toJson().toString()})';
}
