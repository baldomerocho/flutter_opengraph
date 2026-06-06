import 'package:html/dom.dart';
import 'package:opengraph/src/utils/util.dart';

import 'base_parser.dart';
import 'opengraph_parser.dart';

/// Takes a [Document] and parses [OpengraphMetadata] from `<meta property='twitter:*'>` tags
class TwitterCardParser with BaseOpengraphParser {
  final Document? _document;
  TwitterCardParser(this._document);

  /// Get [OpengraphMetadata.title] from 'twitter:title'
  @override
  String? get title =>
      getProperty(
        _document,
        attribute: 'name',
        property: 'twitter:title',
      ) ??
      getProperty(
        _document,
        property: 'twitter:title',
      );

  /// Get [OpengraphMetadata.description] from 'twitter:description'
  @override
  String? get description =>
      getProperty(
        _document,
        attribute: 'name',
        property: 'twitter:description',
      ) ??
      getProperty(
        _document,
        property: 'twitter:description',
      );

  /// Get [OpengraphMetadata.image] from 'twitter:image'
  @override
  String? get image =>
      getProperty(
        _document,
        attribute: 'name',
        property: 'twitter:image',
      ) ??
      getProperty(
        _document,
        property: 'twitter:image',
      );

  /// Twitter Cards do not have a url property so get the url from `og:url`, if available.
  @override
  String? get url => OpengraphParser(_document).url;

  /// Default locale
  @override
  String? get locale => 'en_US';

  /// Default type
  @override
  String? get type => 'website';

  /// Get site name from twitter:site
  @override
  String? get siteName =>
      getProperty(
        _document,
        attribute: 'name',
        property: 'twitter:site',
      ) ??
      getProperty(
        _document,
        property: 'twitter:site',
      );

  @override
  String toString() => parse().toString();
}
