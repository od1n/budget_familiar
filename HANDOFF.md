# HANDOFF — Budget Familiar (presupuesto familiar multimoneda)

> Respaldo preparado el 9 de noviembre de 2026.

| Dato | Valor |
|---|---|
| Repositorio | https://github.com/od1n/budget_familiar (**público**) |
| Rama | `main` |
| Último commit | `65fa6ff` (9 nov 2026) — ajustes del formulario de transacciones y documentos históricos (hecho en este respaldo, **falta el push**) |
| Carpeta local | `D:\Desarrollo\Claude\Projects\budget_familiar` |
| Google Play | `com.budgetfamiliar.app`, versión 1.2.0+28, en prueba cerrada |
| Página web | https://budget-familiar-delta.vercel.app (privacidad `/privacy.html`, eliminación de cuenta `/eliminar-cuenta.html`; se despliega desde `docs\` al hacer push) |

## 1. Qué es

App Flutter de presupuesto familiar multimoneda (USD, VES, EUR, MXN y ARS con tasa blue; tasa manual del bolívar) para Venezuela y Europa. Registro rápido por texto y voz con IA (Gemini), escaneo de recibos, transacciones recurrentes, proyección de saldo a 12 meses (Premium), selector de idioma (español/inglés). Versión de escritorio Windows descargable desde la página web.

## 2. Tecnología

Flutter (>= 3.22) + Dart, Riverpod, Drift, freezed (código generado con `build_runner`), Supabase (base, autenticación, funciones `quick-api` y `generate-ai-insights` con reintento ante errores 503/500/429 de Gemini). Scripts: `build_release.ps1` (Android) y `build_desktop.ps1` (Windows). Guía: `INICIO_RAPIDO.md`. Diseño histórico: `docs\historico\` (incluye `spec_tecnica_v1.md` con el esquema de la base).

## 3. Cómo ejecutarlo

```powershell
Set-Location 'D:\Desarrollo\Claude\Projects\budget_familiar'
& 'C:\src\flutter\bin\flutter.bat' pub get
dart run build_runner build --delete-conflicting-outputs
& 'C:\src\flutter\bin\flutter.bat' run -d windows --dart-define-from-file='D:\Desarrollo\Claude\Projects\budget_familiar\env.json'
```

## 4. Secretos y archivos críticos (NO están en GitHub)

- `D:\Desarrollo\Claude\Projects\budget_familiar\env.json` (URL y clave pública de Supabase; ignorado por git).
- **Llave de firma de Android: `D:\budget_familiar_release.jks`.** Si se pierde, no se pueden publicar actualizaciones con la misma llave. Guardar una copia fuera del equipo (gestor de contraseñas o disco externo) junto con su contraseña.
- La contraseña del almacén de llaves está anotada en `D:\Desarrollo\DesarrolloClaudeC\otros\anotaciones.txt` (archivo local del repositorio de MotoApp que NO debe subirse). Recomendado: pasarla al gestor de contraseñas.
- Respaldo de datos de prueba: `C:\Users\Toor\Documents\budget_familiar_backup_1780353677012.json` y `budget_familiar_db.sqlite`.

## 5. Estado y pendientes

- Política de Servicios Financieros de Google resuelta ("No issues found"); se quitó la sección de inversiones y la IA quedó solo en presupuesto.
- Para pasar a producción: reunir 12 probadores durante 14 días en la prueba cerrada.
- Pendientes funcionales: agenda de pagos, cobro por Pago Móvil fuera de Google Play (vía web/escritorio activando el plan en Supabase con `set_user_plan`). USDT excluido a propósito por la política de Google.
