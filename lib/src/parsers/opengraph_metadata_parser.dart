// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:html/dom.dart';
import 'package:opengraph/src/models/og_media.dart';
import 'base_parser.dart';
import 'favicon_parser.dart';
import 'htmlmeta_parser.dart';
import 'jsonld_parser.dart';
import 'opengraph_parser.dart';
import 'twittercard_parser.dart';

/// Does Works with `BaseOpengraphParser`
class OpengraphMetadataParser {
  /// This is the default strategy for building our [OpengraphMetadata]
  ///
  /// It tries [OpengraphParser], then [TwitterCardParser], then [JsonLdParser], and falls back to [HtmlMetaParser] tags for missing data.
  /// The favicon ([FaviconParser]) is extracted as well and used as the
  /// last-resort image when no other format provides one.
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
      if (output.images.isEmpty) output.images = p.images;
      if (output.videos.isEmpty) output.videos = p.videos;
      if (output.audios.isEmpty) output.audios = p.audios;
      if (output.structuredTags.isEmpty) {
        output.structuredTags = p.structuredTags;
      }

      if (output.hasAllMetadata) {
        break;
      }
    }

    // Pages may declare images only as structured objects (og:image:url
    // without og:image): backfill the scalar from them before any favicon
    // fallback, so image and images.first stay in sync both ways.
    if ((output.image == null || output.image!.isEmpty) &&
        output.images.isNotEmpty) {
      output.image = output.images.first.url;
    }

    // The favicon is the last image fallback: better a recognizable site
    // icon than the bundled placeholder.
    output.faviconUrl = FaviconParser(document).faviconUrl;
    output.image ??= output.faviconUrl;

    // If the parsers did not extract a URL from the metadata, use the given
    // url, if available. This is used to attempt to resolve relative images.
    final _url = output.url ?? url;
    if (_url != null) {
      String resolve(String value) {
        if (value.isEmpty ||
            value.startsWith('http') ||
            value.startsWith('data:')) {
          return value;
        }
        try {
          return Uri.parse(_url).resolve(value).toString();
        } catch (e) {
          // Keep the original value if there's an error resolving it
          return value;
        }
      }

      final image = output.image;
      if (image != null) output.image = resolve(image);
      final favicon = output.faviconUrl;
      if (favicon != null) output.faviconUrl = resolve(favicon);
      output.images = output.images
          .map((i) => i.copyWith(
                url: resolve(i.url),
                secureUrl: i.secureUrl == null ? null : resolve(i.secureUrl!),
              ))
          .toList();
      output.videos = output.videos
          .map((v) => v.copyWith(
                url: resolve(v.url),
                secureUrl: v.secureUrl == null ? null : resolve(v.secureUrl!),
              ))
          .toList();
      output.audios = output.audios
          .map((a) => a.copyWith(
                url: resolve(a.url),
                secureUrl: a.secureUrl == null ? null : resolve(a.secureUrl!),
              ))
          .toList();
    }

    // Keep `images` usable even when the image came from a non-OG format:
    // `images.first` then carries the same URL as `image`.
    final image = output.image;
    if (output.images.isEmpty && image != null && image.isNotEmpty) {
      output.images = [OgImage(url: image)];
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
