import 'dart:convert';

import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:string_validator/string_validator.dart' as validator;

extension GetMethod on Map {
  String? get(dynamic key) {
    if (!containsKey(key) || this[key] == null) return null;
    var value = this[key];
    if (value is List) return value.isNotEmpty ? value.first.toString() : null;
    return value.toString();
  }

  dynamic getDynamic(dynamic key) {
    return this[key];
  }
}

String? getDomain(String url) {
  try {
    return Uri.parse(url).host.toString().split('.')[0];
  } catch (e) {
    return null;
  }
}

/// Matches an explicit URI scheme such as `https://` or `ftp://`.
final RegExp _schemePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*://');

/// Matches a scheme without `//` (`mailto:`, `tel:`, `data:`…), which is
/// not a fetchable web URL. A digit right after the colon means the colon
/// separates host and port (`example.com:8080`), not a scheme.
final RegExp _explicitSchemePattern =
    RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*:(?![0-9])');

/// Normalizes a user-provided [url] so it can be fetched.
///
/// Trims whitespace and prepends `https://` when the scheme is missing, so
/// inputs like `www.example.com` or `example.com/page` become fetchable
/// instead of failing with "No host specified". Returns `null` when the
/// result is not a valid http(s) URL, including explicit non-web schemes
/// such as `mailto:` or `ftp://`.
String? normalizeUrl(String url) {
  var normalized = url.trim();
  if (normalized.isEmpty) return null;
  if (!_schemePattern.hasMatch(normalized)) {
    if (_explicitSchemePattern.hasMatch(normalized)) return null;
    normalized = 'https://$normalized';
  }
  final uri = Uri.tryParse(normalized);
  if (uri == null || uri.host.isEmpty) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (!validator.isURL(normalized)) return null;
  return normalized;
}

/// Extracts the charset parameter of a Content-Type header value.
final RegExp _charsetInContentType =
    RegExp(r'''charset=["']?([\w\-]+)''', caseSensitive: false);

/// Extracts the charset declared by `<meta charset>` or
/// `<meta http-equiv="Content-Type">` in the document head.
final RegExp _charsetInMetaTag =
    RegExp(r'''<meta[^>]+charset=["']?([\w\-]+)''', caseSensitive: false);

/// Decodes the [response] body honoring the declared charset instead of
/// assuming UTF-8, so pages served as latin1/windows-1252 do not turn into
/// mojibake or a decode failure.
///
/// Resolution order: `charset` from the Content-Type header, then a
/// `<meta charset>` sniff over the first bytes of the body, then UTF-8.
/// Decode errors fall back to UTF-8 with malformed bytes allowed, so a bad
/// declaration never loses the whole page to a [FormatException].
String decodeBody(http.Response response) {
  final bytes = response.bodyBytes;
  var charset = _charsetInContentType
      .firstMatch(response.headers['content-type'] ?? '')
      ?.group(1);
  if (charset == null) {
    // latin1 maps every byte, so this sniff pass can never throw.
    final head =
        latin1.decode(bytes.length > 1024 ? bytes.sublist(0, 1024) : bytes);
    charset = _charsetInMetaTag.firstMatch(head)?.group(1);
  }
  try {
    return _encodingFor(charset).decode(bytes);
  } on FormatException {
    return utf8.decode(bytes, allowMalformed: true);
  }
}

Encoding _encodingFor(String? charset) {
  if (charset == null) return utf8;
  final encoding = Encoding.getByName(charset);
  if (encoding != null) return encoding;
  // windows-1252 is a latin1 superset; decoding it as latin1 only swaps a
  // handful of punctuation characters, far better than mojibake.
  final lower = charset.toLowerCase();
  if (lower == 'windows-1252' || lower == 'cp1252' || lower == 'cp-1252') {
    return latin1;
  }
  return utf8;
}

String? getProperty(
  Document? document, {
  String tag = 'meta',
  String attribute = 'property',
  String? property,
  String key = 'content',
}) {
  if (document == null || property == null) return null;

  try {
    return document
        .getElementsByTagName(tag)
        .cast<Element?>()
        .firstWhere((element) => element?.attributes[attribute] == property,
            orElse: () => null)
        ?.attributes[key];
  } catch (e) {
    return null;
  }
}
