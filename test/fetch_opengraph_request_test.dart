// The legacy OpenGraphRequest API is deprecated but still supported; these
// tests keep covering it until its removal in 2.0.0.
// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opengraph/opengraph.dart';

MockClient _htmlClient(String html, {int statusCode = 200}) {
  return MockClient((request) async => http.Response(html, statusCode,
      headers: {'content-type': 'text/html; charset=utf-8'}));
}

void main() {
  setUp(() {
    OpenGraphRequest().clearList();
    OpenGraphRequest().initProvider(OpenGraphConfiguration(maxObjects: 1000));
  });

  tearDown(() {
    OpenGraphRequest().clearList();
    OpenGraphRequest().client = http.Client();
  });

  group('OpenGraphConfiguration', () {
    test('toString includes maxObjects', () {
      expect(OpenGraphConfiguration(maxObjects: 5).toString(),
          'OpenGraphConfiguration(maxObjects: 5)');
    });
  });

  group('OpenGraphRequest fetch (legacy API)', () {
    test('parses og meta tags from the response', () async {
      final request = OpenGraphRequest();
      request.client = _htmlClient('''
        <html><head>
          <meta property="og:title" content="OG Title">
          <meta property="og:description" content="OG Description">
          <meta property="og:image" content="https://example.com/image.png">
          <meta property="og:url" content="https://example.com/page">
          <meta property="og:locale" content="es_MX">
          <meta property="og:type" content="article">
          <meta property="og:site_name" content="Example Site">
        </head><body></body></html>
      ''');

      final entity = await request.fetch('https://example.com');

      expect(entity.title, 'OG Title');
      expect(entity.description, 'OG Description');
      expect(entity.image, 'https://example.com/image.png');
      expect(entity.url, 'https://example.com/page');
      expect(entity.locale, 'es_MX');
      expect(entity.type, 'article');
      expect(entity.siteName, 'Example Site');
    });

    test('falls back to title tag and meta description', () async {
      final request = OpenGraphRequest();
      request.client = _htmlClient('''
        <html><head>
          <title>Plain Title</title>
          <meta name="DESCRIPTION" content="Plain description">
        </head><body><p>hello</p></body></html>
      ''');

      final entity = await request.fetch('https://plain.example.com/post');

      expect(entity.title, 'Plain Title');
      // The uppercase meta name is normalized to lowercase before lookup
      expect(entity.description, 'Plain description');
      expect(entity.image, '');
      // Without og:url the requested url is used
      expect(entity.url, 'https://plain.example.com/post');
      expect(entity.locale, '');
      expect(entity.type, '');
      expect(entity.siteName, '');
    });

    test('returns an empty entity when the request throws', () async {
      final request = OpenGraphRequest();
      request.client = MockClient((request) async {
        throw http.ClientException('network down');
      });

      final entity = await request.fetch('https://unreachable.example.com');

      expect(entity.title, '');
      expect(entity.description, '');
      expect(entity.url, 'https://unreachable.example.com');
    });

    test('evicts the oldest entry beyond maxObjects', () async {
      final request = OpenGraphRequest();
      request.initProvider(OpenGraphConfiguration(maxObjects: 1));
      request.client =
          _htmlClient('<html><head><meta property="og:title" content="T">'
              '<meta property="og:description" content="D"></head></html>');

      await request.fetch('https://first.example.com');
      await request.fetch('https://second.example.com');

      expect(request.urls.length, 1);
    });

    test('findObjectOnList returns an empty entity for unknown ids', () {
      final request = OpenGraphRequest();
      final id = base64.encode(utf8.encode('https://unknown.example.com'));

      final entity = request.findObjectOnList(id);

      expect(entity.title, '');
      expect(entity.description, '');
      expect(entity.url, 'https://unknown.example.com');
    });

    test('sends the configured request headers', () async {
      final request = OpenGraphRequest();
      Map<String, String>? seen;
      request.client = MockClient((req) async {
        seen = req.headers;
        return http.Response('<html></html>', 200,
            headers: {'content-type': 'text/html; charset=utf-8'});
      });

      await request.fetch('https://headers.example.com');

      expect(seen!['User-Agent'], contains('FlutterOpengraph'));
    });

    test('caches entities even when the page has no description', () async {
      final request = OpenGraphRequest();
      var calls = 0;
      request.client = MockClient((req) async {
        calls++;
        return http.Response(
            '<html><head><title>No description</title></head></html>', 200,
            headers: {'content-type': 'text/html; charset=utf-8'});
      });

      await request.fetch('https://nodesc.example.com');
      await request.fetch('https://nodesc.example.com');

      expect(calls, 1);
    });

    test('returns the cached entity without refetching', () async {
      final request = OpenGraphRequest();
      var calls = 0;
      request.client = MockClient((req) async {
        calls++;
        return http.Response(
            '<html><head><meta property="og:title" content="Cached">'
            '<meta property="og:description" content="D"></head></html>',
            200,
            headers: {'content-type': 'text/html; charset=utf-8'});
      });

      await request.fetch('https://cacheable.example.com');
      final second = await request.fetch('https://cacheable.example.com');

      expect(calls, 1);
      expect(second.title, 'Cached');
    });
  });
}
