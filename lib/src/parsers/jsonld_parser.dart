import 'dart:convert';

import 'package:html/dom.dart';
import 'package:opengraph/src/utils/util.dart';

import 'base_parser.dart';

/// Takes a [Document] and parses [OpengraphMetadata] from `json-ld` data in `<script>`
class JsonLdParser with BaseOpengraphParser {
  /// The [document] to be parse
  Document? document;
  dynamic _jsonData;

  JsonLdParser(this.document) {
    _jsonData = _parseToJson(document);
  }

  dynamic _parseToJson(Document? document) {
    final data = document?.head
        ?.querySelector("script[type='application/ld+json']")
        ?.innerHtml;
    if (data == null) {
      return null;
    }
    var d = jsonDecode(data);
    return d;
  }

  /// Get the [OpengraphMetadata.title] from the json-ld data
  @override
  String? get title {
    final data = _jsonData;
    if (data is List) {
      return data.first['name'];
    } else if (data is Map) {
      return data.get('name') ?? data.get('headline');
    }
    return null;
  }

  /// Get the [OpengraphMetadata.description] from the json-ld data
  @override
  String? get description {
    final data = _jsonData;
    if (data is List) {
      return data.first['description'] ?? data.first['headline'];
    } else if (data is Map) {
      return data.get('description') ?? data.get('headline');
    }
    return null;
  }

  /// Get the [OpengraphMetadata.image] from the json-ld data
  @override
  String? get image {
    final data = _jsonData;
    if (data is List && data.isNotEmpty) {
      return _imageResultToString(data.first['logo'] ?? data.first['image']);
    } else if (data is Map) {
      return _imageResultToString(
          data.getDynamic('logo') ?? data.getDynamic('image'));
    }

    return null;
  }

  /// Get the [OpengraphMetadata.url] from the json-ld data
  @override
  String? get url {
    final data = _jsonData;
    if (data is List) {
      return data.first['url'];
    } else if (data is Map) {
      return data.get('url');
    }
    return null;
  }

  /// Default locale
  @override
  String? get locale => 'en_US';

  /// Get the [OpengraphMetadata.type] from the json-ld data
  @override
  String? get type {
    final data = _jsonData;
    if (data is List) {
      return data.first['@type'] ?? 'website';
    } else if (data is Map) {
      return data.get('@type') ?? 'website';
    }
    return 'website';
  }

  /// Get the [OpengraphMetadata.siteName] from the json-ld data
  @override
  String? get siteName {
    final data = _jsonData;
    if (data is List) {
      return data.first['publisher']?['name'];
    } else if (data is Map) {
      final publisher = data.getDynamic('publisher');
      if (publisher is Map) {
        return publisher.get('name');
      }
    }
    return null;
  }

  String? _imageResultToString(dynamic result) {
    if (result is List && result.isNotEmpty) {
      result = result.first;
    }

    if (result is String) {
      return result;
    }

    return null;
  }

  @override
  String toString() => parse().toString();
}
