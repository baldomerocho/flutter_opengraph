// To parse this JSON data, do
//
//     final openGraphEntity = openGraphEntityFromJson(jsonString);

import 'dart:convert';

OpenGraphEntity openGraphEntityFromJson(String str) => OpenGraphEntity.fromJson(json.decode(str));

String openGraphEntityToJson(OpenGraphEntity data) => json.encode(data.toJson());

class OpenGraphEntity {
  String title;
  String description;
  String locale;
  String type;
  String url;
  String siteName;
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

  factory OpenGraphEntity.fromJson(Map<String, dynamic> json) => OpenGraphEntity(
    title: json["title"],
    description: json["description"],
    locale: json["locale"],
    type: json["type"],
    url: json["url"],
    siteName: json["site_name"],
    image: json["image"],
  );

  Map<String, dynamic> toJson() => {
    "title": title,
    "description": description,
    "locale": locale,
    "type": type,
    "url": url,
    "site_name": siteName,
    "image": image,
  };

  @override
  String toString() => toJson().toString();

}
