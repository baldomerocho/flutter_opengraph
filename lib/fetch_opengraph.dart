import 'dart:convert';
import 'dart:io';

import 'package:opengraph/entities/open_graph_entity.dart';

abstract class OpenGraphRequestInterface {
  Future<OpenGraphEntity?> fetch(String url);
  void initProvider(String url);
}

class OpenGraphRequest implements OpenGraphRequestInterface{
  static final OpenGraphRequest _instance = OpenGraphRequest._internal();

  factory OpenGraphRequest() => _instance;

  OpenGraphRequest._internal();

  String? _provider;

  // Inicializa el proveedor con la URL
  @override
  void initProvider(String url) {
    _provider = url;
  }
  @override
  Future<OpenGraphEntity?> fetch(String url) async {
    url = encodeBase64(url);
    final String url0 = "$_provider$url";
    final httpClient = HttpClient();
    try{
      final request = await httpClient.getUrl(Uri.parse(url0));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final json = jsonDecode(responseBody);
      httpClient.close();
      return OpenGraphEntity.fromJson(json);
    } catch (e) {
      return null;
    }
  }

}

String encodeBase64(string) {
  return base64.encode(utf8.encode(string));
}