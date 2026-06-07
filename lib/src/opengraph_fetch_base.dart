import 'dart:async';

import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:opengraph/src/parsers/parsers.dart';
import 'package:opengraph/src/utils/util.dart';

class OpengraphFetch {
  /// Maximum time to wait for the page before giving up, so a slow URL does
  /// not keep a preview spinner hanging forever. Covers the whole redirect
  /// chain, not each hop individually.
  static Duration timeout = const Duration(seconds: 10);

  /// Maximum number of HTTP redirects (301/302/303/307/308) followed before
  /// giving up on a URL. Shortened links sometimes chain several hops.
  static int maxRedirects = 7;

  /// Headers sent with every request. Some sites only serve metadata to
  /// known crawlers or block Dart's default user agent; override this if
  /// you need different headers, or pass per-call headers to [extract].
  static Map<String, String> requestHeaders = {
    'User-Agent':
        'Mozilla/5.0 (compatible; FlutterOpengraph; +https://github.com/baldomerocho/flutter_opengraph)',
    'Accept': 'text/html,application/xhtml+xml,*/*',
  };

  /// Creates the HTTP client used for each request. It is called once per
  /// request and the returned client is **closed** when that request
  /// completes, so it must return a fresh client on every call — never a
  /// shared or long-lived instance. Replaceable, e.g. with a MockClient
  /// from `package:http/testing.dart` in tests.
  static http.Client Function() clientFactory = http.Client.new;

  /// Fetches a [url], validates it, and returns [OpengraphMetadata].
  ///
  /// The URL is normalized first: a missing scheme gets `https://`
  /// prepended, so `www.example.com` works. Returns null for invalid URLs,
  /// including explicit non-http(s) schemes such as `mailto:` or `ftp://`.
  ///
  /// Redirects are followed up to [maxRedirects] and relative images are
  /// resolved against the final URL of the chain. On the web the browser
  /// follows redirects itself; the final URL is still picked up from the
  /// response when the platform exposes it. Sensitive headers
  /// (Authorization, Cookie) are dropped on cross-origin hops.
  ///
  /// [headers] are merged over [requestHeaders] for this call only, e.g.
  /// for per-site authentication or an Accept-Language.
  ///
  /// On fetch errors (network failure, timeout, non-200 response) it returns
  /// a fallback metadata built from the URL. Pass [throwOnError] to propagate
  /// those errors to the caller instead.
  static Future<OpengraphMetadata?> extract(String url,
      {bool throwOnError = false, Map<String, String>? headers}) async {
    final normalized = normalizeUrl(url);
    if (normalized == null) {
      return null;
    }

    /// Sane defaults; Always return the Domain name as the [title], and a [description] for a given [url]
    final defaultOutput = OpengraphMetadata();
    defaultOutput.title = getDomain(normalized);
    defaultOutput.description = normalized;
    defaultOutput.url = normalized;
    defaultOutput.locale = 'en_US';
    defaultOutput.type = 'website';

    // Make our network call
    try {
      final result = await _get(Uri.parse(normalized), {
        ...requestHeaders,
        if (headers != null) ...headers,
      });
      final response = result.response;
      final finalUrl = result.finalUri.toString();
      final headerContentType = response.headers['content-type'];

      if (headerContentType != null &&
          headerContentType.startsWith(r'image/')) {
        defaultOutput.title = '';
        defaultOutput.description = '';
        defaultOutput.image = finalUrl;
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

      // Resolve relative images against the URL the redirects landed on,
      // not the original (possibly shortened) one.
      final data = _extractMetadata(document, url: finalUrl);
      if (data == null) {
        return defaultOutput;
      }

      return data;
    } catch (e) {
      if (throwOnError) rethrow;
      return defaultOutput;
    }
  }

  /// Status codes that redirect a GET request.
  static const Set<int> _redirectCodes = {301, 302, 303, 307, 308};

  /// Sends a GET request following redirects manually (up to [maxRedirects])
  /// so the final URL is known: `package:http` follows redirects internally
  /// but never exposes the destination, which is needed to resolve relative
  /// image paths against the real domain.
  static Future<({http.Response response, Uri finalUri})> _get(
      Uri uri, Map<String, String> headers) async {
    final client = clientFactory();
    final result = _followRedirects(client, uri, headers);
    // If the timeout below fires, the redirect chain keeps failing in the
    // background once the client closes; mark it handled so the error is
    // not reported as uncaught.
    result.ignore();
    try {
      return await result.timeout(timeout);
    } finally {
      client.close();
    }
  }

  static Future<({http.Response response, Uri finalUri})> _followRedirects(
      http.Client client, Uri uri, Map<String, String> headers) async {
    var current = uri;
    var currentHeaders = headers;
    for (var redirects = 0;; redirects++) {
      // On platforms that cannot disable redirect following (web), the
      // client resolves the chain itself and a 3xx never reaches this loop.
      final request = http.Request('GET', current)
        ..followRedirects = false
        ..headers.addAll(currentHeaders);
      final streamed = await client.send(request);
      final response = await http.Response.fromStream(streamed);
      final location = response.headers['location'];
      if (!_redirectCodes.contains(response.statusCode) || location == null) {
        // Clients that know the URL they actually responded from (the
        // browser does, after transparently following redirects) report
        // the real final URL.
        if (streamed case http.BaseResponseWithUrl(:final url)) {
          current = url;
        }
        return (response: response, finalUri: current);
      }
      if (redirects >= maxRedirects) {
        throw http.ClientException(
            'Too many redirects (more than $maxRedirects) fetching $uri',
            current);
      }
      final next = current.resolve(location);
      // Redirects are followed across origins — https→http downgrades
      // included, like browsers do — but credentials must not leak there:
      // drop sensitive headers and keep the safe defaults.
      if (next.scheme != current.scheme ||
          next.host != current.host ||
          next.port != current.port) {
        currentHeaders = Map.of(currentHeaders)
          ..removeWhere((key, _) {
            final lower = key.toLowerCase();
            return lower == 'authorization' || lower == 'cookie';
          });
      }
      current = next;
    }
  }

  /// Takes an [http.Response] and returns a [html.Document]
  static Document? responseToDocument(http.Response response) {
    if (response.statusCode != 200) {
      return null;
    }

    Document? document;
    try {
      document = parser.parse(decodeBody(response));
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
