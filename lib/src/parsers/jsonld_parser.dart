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

  /// Node types that carry the metadata a preview wants, in the shapes
  /// e-commerce and news sites publish.
  static const Set<String> _preferredTypes = {
    'Article',
    'NewsArticle',
    'BlogPosting',
    'Product',
    'WebSite',
    'WebPage',
    'Organization',
    'VideoObject',
  };

  /// Reads every `application/ld+json` script in the document (head and
  /// body), traversing `@graph` containers, and picks the best node across
  /// ALL scripts: sites commonly emit one script per entity (e.g. a
  /// BreadcrumbList first and the real Article later), so the preferred
  /// node may not come from the first script. Scripts with invalid JSON
  /// are skipped.
  dynamic _parseToJson(Document? document) {
    final scripts =
        document?.querySelectorAll("script[type='application/ld+json']") ??
            const <Element>[];
    final nodes = <dynamic>[];
    for (final script in scripts) {
      dynamic decoded;
      try {
        decoded = jsonDecode(script.innerHtml);
      } on FormatException {
        continue;
      }
      final node = _selectNode(decoded);
      if (node != null) {
        nodes.add(node);
      }
    }
    for (final node in nodes) {
      if (node is Map && _isPreferredType(node['@type'])) {
        return node;
      }
    }
    return nodes.isEmpty ? null : nodes.first;
  }

  /// Picks the most relevant node: unwraps `@graph`, and inside lists
  /// prefers nodes whose `@type` is known to describe the page.
  dynamic _selectNode(dynamic data) {
    if (data is Map) {
      final graph = data['@graph'];
      if (graph is List) {
        return _selectNode(graph);
      }
      return data;
    }
    if (data is List) {
      for (final item in data) {
        if (item is Map && _isPreferredType(item['@type'])) {
          return item;
        }
      }
      for (final item in data) {
        if (item is Map) {
          return item;
        }
      }
    }
    return null;
  }

  bool _isPreferredType(dynamic type) {
    if (type is String) return _preferredTypes.contains(type);
    if (type is List) return type.any(_isPreferredType);
    return false;
  }

  /// Get the [OpengraphMetadata.title] from the json-ld data
  ///
  /// [_parseToJson] always selects a single node (Map) or null, so the
  /// getters only need to handle that shape.
  @override
  String? get title {
    final data = _jsonData;
    if (data is Map) {
      return data.get('name') ?? data.get('headline');
    }
    return null;
  }

  /// Get the [OpengraphMetadata.description] from the json-ld data
  @override
  String? get description {
    final data = _jsonData;
    if (data is Map) {
      return data.get('description') ?? data.get('headline');
    }
    return null;
  }

  /// Get the [OpengraphMetadata.image] from the json-ld data
  @override
  String? get image {
    final data = _jsonData;
    if (data is Map) {
      return _imageResultToString(
          data.getDynamic('logo') ?? data.getDynamic('image'));
    }

    return null;
  }

  /// Get the [OpengraphMetadata.url] from the json-ld data
  @override
  String? get url {
    final data = _jsonData;
    if (data is Map) {
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
    if (data is Map) {
      return data.get('@type') ?? 'website';
    }
    return 'website';
  }

  /// Get the [OpengraphMetadata.siteName] from the json-ld data
  @override
  String? get siteName {
    final data = _jsonData;
    if (data is Map) {
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
