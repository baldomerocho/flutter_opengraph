import 'package:html/dom.dart';
import 'package:opengraph/src/utils/util.dart';

import 'base_parser.dart';

/// Takes a [Document] and parses [OpengraphMetadata] from `<meta property='og:*'>` tags
class OpengraphParser with BaseOpengraphParser {
  final Document? _document;
  OpengraphParser(this._document);

  /// Get [OpengraphMetadata.title] from 'og:title'
  @override
  String? get title => getProperty(
        _document,
        property: 'og:title',
      );

  /// Get [OpengraphMetadata.description] from 'og:description'
  @override
  String? get description => getProperty(
        _document,
        property: 'og:description',
      );

  /// Get [OpengraphMetadata.image] from 'og:image'
  @override
  String? get image => getProperty(
        _document,
        property: 'og:image',
      );

  /// Get [OpengraphMetadata.url] from 'og:url'
  @override
  String? get url => getProperty(
        _document,
        property: 'og:url',
      );

  /// Get [OpengraphMetadata.locale] from 'og:locale'
  @override
  String? get locale => getProperty(
        _document,
        property: 'og:locale',
      );

  /// Get [OpengraphMetadata.type] from 'og:type'
  @override
  String? get type => getProperty(
        _document,
        property: 'og:type',
      );

  /// Get [OpengraphMetadata.siteName] from 'og:site_name'
  @override
  String? get siteName => getProperty(
        _document,
        property: 'og:site_name',
      );

  @override
  String toString() => parse().toString();
}
