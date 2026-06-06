import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengraph/opengraph.dart';

void main() {
  group('WidgetOpenGraph', () {
    testWidgets('renders correctly with all data in non-production mode', (WidgetTester tester) async {
      final data = OpenGraphEntity(
        title: 'Test Title',
        description: 'Test Description',
        image: 'https://example.com/image.jpg',
        url: 'https://example.com',
        locale: 'en_US',
        type: 'article',
        siteName: 'Test Site',
      );
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WidgetOpenGraph(
            data: data,
            height: 200,
            isProduction: false, // Usar modo no-producción para evitar cargar imágenes de red
            borderRadius: 10,
          ),
        ),
      ));
      
      await tester.pump();
      
      // Verificar que se muestra el título
      expect(find.text('Test Title'), findsOneWidget);
      
      // Verificar que se muestra la descripción
      expect(find.text('Test Description'), findsOneWidget);
      
      // Verificar que se muestra el host de la URL
      expect(find.text('example.com'), findsOneWidget);
    });
    
    testWidgets('handles empty image URL in non-production mode', (WidgetTester tester) async {
      final data = OpenGraphEntity(
        title: 'Test Title',
        description: 'Test Description',
        image: '', // URL de imagen vacía
        url: 'https://example.com',
        locale: 'en_US',
        type: 'article',
        siteName: 'Test Site',
      );
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WidgetOpenGraph(
            data: data,
            height: 200,
            isProduction: false, // Usar modo no-producción para evitar cargar imágenes de red
            borderRadius: 10,
          ),
        ),
      ));
      
      await tester.pump();
      
      // Verificar que se muestra el título
      expect(find.text('Test Title'), findsOneWidget);
      
      // Verificar que se muestra la descripción
      expect(find.text('Test Description'), findsOneWidget);
    });
    
    testWidgets('handles empty title and description', (WidgetTester tester) async {
      final data = OpenGraphEntity(
        title: '', // Título vacío
        description: '', // Descripción vacía
        image: 'https://example.com/image.jpg',
        url: 'https://example.com',
        locale: 'en_US',
        type: 'article',
        siteName: 'Test Site',
      );
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WidgetOpenGraph(
            data: data,
            height: 200,
            isProduction: false,
            borderRadius: 10,
          ),
        ),
      ));
      
      await tester.pump();
      
      // Verificar que no se muestra el título ni la descripción
      expect(find.text(''), findsNothing); // No debería mostrar strings vacíos
      
      // Verificar que se muestra el host de la URL
      expect(find.text('example.com'), findsOneWidget);
    });
    
    testWidgets('adapts to different screen sizes', (WidgetTester tester) async {
      final data = OpenGraphEntity(
        title: 'Test Title',
        description: 'Test Description',
        image: 'https://example.com/image.jpg',
        url: 'https://example.com',
        locale: 'en_US',
        type: 'article',
        siteName: 'Test Site',
      );
      
      // Configurar un tamaño de pantalla pequeño
      tester.binding.window.physicalSizeTestValue = const Size(320, 480);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WidgetOpenGraph(
            data: data,
            height: 200,
            isProduction: false,
            borderRadius: 10,
          ),
        ),
      ));
      
      await tester.pump();
      
      // Verificar que el widget se adapta al ancho de la pantalla
      final container = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(container.height, 200);
      
      // Restaurar el tamaño de la pantalla
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    });
    
    testWidgets('applies different border radius values', (WidgetTester tester) async {
      final data = OpenGraphEntity(
        title: 'Test Title',
        description: 'Test Description',
        image: 'https://example.com/image.jpg',
        url: 'https://example.com',
        locale: 'en_US',
        type: 'article',
        siteName: 'Test Site',
      );
      
      const customBorderRadius = 20.0;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WidgetOpenGraph(
            data: data,
            height: 200,
            isProduction: false,
            borderRadius: customBorderRadius,
          ),
        ),
      ));
      
      await tester.pump();
      
      // Verificar que se aplica el radio de borde personalizado
      final padding = tester.widget<Padding>(find.byType(Padding).first);
      expect(padding.padding, EdgeInsets.all(customBorderRadius / 2));
      
      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect).first);
      expect(clipRRect.borderRadius, BorderRadius.circular(customBorderRadius / 2));
    });
  });
}
