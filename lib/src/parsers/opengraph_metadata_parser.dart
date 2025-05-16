// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:html/dom.dart';
import 'base_parser.dart';
import 'htmlmeta_parser.dart';
import 'jsonld_parser.dart';
import 'opengraph_parser.dart';
import 'twittercard_parser.dart';

/// Does Works with `BaseOpengraphParser`
class OpengraphMetadataParser {
  /// This is the default strategy for building our [OpengraphMetadata]
  ///
  /// It tries [OpengraphParser], then [TwitterCardParser], then [JsonLdParser], and falls back to [HtmlMetaParser] tags for missing data.
  /// You may optionally provide a URL to the function, used to resolve relative images or to compensate for the lack of URI identifiers
  /// from the metadata parsers.
  static OpengraphMetadata parse(Document? document, {String? url}) {
    final output = OpengraphMetadata();

    final parsers = [
      openGraph(document),
      twitterCard(document),
      jsonLdSchema(document),
      htmlMeta(document),
    ];

    for (final p in parsers) {
      output.title ??= p.title;
      output.description ??= p.description;
      output.image ??= p.image;
      output.url ??= p.url;
      output.locale ??= p.locale;
      output.type ??= p.type;
      output.siteName ??= p.siteName;

      if (output.hasAllMetadata) {
        break;
      }
    }

    // If the parsers did not extract a URL from the metadata, use the given
    // url, if available. This is used to attempt to resolve relative images.
    final _url = output.url ?? url;
    final image = output.image;
    if (_url != null &&
        image != null &&
        image.isNotEmpty &&
        !image.startsWith('http')) {
      try {
        output.image = Uri.parse(_url).resolve(image).toString();
      } catch (e) {
        // Keep the original image if there's an error resolving it
      }
    }

    return output;
  }

  static OpengraphMetadata openGraph(Document? document) {
    return OpengraphParser(document).parse();
  }

  static OpengraphMetadata htmlMeta(Document? document) {
    return HtmlMetaParser(document).parse();
  }

  static OpengraphMetadata jsonLdSchema(Document? document) {
    return JsonLdParser(document).parse();
  }

  static OpengraphMetadata twitterCard(Document? document) {
    return TwitterCardParser(document).parse();
  }
}
