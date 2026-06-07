import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:opengraph/src/utils/util.dart';

void main() {
  group('normalizeUrl', () {
    test('prepends https to scheme-less urls', () {
      expect(normalizeUrl('www.example.com'), 'https://www.example.com');
      expect(
          normalizeUrl('example.com/page?q=1'), 'https://example.com/page?q=1');
    });

    test('trims surrounding whitespace', () {
      expect(normalizeUrl('  https://example.com  '), 'https://example.com');
    });

    test('keeps explicit http and https schemes untouched', () {
      expect(normalizeUrl('http://example.com'), 'http://example.com');
      expect(normalizeUrl('https://example.com/a'), 'https://example.com/a');
    });

    test('rejects non-http schemes', () {
      expect(normalizeUrl('ftp://example.com'), isNull);
    });

    test('rejects explicit non-web schemes without //', () {
      expect(normalizeUrl('mailto:user@example.com'), isNull);
      expect(normalizeUrl('tel:+34600111222'), isNull);
      expect(normalizeUrl('data:text/html,hello'), isNull);
    });

    test('treats host:port as a missing scheme, not a scheme', () {
      expect(normalizeUrl('example.com:8080/path'),
          'https://example.com:8080/path');
    });

    test('rejects invalid input', () {
      expect(normalizeUrl(''), isNull);
      expect(normalizeUrl('   '), isNull);
      expect(normalizeUrl('not a url'), isNull);
      expect(normalizeUrl('x'), isNull);
    });

    test('accepts ip hosts with ports', () {
      expect(
          normalizeUrl('http://127.0.0.1:8080/og'), 'http://127.0.0.1:8080/og');
    });
  });

  group('decodeBody', () {
    test('uses the charset from the content-type header', () {
      final response = http.Response.bytes(
          latin1.encode('<html><head><title>Iñtërnâtiônàl</title></head>'), 200,
          headers: {'content-type': 'text/html; charset=ISO-8859-1'});

      expect(decodeBody(response), contains('Iñtërnâtiônàl'));
    });

    test('handles a quoted charset in the content-type header', () {
      final response = http.Response.bytes(
          latin1.encode('<title>año</title>'), 200,
          headers: {'content-type': 'text/html; charset="iso-8859-1"'});

      expect(decodeBody(response), contains('año'));
    });

    test('sniffs the meta charset when the header has none', () {
      const html = '<html><head><meta charset="iso-8859-1">'
          '<title>café</title></head></html>';
      final response = http.Response.bytes(latin1.encode(html), 200,
          headers: {'content-type': 'text/html'});

      expect(decodeBody(response), contains('café'));
    });

    test('sniffs the http-equiv content-type charset', () {
      const html = '<html><head><meta http-equiv="Content-Type" '
          'content="text/html; charset=iso-8859-1">'
          '<title>señal</title></head></html>';
      final response = http.Response.bytes(latin1.encode(html), 200,
          headers: {'content-type': 'text/html'});

      expect(decodeBody(response), contains('señal'));
    });

    test('treats windows-1252 as latin1', () {
      final response = http.Response.bytes(
          latin1.encode('<title>café</title>'), 200,
          headers: {'content-type': 'text/html; charset=windows-1252'});

      expect(decodeBody(response), contains('café'));
    });

    test('defaults to utf-8 without any charset declaration', () {
      final response = http.Response.bytes(
          utf8.encode('<title>día</title>'), 200,
          headers: {'content-type': 'text/html'});

      expect(decodeBody(response), contains('día'));
    });

    test('never throws on bytes that do not match the charset', () {
      final response = http.Response.bytes(const [0xFF, 0xFE, 0x41], 200,
          headers: {'content-type': 'text/html; charset=utf-8'});

      expect(() => decodeBody(response), returnsNormally);
      expect(decodeBody(response), contains('A'));
    });

    test('unknown charsets fall back to utf-8', () {
      final response = http.Response.bytes(
          utf8.encode('<title>plain</title>'), 200,
          headers: {'content-type': 'text/html; charset=shift_jis'});

      expect(decodeBody(response), contains('plain'));
    });
  });
}
