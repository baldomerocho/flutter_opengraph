import 'dart:convert';
import 'dart:io';

import 'package:opengraph/entities/open_graph_entity.dart';


class OpenGraphRequest{
  static final OpenGraphRequest _instance = OpenGraphRequest._internal();

  factory OpenGraphRequest() => _instance;

  OpenGraphRequest._internal();

  String? _provider;

  // Inicializa el proveedor con la URL
  void initProvider(String url) {
    _provider = url;
  }

  Future<OpenGraphEntity> fetch(String url) async {
    final String url0 = "$_provider$url";
    final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url0));
      final response = await request.close();

      if (response.statusCode == HttpStatus.ok) {
        final responseBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody);
        httpClient.close();
        return OpenGraphEntity.fromJson(json["data"]);
      } else {
        return OpenGraphEntity.fromJson({
          "title": "",
          "description": "",
          "locale": "",
          "type": "",
          "url": "",
          "site_name": "",
          "updated_time": "",
          "image": "",
          "image_secure_url": "",
          "image_width": "",
          "image_height": "",
          "image_alt": "",
          "image_type": "",
          "twitter_card": "",
          "twitter_title": "",
          "twitter_description": "",
          "twitter_site": ""
        });
      }
  }

}