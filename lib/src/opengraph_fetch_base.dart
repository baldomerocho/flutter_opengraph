import 'dart:convert';
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:opengraph/src/parsers/parsers.dart';
import 'package:opengraph/src/utils/util.dart';
import 'package:string_validator/string_validator.dart' as validator;

class OpengraphFetch {
  /// Maximum time to wait for the page before giving up, so a slow URL does
  /// not keep a preview spinner hanging forever.
  static Duration timeout = const Duration(seconds: 10);

  /// Headers sent with every request. Some sites only serve metadata to
  /// known crawlers or block Dart's default user agent; override this if
  /// you need different headers.
  static Map<String, String> requestHeaders = {
    'User-Agent':
        'Mozilla/5.0 (compatible; FlutterOpengraph; +https://github.com/baldomerocho/flutter_opengraph)',
    'Accept': 'text/html,application/xhtml+xml,*/*',
  };

  /// Fetches a [url], validates it, and returns [OpengraphMetadata].
  ///
  /// On fetch errors (network failure, timeout, non-200 response) it returns
  /// a fallback metadata built from the URL. Pass [throwOnError] to propagate
  /// those errors to the caller instead.
  static Future<OpengraphMetadata?> extract(String url,
      {bool throwOnError = false}) async {
    if (!validator.isURL(url)) {
      return null;
    }

    /// Sane defaults; Always return the Domain name as the [title], and a [description] for a given [url]
    final defaultOutput = OpengraphMetadata();
    defaultOutput.title = getDomain(url);
    defaultOutput.description = url;
    defaultOutput.url = url;
    defaultOutput.locale = 'en_US';
    defaultOutput.type = 'website';

    // Make our network call
    try {
      final response = await http
          .get(Uri.parse(url), headers: requestHeaders)
          .timeout(timeout);
      final headerContentType = response.headers['content-type'];

      if (headerContentType != null &&
          headerContentType.startsWith(r'image/')) {
        defaultOutput.title = '';
        defaultOutput.description = '';
        defaultOutput.image = url;
        return defaultOutput;
      }

      final document = responseToDocument(response);

      if (document == null) {
        if (throwOnError) {
          throw http.ClientException(
              'Failed to fetch $url: HTTP ${response.statusCode}');
        }
        return defaultOutput;
      }

      final data = _extractMetadata(document, url: url);
      if (data == null) {
        return defaultOutput;
      }

      return data;
    } catch (e) {
      if (throwOnError) rethrow;
      return defaultOutput;
    }
  }

  /// Takes an [http.Response] and returns a [html.Document]
  static Document? responseToDocument(http.Response response) {
    if (response.statusCode != 200) {
      return null;
    }

    Document? document;
    try {
      document = parser.parse(utf8.decode(response.bodyBytes));
    } catch (err) {
      return document;
    }

    return document;
  }

  /// Returns instance of [OpengraphMetadata] with data extracted from the [html.Document]
  /// Provide a given url as a fallback when there are no Document url extracted
  /// by the parsers.
  ///
  /// Future: Can pass in a strategy i.e: to retrieve only OpenGraph, or OpenGraph and Json+LD only
  static OpengraphMetadata? _extractMetadata(Document document, {String? url}) {
    return OpengraphMetadataParser.parse(document, url: url);
  }
}
