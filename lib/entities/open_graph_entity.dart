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
  String updatedTime;
  String image;
  String imageSecureUrl;
  String imageWidth;
  String imageHeight;
  String imageAlt;
  String imageType;
  String twitterCard;
  String twitterTitle;
  String twitterDescription;
  String twitterSite;

  OpenGraphEntity({
    required this.title,
    required this.description,
    required this.locale,
    required this.type,
    required this.url,
    required this.siteName,
    required this.updatedTime,
    required this.image,
    required this.imageSecureUrl,
    required this.imageWidth,
    required this.imageHeight,
    required this.imageAlt,
    required this.imageType,
    required this.twitterCard,
    required this.twitterTitle,
    required this.twitterDescription,
    required this.twitterSite,
  });

  factory OpenGraphEntity.fromJson(Map<String, dynamic> json) => OpenGraphEntity(
    title: json["title"],
    description: json["description"],
    locale: json["locale"],
    type: json["type"],
    url: json["url"],
    siteName: json["site_name"],
    updatedTime: json["updated_time"],
    image: json["image"],
    imageSecureUrl: json["image_secure_url"],
    imageWidth: json["image_width"],
    imageHeight: json["image_height"],
    imageAlt: json["image_alt"],
    imageType: json["image_type"],
    twitterCard: json["twitter_card"],
    twitterTitle: json["twitter_title"],
    twitterDescription: json["twitter_description"],
    twitterSite: json["twitter_site"],
  );

  Map<String, dynamic> toJson() => {
    "title": title,
    "description": description,
    "locale": locale,
    "type": type,
    "url": url,
    "site_name": siteName,
    "updated_time": updatedTime,
    "image": image,
    "image_secure_url": imageSecureUrl,
    "image_width": imageWidth,
    "image_height": imageHeight,
    "image_alt": imageAlt,
    "image_type": imageType,
    "twitter_card": twitterCard,
    "twitter_title": twitterTitle,
    "twitter_description": twitterDescription,
    "twitter_site": twitterSite,
  };

  @override
  String toString() {
    return 'OpenGraphEntity{title: $title, description: $description, locale: $locale, type: $type, url: $url, siteName: $siteName, updatedTime: $updatedTime, image: $image, imageSecureUrl: $imageSecureUrl, imageWidth: $imageWidth, imageHeight: $imageHeight, imageAlt: $imageAlt, imageType: $imageType, twitterCard: $twitterCard, twitterTitle: $twitterTitle, twitterDescription: $twitterDescription, twitterSite: $twitterSite}';
  }

}
