import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:opengraph/opengraph.dart';

/// End-to-end tests for the fetch pipeline against a local HTTP server,
/// covering the network branches that cannot be reached with parsed
/// documents alone (non-200 handling, image content types, error
/// propagation with throwOnError).
void main() {
  late HttpServer server;
  late String base;

  setUp(() async {
    OpengraphCache.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = 'http://127.0.0.1:${server.port}';
    server.listen((request) async {
      final response = request.response;
      switch (request.uri.path) {
        case '/og':
          response.headers.contentType = ContentType.html;
          response.write('<html><head>'
              '<meta property="og:title" content="Server Title">'
              '<meta property="og:description" content="Server Description">'
              '<meta property="og:image" content="/relative.png">'
              '</head><body></body></html>');
          break;
        case '/image.png':
          response.headers.contentType = ContentType('image', 'png');
          response.add(const [1, 2, 3]);
          break;
        default:
          response.statusCode = HttpStatus.notFound;
      }
      await response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    OpengraphCache.clear();
  });

  group('OpengraphFetch.extract over HTTP', () {
    test('parses metadata and resolves relative images', () async {
      final metadata = await OpengraphFetch.extract('$base/og');

      expect(metadata, isNotNull);
      expect(metadata!.title, 'Server Title');
      expect(metadata.description, 'Server Description');
      expect(metadata.image, '$base/relative.png');
    });

    test('returns fallback metadata for non-200 responses by default',
        () async {
      final metadata = await OpengraphFetch.extract('$base/missing');

      expect(metadata, isNotNull);
      expect(metadata!.description, '$base/missing');
      expect(metadata.type, 'website');
    });

    test('throws on non-200 responses with throwOnError', () async {
      await expectLater(
        OpengraphFetch.extract('$base/missing', throwOnError: true),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('returns the url as image for image content types', () async {
      final metadata = await OpengraphFetch.extract('$base/image.png');

      expect(metadata, isNotNull);
      expect(metadata!.image, '$base/image.png');
      expect(metadata.title, '');
      expect(metadata.description, '');
    });
  });

  group('opengraph_fetch over HTTP', () {
    test('returns and caches the parsed entity', () async {
      final entity = await opengraph_fetch('$base/og');

      expect(entity, isNotNull);
      expect(entity!.title, 'Server Title');
      expect(OpengraphCache.get('$base/og'), isNotNull);
    });

    test('falls back to a domain entity on http errors without caching',
        () async {
      final entity = await opengraph_fetch('$base/missing');

      expect(entity, isNotNull);
      expect(entity!.description, '$base/missing');
      expect(entity.url, '$base/missing');
      // Failures must not be cached so transient errors can recover
      expect(OpengraphCache.get('$base/missing'), isNull);
    });

    test('propagates http errors with throwOnError', () async {
      await expectLater(
        opengraph_fetch('$base/missing', throwOnError: true),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('concurrent calls for the same url share one request', () async {
      final results = await Future.wait([
        opengraph_fetch('$base/og'),
        opengraph_fetch('$base/og'),
        opengraph_fetch('$base/og'),
      ]);

      expect(results.every((e) => e!.title == 'Server Title'), isTrue);
    });
  });
}
