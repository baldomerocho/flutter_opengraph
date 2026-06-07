import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opengraph/opengraph.dart';

/// Simulates a browser client: redirects are followed internally and the
/// destination is reported through [http.BaseResponseWithUrl].
class _BrowserLikeClient extends http.BaseClient {
  _BrowserLikeClient(this.finalUrl, this.html);

  final Uri finalUrl;
  final String html;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return _StreamedResponseWithUrl(
      Stream.value(utf8.encode(html)),
      200,
      headers: {'content-type': 'text/html; charset=utf-8'},
      request: request,
      url: finalUrl,
    );
  }
}

class _StreamedResponseWithUrl extends http.StreamedResponse
    implements http.BaseResponseWithUrl {
  _StreamedResponseWithUrl(super.stream, super.statusCode,
      {super.headers, super.request, required this.url});

  @override
  final Uri url;
}

/// Tests for the network options added in 1.3.0: controlled redirects with
/// final-URL propagation, scheme-less URL normalization, per-call headers
/// and cache freshness overrides. They rely on [OpengraphFetch.clientFactory]
/// to observe the requests without a real server.
void main() {
  tearDown(() {
    OpengraphFetch.clientFactory = http.Client.new;
    OpengraphFetch.maxRedirects = 7;
    OpengraphFetch.proxyUrl = null;
    OpengraphCache.clear();
    OpengraphCache.ttl = const Duration(hours: 24);
    OpengraphCache.clock = DateTime.now;
  });

  group('redirects', () {
    test('follows the chain and resolves relative images against the final url',
        () async {
      final mock = MockClient((request) async {
        switch (request.url.toString()) {
          case 'https://short.io/a':
            return http.Response('', 302, headers: {'location': '/b'});
          case 'https://short.io/b':
            return http.Response('', 301,
                headers: {'location': 'https://example.com/article'});
          case 'https://example.com/article':
            return http.Response(
                '<html><head>'
                '<meta property="og:title" content="Article">'
                '<meta property="og:image" content="/img.png">'
                '</head></html>',
                200,
                headers: {'content-type': 'text/html; charset=utf-8'});
          default:
            return http.Response('not found', 404);
        }
      });
      OpengraphFetch.clientFactory = () => mock;

      final metadata = await OpengraphFetch.extract('https://short.io/a');

      expect(metadata!.title, 'Article');
      // The relative og:image resolves against the redirect destination,
      // not the original short URL.
      expect(metadata.image, 'https://example.com/img.png');
    });

    test('throws after exceeding maxRedirects with throwOnError', () async {
      OpengraphFetch.maxRedirects = 2;
      var hops = 0;
      OpengraphFetch.clientFactory = () => MockClient((request) async {
            hops++;
            return http.Response('', 302, headers: {'location': '/hop$hops'});
          });

      await expectLater(
        OpengraphFetch.extract('https://loop.example.com', throwOnError: true),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('returns the fallback after exceeding maxRedirects by default',
        () async {
      OpengraphFetch.maxRedirects = 1;
      var hops = 0;
      OpengraphFetch.clientFactory = () => MockClient((request) async {
            hops++;
            return http.Response('', 302, headers: {'location': '/hop$hops'});
          });

      final metadata = await OpengraphFetch.extract('https://loop.example.com');

      expect(metadata!.type, 'website');
      expect(metadata.description, 'https://loop.example.com');
    });

    test('treats a 3xx without location as a final response', () async {
      OpengraphFetch.clientFactory = () => MockClient((request) async {
            return http.Response('', 302); // no location header
          });

      // Falls back instead of throwing or looping…
      final metadata =
          await OpengraphFetch.extract('https://broken.example.com');
      expect(metadata!.type, 'website');
      expect(metadata.description, 'https://broken.example.com');

      // …and surfaces the status with throwOnError.
      await expectLater(
        OpengraphFetch.extract('https://broken.example.com',
            throwOnError: true),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('follows https→http downgrades but drops sensitive headers', () async {
      Map<String, String>? finalHeaders;
      OpengraphFetch.clientFactory = () => MockClient((request) async {
            switch (request.url.toString()) {
              case 'https://secure.example.com/a':
                return http.Response('', 302,
                    headers: {'location': 'http://legacy.example.com/b'});
              case 'http://legacy.example.com/b':
                finalHeaders = request.headers;
                return http.Response(
                    '<html><head>'
                    '<meta property="og:title" content="Legacy">'
                    '</head></html>',
                    200,
                    headers: {'content-type': 'text/html; charset=utf-8'});
              default:
                return http.Response('not found', 404);
            }
          });

      final metadata = await OpengraphFetch.extract(
          'https://secure.example.com/a',
          headers: {'Authorization': 'Bearer secret', 'Cookie': 'session=1'});

      // The downgrade is followed (like browsers do)…
      expect(metadata!.title, 'Legacy');
      // …but credentials do not leak across origins.
      expect(finalHeaders!.containsKey('Authorization'), isFalse);
      expect(finalHeaders!.containsKey('Cookie'), isFalse);
      expect(finalHeaders!['User-Agent'], contains('FlutterOpengraph'));
    });

    test('keeps headers across same-origin redirects', () async {
      Map<String, String>? finalHeaders;
      OpengraphFetch.clientFactory = () => MockClient((request) async {
            if (request.url.path == '/a') {
              return http.Response('', 302, headers: {'location': '/b'});
            }
            finalHeaders = request.headers;
            return http.Response(
                '<html><head>'
                '<meta property="og:title" content="Same">'
                '</head></html>',
                200,
                headers: {'content-type': 'text/html; charset=utf-8'});
          });

      await OpengraphFetch.extract('https://same.example.com/a',
          headers: {'Authorization': 'Bearer secret'});

      expect(finalHeaders!['Authorization'], 'Bearer secret');
    });

    test('uses the response-reported final url when the client exposes it',
        () async {
      // Browsers follow redirects internally and report the destination via
      // the response; relative images must resolve against it.
      OpengraphFetch.clientFactory = () => _BrowserLikeClient(
            Uri.parse('https://destination.example.com/article'),
            '<html><head>'
            '<meta property="og:image" content="/img.png">'
            '</head></html>',
          );

      final metadata = await OpengraphFetch.extract('https://short.io/x');

      expect(metadata!.image, 'https://destination.example.com/img.png');
    });
  });

  group('url normalization', () {
    test('fetches scheme-less urls over https', () async {
      Uri? requested;
      OpengraphFetch.clientFactory = () => MockClient((request) async {
            requested = request.url;
            return http.Response(
                '<html><head><meta property="og:title" content="Normalized">'
                '</head></html>',
                200,
                headers: {'content-type': 'text/html; charset=utf-8'});
          });

      final metadata = await OpengraphFetch.extract('www.example.com/page');

      expect(requested, Uri.parse('https://www.example.com/page'));
      expect(metadata!.title, 'Normalized');
    });

    test('caches scheme-less urls under the normalized key', () async {
      OpengraphFetch.clientFactory = () => MockClient((request) async {
            return http.Response(
                '<html><head><meta property="og:title" content="T"></head></html>',
                200,
                headers: {'content-type': 'text/html; charset=utf-8'});
          });

      await opengraph_fetch('example.com');

      expect(OpengraphCache.get('https://example.com'), isNotNull);
    });
  });

  group('per-call headers', () {
    test('merges headers over the defaults for a single call', () async {
      Map<String, String>? seen;
      OpengraphFetch.clientFactory = () => MockClient((request) async {
            seen = request.headers;
            return http.Response('<html></html>', 200,
                headers: {'content-type': 'text/html; charset=utf-8'});
          });

      await OpengraphFetch.extract('https://example.com',
          headers: {'Accept-Language': 'es'});

      expect(seen!['Accept-Language'], 'es');
      // Defaults are preserved underneath the per-call headers.
      expect(seen!['User-Agent'], contains('FlutterOpengraph'));
    });

    test('opengraph_fetch forwards per-call headers to the request', () async {
      Map<String, String>? seen;
      OpengraphFetch.clientFactory = () => MockClient((request) async {
            seen = request.headers;
            return http.Response(
                '<html><head><meta property="og:title" content="T"></head></html>',
                200,
                headers: {'content-type': 'text/html; charset=utf-8'});
          });

      await opengraph_fetch('https://headers.example.com',
          headers: {'Authorization': 'Bearer token'});

      expect(seen!['Authorization'], 'Bearer token');
    });
  });

  group('proxyUrl', () {
    test('routes the request through a {url} template proxy', () async {
      Uri? requested;
      OpengraphFetch.proxyUrl = 'https://proxy.example.com/?url={url}';
      OpengraphFetch.clientFactory = () => MockClient((request) async {
            requested = request.url;
            return http.Response(
                '<html><head><meta property="og:title" content="P"></head></html>',
                200,
                headers: {'content-type': 'text/html; charset=utf-8'});
          });

      final metadata = await OpengraphFetch.extract('https://target.com/page');

      expect(
          requested,
          Uri.parse('https://proxy.example.com/'
              '?url=${Uri.encodeComponent('https://target.com/page')}'));
      expect(metadata!.title, 'P');
    });

    test('appends the encoded url to a plain prefix proxy', () async {
      Uri? requested;
      OpengraphFetch.proxyUrl = 'https://proxy.example.com/fetch?u=';
      OpengraphFetch.clientFactory = () => MockClient((request) async {
            requested = request.url;
            return http.Response('<html></html>', 200,
                headers: {'content-type': 'text/html; charset=utf-8'});
          });

      await OpengraphFetch.extract('https://target.com');

      expect(
          requested,
          Uri.parse('https://proxy.example.com/fetch'
              '?u=${Uri.encodeComponent('https://target.com')}'));
    });

    test('keeps the target url for relative image resolution', () async {
      OpengraphFetch.proxyUrl = 'https://proxy.example.com/?url={url}';
      OpengraphFetch.clientFactory = () => MockClient((request) async {
            return http.Response(
                '<html><head>'
                '<meta property="og:image" content="/img.png">'
                '</head></html>',
                200,
                headers: {'content-type': 'text/html; charset=utf-8'});
          });

      final metadata = await OpengraphFetch.extract('https://target.com/page');

      // Relative images resolve against the target, not the proxy.
      expect(metadata!.image, 'https://target.com/img.png');
    });

    test('re-proxies each hop of a passed-through redirect chain', () async {
      final requested = <Uri>[];
      OpengraphFetch.proxyUrl = 'https://proxy.example.com/?url={url}';
      OpengraphFetch.clientFactory = () => MockClient((request) async {
            requested.add(request.url);
            if (requested.length == 1) {
              // The proxy passes the target's redirect through.
              return http.Response('', 302,
                  headers: {'location': '/final-page'});
            }
            return http.Response(
                '<html><head>'
                '<meta property="og:title" content="Destination">'
                '</head></html>',
                200,
                headers: {'content-type': 'text/html; charset=utf-8'});
          });

      final metadata = await OpengraphFetch.extract('https://target.com/short');

      // The relative location resolves against the TARGET and the next hop
      // goes through the proxy again.
      expect(
          requested[1],
          Uri.parse('https://proxy.example.com/'
              '?url=${Uri.encodeComponent('https://target.com/final-page')}'));
      expect(metadata!.title, 'Destination');
    });

    test('ignores the response-reported url when a proxy is configured',
        () async {
      // A browser-like client reports the PROXY url as the final one;
      // relative images must still resolve against the target.
      OpengraphFetch.proxyUrl = 'https://proxy.example.com/?url={url}';
      OpengraphFetch.clientFactory = () => _BrowserLikeClient(
            Uri.parse('https://proxy.example.com/?url=whatever'),
            '<html><head>'
            '<meta property="og:image" content="/img.png">'
            '</head></html>',
          );

      final metadata = await OpengraphFetch.extract('https://target.com/page');

      expect(metadata!.image, 'https://target.com/img.png');
    });
  });

  group('image content types', () {
    test('direct image urls keep the images.first invariant', () async {
      OpengraphFetch.clientFactory = () => MockClient((request) async {
            return http.Response.bytes(const [1, 2, 3], 200,
                headers: {'content-type': 'image/png'});
          });

      final metadata =
          await OpengraphFetch.extract('https://cdn.example.com/x.png');

      expect(metadata!.image, 'https://cdn.example.com/x.png');
      // images.first must be usable whenever image is.
      expect(metadata.images.single.url, 'https://cdn.example.com/x.png');
    });
  });

  group('cache freshness', () {
    test('refetches when the cached entry is older than maxAge', () async {
      var current = DateTime(2026, 1, 1);
      OpengraphCache.clock = () => current;
      var calls = 0;
      OpengraphFetch.clientFactory = () => MockClient((request) async {
            calls++;
            return http.Response(
                '<html><head>'
                '<meta property="og:title" content="Fresh $calls">'
                '</head></html>',
                200,
                headers: {'content-type': 'text/html; charset=utf-8'});
          });

      final first = await opengraph_fetch('https://ttl.example.com');
      current = current.add(const Duration(hours: 2));
      final second = await opengraph_fetch('https://ttl.example.com',
          maxAge: const Duration(hours: 1));

      expect(calls, 2);
      expect(first!.title, 'Fresh 1');
      expect(second!.title, 'Fresh 2');
    });
  });
}
