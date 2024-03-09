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

abstract class OpenGraphRequestInterface {
  Future<OpenGraphEntity?> fetch(String url);
  void initProvider(OpenGraphCredentials credentials);
}

class OpenGraphRequest implements OpenGraphRequestInterface {
  static final OpenGraphRequest _instance = OpenGraphRequest._internal();

  factory OpenGraphRequest() => _instance;

  OpenGraphRequest._internal();
  Map<String, OpenGraphEntity> urls = {};
  int _maxObjects = 1000;

  OpenGraphCredentials? _credentials;

  // Inicializa el proveedor con la URL
  @override
  void initProvider(OpenGraphCredentials credentials) {
    _credentials = credentials;
    _maxObjects = credentials.maxObjects;
  }

  @override
  Future<OpenGraphEntity?> fetch(String url) async {
    url = encodeBase64(url);
    if (findObjectOnList(url) != null) {
      return findObjectOnList(url);
    }
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
      return null;
    }
  }

  void overrideObjectOnList(OpenGraphEntity object, String id) =>
      urls[id] = object;

  OpenGraphEntity? findObjectOnList(String id) {
    final object = urls[id];
    if (object != null) return OpenGraphEntity.fromJson(object.toJson());
    return null;
  }

  void clearList() => urls.clear();
  void maxObjects() {
    if (urls.length > _maxObjects) {
      urls.remove(urls.keys.first);
    }
  }
}

String encodeBase64(string) {
  return base64.encode(utf8.encode(string));
}
