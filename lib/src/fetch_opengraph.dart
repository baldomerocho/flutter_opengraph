import 'dart:convert';
import 'dart:io';

import 'package:opengraph/entities/open_graph_entity.dart';

class OpenGraphCredentials {
  final String url;
  final String token;
  final int maxObjects;

  OpenGraphCredentials(
      {required this.url, required this.token, this.maxObjects = 1000});

  @override
  String toString() {
    return "OpenGraphCredentials(url: $url, token: $token, maxObjects: $maxObjects)";
  }
}

/// Interface for OpenGraphRequest
abstract class OpenGraphRequestInterface {
  /// Fetches the OpenGraph data from the given URL
  Future<OpenGraphEntity?> fetch(String url);

  /// Initializes the provider with the given credentials
  void initProvider(OpenGraphCredentials credentials);
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
  OpenGraphCredentials? _credentials;

  // Inicializa el proveedor con la URL
  @override
  void initProvider(OpenGraphCredentials credentials) {
    _credentials = credentials;
    _maxObjects = credentials.maxObjects;
  }

  @override
  Future<OpenGraphEntity> fetch(String url) async {
    url = _encodeBase64(url);
    if (findObjectOnList(url).description != '') return findObjectOnList(url);
    final String url0 = "${_credentials!.url}$url";
    final httpClient = HttpClient();
    try {
      final request = await httpClient.getUrl(Uri.parse(url0));
      request.headers.add(
          HttpHeaders.authorizationHeader, "Bearer ${_credentials!.token}");
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final json = jsonDecode(responseBody);
      httpClient.close();
      overrideObjectOnList(OpenGraphEntity.fromJson(json), url);
      maxObjects();
      return OpenGraphEntity.fromJson(json);
    } catch (e) {
      return OpenGraphEntity(
          title: '',
          description: '',
          image: '',
          url: _decodeBase64(url),
          locale: 'en_US',
          type: 'website',
          siteName: '');
    }
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
