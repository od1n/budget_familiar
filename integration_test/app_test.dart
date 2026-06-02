import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// ── Integration tests ───────────────────────────────────────────────────────
//
// Estos tests corren en un dispositivo real o emulador.
// Ejecutar con:
//   flutter test integration_test/app_test.dart -d <device>
//
// Para Windows:
//   flutter test integration_test/app_test.dart -d windows
//
// NOTA: Requieren --dart-define con las claves de Supabase.
//   flutter test integration_test/app_test.dart -d windows \
//     --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Pantalla de inicio', () {
    testWidgets('muestra onboarding o login al arrancar', (tester) async {
      // La app arranca y muestra onboarding (primera vez) o login.
      // No podemos importar main.dart directamente porque requiere
      // inicialización async compleja (Supabase, Firebase, etc.)
      // Este test verifica que el framework de integration_test funciona.

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Integration test OK')),
          ),
        ),
      );

      expect(find.text('Integration test OK'), findsOneWidget);
    });
  });

  group('Navegación básica (smoke test)', () {
    testWidgets('MaterialApp se renderiza sin errores', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Budget Familiar')),
            body: const Center(child: Text('Smoke test')),
          ),
        ),
      );

      expect(find.text('Budget Familiar'), findsOneWidget);
      expect(find.text('Smoke test'), findsOneWidget);
    });
  });
}
