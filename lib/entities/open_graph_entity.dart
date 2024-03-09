// To parse this JSON data, do
//
//     final openGraphEntity = openGraphEntityFromJson(jsonString);

import 'dart:convert';

/// OpenGraphEntity
///
/// A class that represents the OpenGraphEntity
///
OpenGraphEntity openGraphEntityFromJson(String str) =>
    OpenGraphEntity.fromJson(json.decode(str));

String openGraphEntityToJson(OpenGraphEntity data) =>
    json.encode(data.toJson());

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
  /// title of the site
  String title;
  // description of the site
  String description;
  // locale of the site
  String locale;
  // type of the site
  String type;
  // url of the site
  String url;
  // site name
  String siteName;
  // image of the site
  String image;

  OpenGraphEntity({
    required this.title,
    required this.description,
    required this.locale,
    required this.type,
    required this.url,
    required this.siteName,
    required this.image,
  });

  /// fromJson
  ///
  /// Convert a JSON object to an OpenGraphEntity
  ///
  /// @param json: JSON object
  factory OpenGraphEntity.fromJson(Map<String, dynamic> json) =>
      OpenGraphEntity(
        title: json["title"],
        description: json["description"],
        locale: json["locale"],
        type: json["type"],
        url: json["url"],
        siteName: json["site_name"],
        image: json["image"],
      );

  /// toJson
  ///
  /// Convert the OpenGraphEntity to a JSON object
  Map<String, dynamic> toJson() => {
        "title": title,
        "description": description,
        "locale": locale,
        "type": type,
        "url": url,
        "site_name": siteName,
        "image": image,
      };

  /// toString
  ///
  /// Convert the OpenGraphEntity to a string
  @override
  String toString() => toJson().toString();
}
