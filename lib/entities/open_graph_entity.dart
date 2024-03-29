import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'open_graph_entity.freezed.dart';
part 'open_graph_entity.g.dart';

/// OpenGraphEntity represents the OpenGraph protocol
/// Properties:
/// - title: Site title, example: "Open Graph protocol"
/// - description: Site description, example: "The Open Graph protocol enables any web page to become a rich object in a social graph."
/// - locale: Site locale, example: "en_US"
/// - type: Site type, example: "website"
/// - url: Site url, example: "http://ogp.me/"
/// - siteName: Site name, example: "Open Graph protocol"
/// - image: Site image, example: "http://ogp.me/logo.png"
@freezed
class OpenGraphEntity with _$OpenGraphEntity {
  // OpenGraphEntity({
  //   required this.title,
  //   required this.description,
  //   required this.locale,
  //   required this.type,
  //   required this.url,
  //   required this.siteName,
  //   required this.image,
  // });

  factory OpenGraphEntity({
    required String title,
    required String description,
    required String locale,
    required String type,
    required String url,
    required String siteName,
    required String image,
  }) = _OpenGraphEntity;

  /// Create OpenGraphEntity from json
  factory OpenGraphEntity.fromJson(Map<String, dynamic> json) =>
      _$OpenGraphEntityFromJson(json);
}
