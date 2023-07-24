import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengraph/entities/open_graph_entity.dart';
import 'package:opengraph/fetch_opengraph.dart';

import 'package:opengraph/opengraph.dart';

// Creamos MockOpenGraphRequest que hereda de OpenGraphRequestInterface
class MockOpenGraphRequest implements OpenGraphRequestInterface {
  String? _provider;

  @override
  void initProvider(String url) {
    _provider = url;
  }

  @override
  Future<OpenGraphEntity?> fetch(String url) async {
    if(_provider == "https://example.com"){
      return OpenGraphEntity.fromJson(
          {
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
          }
      );
    }
    if (_provider != "https://example.com?url=") {
      return throw HttpException("Error on fetch OpenGraph");
    }
    return OpenGraphEntity.fromJson(
        {
          "title": "Example Domain",
          "description": "The description for Example Domain",
          "locale": "es_ES",
          "type": "website",
          "url": "https://delemp.com/",
          "site_name": "delEmperador",
          "updated_time": "2023-05-31T13:41:30-06:00",
          "image": "https://delemp.com/wp-content/uploads/2020/11/delemperador-og-default.png",
          "image_secure_url": "https://delemp.com/wp-content/uploads/2020/11/delemperador-og-default.png",
          "image_width": "1200",
          "image_height": "630",
          "image_alt": "delEmperador",
          "image_type": "image/png",
          "twitter_card": "summary_large_image",
          "twitter_title": "delEmperador",
          "twitter_description": "delEmperador App. - Directorio, Empleo, Recetas y artículos de Historia, Religión, Mitología y Leyendas.",
          "twitter_site": ""
        }
    );
  }
}

void main() {

  testWidgets('OpenGraphPreview shows CircularProgressIndicator when loading', (WidgetTester tester) async {
        // Build our widget and trigger a frame.
    final provider = MockOpenGraphRequest();
    provider.initProvider("");
    await tester.pumpWidget(const OpenGraphPreview(url: 'https://example.com'));

        // Verify CircularProgressIndicator is shown.
        final circular = find.byType(CircularProgressIndicator);
        expect(circular, findsOneWidget);
  });

  testWidgets("OpenGraphPreview shows error message when fetch fails", (WidgetTester tester) async {
    // Build our widget and trigger a frame.
    final provider = MockOpenGraphRequest();
    provider.initProvider("");
    await tester.pumpWidget(const OpenGraphPreview(url: 'https://example.com'));

    // verify if error message is shown
    expect(find.text("Error on fetch OpenGraph"), findsOneWidget);
  });

  testWidgets("OpenGraphPreview shows errow if title, description and images is empty", (WidgetTester tester) async {
    final provider = MockOpenGraphRequest();
    provider.initProvider("https://example.com");

    await tester.pumpWidget(const OpenGraphPreview(url: 'https://example.com'));
    expect(find.byType(SizedBox), findsOneWidget);
  });

  test("OpenGraphRequest fetches OpenGraphEntity", () async {
    final provider = MockOpenGraphRequest();
    provider.initProvider("https://example.com?url=");
    final entity = await provider.fetch("https://example.com");
    expect(entity, isNotNull);
    expect(entity!.title, "Example Domain");
    expect(entity.description, "The description for Example Domain");
    expect(entity.image, "https://delemp.com/wp-content/uploads/2020/11/delemperador-og-default.png");
  });


}
