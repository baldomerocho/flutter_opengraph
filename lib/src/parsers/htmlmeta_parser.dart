import 'package:html/dom.dart';

import 'base_parser.dart';

/// Takes a [Document] and parses [OpengraphMetadata] from [<meta>, <title>, <img>] tags
class HtmlMetaParser with BaseOpengraphParser {
  /// The [document] to be parse
  final Document? _document;

  HtmlMetaParser(this._document);

  /// Get the [OpengraphMetadata.title] from the [<title>] tag
  @override
  String? get title => _document?.head?.querySelector('title')?.text;

  /// Get the [OpengraphMetadata.description] from the <meta name="description" content=""> tag
  @override
  String? get description => _document?.head
      ?.querySelector("meta[name='description']")
      ?.attributes['content'];

  /// Get the [OpengraphMetadata.image] from the first <img> tag in the body
  @override
  String? get image => _document?.body?.querySelector('img')?.attributes['src'];

  /// Default locale
  @override
  String? get locale => 'en_US';

  /// Default type
  @override
  String? get type => 'website';

  /// Get the [OpengraphMetadata.siteName] from the domain of the URL
  @override
  String? get siteName => null;

  @override
  String toString() => parse().toString();
}
