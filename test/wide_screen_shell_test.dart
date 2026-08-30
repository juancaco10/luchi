import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luchi/app.dart';

/// `WideScreenShell` envuelve toda la app desde el `builder` del
/// MaterialApp. Su contrato tiene dos mitades y una es un "no hagas nada":
/// en móvil —el producto principal, Android— debe dejar el árbol
/// exactamente como estaba, porque la tipografía y los targets táctiles se
/// dimensionaron a propósito para un niño usando el dedo. Solo por encima
/// del breakpoint limita el ancho, que es lo que evita que en un navegador
/// de escritorio los botones se estiren a media pantalla.
void main() {
  /// Monta el shell con un ancho de ventana concreto.
  Future<void> pumpAt(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: WideScreenShell(
          child: Container(key: const Key('contenido')),
        ),
      ),
    );
  }

  /// Ancho real que acaba teniendo el contenido de la app.
  double anchoDelContenido(WidgetTester tester) =>
      tester.getSize(find.byKey(const Key('contenido'))).width;

  group('WideScreenShell', () {
    testWidgets('en móvil no toca el árbol: el contenido ocupa todo el ancho',
        (tester) async {
      await pumpAt(tester, 400);

      expect(anchoDelContenido(tester), 400);
      // Nada de envoltorio: si apareciera, móvil habría cambiado.
      expect(find.byType(ClipRect), findsNothing);
    });

    testWidgets('justo por debajo del breakpoint sigue siendo móvil',
        (tester) async {
      await pumpAt(tester, WideScreenShell.wideBreakpoint - 1);

      expect(anchoDelContenido(tester), WideScreenShell.wideBreakpoint - 1);
    });

    testWidgets('en escritorio limita el contenido a una columna',
        (tester) async {
      await pumpAt(tester, 1920);

      expect(anchoDelContenido(tester), WideScreenShell.contentWidth);
    });

    testWidgets('en el breakpoint exacto ya limita', (tester) async {
      await pumpAt(tester, WideScreenShell.wideBreakpoint);

      expect(anchoDelContenido(tester), WideScreenShell.contentWidth);
    });

    testWidgets('en escritorio acota la escala de texto sin ignorar al usuario',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late TextScaler escalaVista;
      await tester.pumpWidget(
        MaterialApp(
          // copyWith y no un MediaQueryData nuevo: este debe conservar el
          // `size` de la ventana, que es lo que el shell mira para decidir
          // si está en móvil o en escritorio.
          home: Builder(builder: (outer) {
            return MediaQuery(
              // El usuario pidió fuentes muy grandes en su navegador.
              data: MediaQuery.of(outer)
                  .copyWith(textScaler: const TextScaler.linear(2.0)),
              child: WideScreenShell(
                child: Builder(builder: (context) {
                  escalaVista = MediaQuery.textScalerOf(context);
                  return const SizedBox();
                }),
              ),
            );
          }),
        ),
      );

      // Se recorta al techo, no se descarta: 2.0 pedido → 1.1 aplicado.
      expect(escalaVista.scale(10), 11.0);
    });

    testWidgets('en móvil respeta la escala de texto del usuario tal cual',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late TextScaler escalaVista;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: WideScreenShell(
              child: Builder(builder: (context) {
                escalaVista = MediaQuery.textScalerOf(context);
                return const SizedBox();
              }),
            ),
          ),
        ),
      );

      // Accesibilidad intacta en el dispositivo real.
      expect(escalaVista.scale(10), 20.0);
    });
  });
}
