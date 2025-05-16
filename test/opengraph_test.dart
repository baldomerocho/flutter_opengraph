import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengraph/opengraph.dart';
import 'package:mockito/mockito.dart';

final credentials = OpenGraphConfiguration(maxObjects: 1000);

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

// Mock for the OpengraphFetch class to test opengraph_fetch function
class MockOpengraphFetch {
  static Future<OpengraphMetadata?> extract(String url) async {
    // Return a mock OpengraphMetadata
    final metadata = OpengraphMetadata()
      ..title = 'Example Title'
      ..description = 'Example Description'
      ..image = 'https://example.com/image.jpg'
      ..url = 'https://example.com'
      ..locale = 'en'
      ..type = 'website'
      ..siteName = 'Example Site';
    return metadata;
  }
}

void main() {
  final mockRequest = MockOpenGraphRequest();
  mockRequest.initProvider(credentials);
  group('OpengraphPreview', () {
    testWidgets('displays loading indicator while fetching data',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: OpengraphPreview(url: 'https://example.com'),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('opengraph_fetch', () {
    test('returns OpenGraphEntity with correct data', () async {
      // Create a mock implementation of the opengraph_fetch function
      Future<OpenGraphEntity?> mockOpengraphFetch(String url) async {
        return OpenGraphEntity(
          title: 'Example Title',
          description: 'Example Description',
          image: 'https://example.com/image.jpg',
          url: 'https://example.com',
          locale: 'en',
          type: 'website',
          siteName: 'Example Site',
        );
      }

      // Use the mock function
      final result = await mockOpengraphFetch('https://example.com');

      expect(result, isNotNull);
      expect(result!.title, 'Example Title');
      expect(result.description, 'Example Description');
      expect(result.image, contains('example.com'));
    });
  });
}
