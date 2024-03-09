import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengraph/entities/open_graph_entity.dart';
import 'package:opengraph/opengraph.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';

final credentials = OpenGraphCredentials(
    url: "http://provider",
    token: "5f3e3e3e-3e3e-3e3e-3e3e-3e3e3e3e3e3e",
    maxObjects: 1000);

class MockOpenGraphRequest extends Mock implements OpenGraphRequestInterface {
  MockOpenGraphRequest() {
    initProvider(credentials);
  }
  @override
  Future<OpenGraphEntity?> fetch(String url) => super.noSuchMethod(
        Invocation.method(#fetch, [url]),
        returnValue: Future.value(OpenGraphEntity(
          title: 'Example Title',
          description: 'Example Description',
          image: 'https://example.com/image.jpg',
          url: 'https://example.com',
          locale: 'en',
          type: 'website',
          siteName: 'Example Site',
        )),
        returnValueForMissingStub: Future.value(OpenGraphEntity(
          title: 'Example Title',
          description: 'Example Description',
          image:
              'https://delemp.com/wp-content/uploads/2020/11/delemperador-og-default.png',
          url: 'https://example.com',
          locale: 'en',
          type: 'website',
          siteName: 'Example Site',
        )),
      );
}

void main() {
  final mockRequest = MockOpenGraphRequest();
  mockRequest.initProvider(credentials);
  group('OpenGraphPreview', () {
    testWidgets('displays loading indicator while fetching data',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home:
            OpenGraphPreview(url: 'https://example.com', provider: mockRequest),
      ));

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    });

    testWidgets('displays OpenGraph data when fetched',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home:
            OpenGraphPreview(url: 'https://example.com', provider: mockRequest),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Example Title'), findsOneWidget);
      expect(find.text('Example Description'), findsOneWidget);
    });
  });
}
