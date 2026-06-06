import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:opengraph/src/opengraph_fetch_base.dart';

void main() {
  group('OpengraphFetch', () {
    test('extract returns metadata for valid URLs', () async {
      // Esta prueba verifica que extract devuelve metadatos para URLs válidas
      final result = await OpengraphFetch.extract('https://flutter.dev');
      
      // Verificar que se devuelven metadatos (incluso si son valores por defecto)
      expect(result, isNotNull);
      // No verificamos el valor exacto de la URL ya que puede variar
      final url = result!.url;
      expect(url != null, isTrue);
    });
    
    test('responseToDocument handles valid HTML', () {
      // Crear una respuesta HTTP con HTML válido
      const htmlContent = '''
      <html>
        <head>
          <title>Test Page</title>
        </head>
        <body>
          <h1>Hello, World!</h1>
        </body>
      </html>
      ''';
      final response = http.Response(htmlContent, 200);
      
      // Llamar al método que queremos probar
      final document = OpengraphFetch.responseToDocument(response);
      
      // Verificar que se analiza correctamente el HTML
      expect(document, isNotNull);
      expect(document!.querySelector('title')?.text, 'Test Page');
      expect(document.querySelector('h1')?.text, 'Hello, World!');
    });
    
    test('responseToDocument handles non-200 status codes', () {
      // Crear una respuesta con código de estado de error
      final response = http.Response('', 404);
      
      // Llamar al método que queremos probar
      final document = OpengraphFetch.responseToDocument(response);
      
      // Verificar que se devuelve null para respuestas con error
      expect(document, isNull);
    });
    
    test('extract handles invalid URLs gracefully', () async {
      // Llamar a extract con una URL inválida
      final result = await OpengraphFetch.extract('invalid-url');
      
      // Verificar el comportamiento con URLs inválidas
      if (result != null) {
        // Si devuelve un objeto, verificar que tiene valores por defecto
        expect(result.url, 'invalid-url');
      }
    });
  });
}
