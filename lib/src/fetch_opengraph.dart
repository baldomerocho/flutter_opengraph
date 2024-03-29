import 'dart:convert';
import 'dart:io';

import 'package:html/parser.dart';
import 'package:opengraph/entities/open_graph_entity.dart';

class OpenGraphConfiguration {
  final int maxObjects;

  OpenGraphConfiguration({this.maxObjects = 1000});

  @override
  String toString() {
    return "OpenGraphConfiguration(maxObjects: $maxObjects)";
  }
}

/// Interface for OpenGraphRequest
abstract class OpenGraphRequestInterface {
  /// Fetches the OpenGraph data from the given URL
  Future<OpenGraphEntity?> fetch(String url);

  /// Initializes the provider with the given credentials
  void initProvider(OpenGraphConfiguration configuration);
}

/// OpenGraphRequest is a singleton class that fetches OpenGraph data from the given URL
class OpenGraphRequest implements OpenGraphRequestInterface {
  /// Singleton instance
  static final OpenGraphRequest _instance = OpenGraphRequest._internal();

  /// Factory constructor
  factory OpenGraphRequest() => _instance;

  /// Internal constructor
  OpenGraphRequest._internal();

  /// Save temporal data of the fetched URLs
  Map<String, OpenGraphEntity> urls = {};

  /// Maximum number of objects to save
  int _maxObjects = 1000;

  /// Credentials for the OpenGraph API
  OpenGraphConfiguration? configuration;

  // Inicializa el proveedor con la URL
  @override
  void initProvider(OpenGraphConfiguration configuration) {
    _maxObjects = configuration.maxObjects;
  }

  @override
  Future<OpenGraphEntity> fetch(String url) async {
    var id = _encodeBase64(url);
    if (findObjectOnList(id).description != '') return findObjectOnList(id);
    final httpClient = HttpClient();
    try {
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final openGraph = await _obtainOpenGraph(responseBody, url);
      httpClient.close();
      overrideObjectOnList(openGraph, id);
      maxObjects();
      return openGraph;
    } catch (e) {
      return OpenGraphEntity(
          title: '',
          description: '',
          image: '',
          url: _decodeBase64(id),
          locale: 'en_US',
          type: 'website',
          siteName: '');
    }
  }

  Future<OpenGraphEntity> _obtainOpenGraph(
      String responseBody, String path) async {
    var document = parse(responseBody);
    // convierte todas las etiquetas <meta name="any"> a minuscúlas
    document.head?.querySelectorAll('meta[name]').forEach((element) {
      element.attributes['name'] =
          element.attributes['name']?.toLowerCase() ?? '';
    });
    // obten la primera imagen que encuentre
    var img = document.head?.querySelector('img');

    var title = document.head?.querySelector('meta[property="og:title"]');
    var description =
        document.head?.querySelector('meta[property="og:description"]');
    var image = document.head?.querySelector('meta[property="og:image"]');
    var url = document.head?.querySelector('meta[property="og:url"]');
    var locale = document.head?.querySelector('meta[property="og:locale"]');
    var type = document.head?.querySelector('meta[property="og:type"]');
    var siteName =
        document.head?.querySelector('meta[property="og:site_name"]');

    return OpenGraphEntity(
        title: title?.attributes['content'] ??
            document.head?.querySelector('title')?.text ??
            '',
        description: description?.attributes['content'] ??
            document.head
                ?.querySelector('meta[name="description"]')
                ?.attributes['content'] ??
            '',
        image: image?.attributes['content'] ?? img?.attributes['src'] ?? '',
        url: url?.attributes['content'] ?? path,
        locale: locale?.attributes['content'] ?? '',
        type: type?.attributes['content'] ?? '',
        siteName: siteName?.attributes['content'] ?? '');
  }

  void overrideObjectOnList(OpenGraphEntity object, String id) =>
      urls[id] = object;

  OpenGraphEntity findObjectOnList(String id) {
    final object = urls[id];
    if (object != null) return OpenGraphEntity.fromJson(object.toJson());
    return OpenGraphEntity(
        title: '',
        description: '',
        image: '',
        url: _decodeBase64(id),
        locale: 'en_US',
        type: 'website',
        siteName: '');
  }

  void clearList() => urls.clear();
  void maxObjects() {
    if (urls.length > _maxObjects) {
      urls.remove(urls.keys.first);
    }
  }
}

String _encodeBase64(string) {
  return base64.encode(utf8.encode(string));
}

String _decodeBase64(string) {
  return utf8.decode(base64.decode(string));
}
