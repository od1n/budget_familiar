# Budget Familiar — Resumen de integración del proyecto
> Actualizado: junio 2026. Usar para iniciar conversaciones futuras.

---

## 1. Descripción general

App de presupuesto familiar SaaS multiplataforma. Target primario: **Windows Desktop**. Target secundario: **Android** (publicado en Play Console). iOS pendiente (requiere Mac).
Contexto económico venezolano: manejo dual USD/VES, tasas BCV y paralela, inflación.

**Comando para correr en desarrollo:**
```powershell
Set-Location "D:\Desarrollo\Claude\Projects\budget_familiar"
& "C:\src\flutter\bin\flutter.bat" run -d windows "--dart-define=SUPABASE_URL=https://tnomtsvzkleowdsdfsyq.supabase.co" "--dart-define=SUPABASE_ANON_KEY=<anon_key>"
```

**Build release Android (AAB):**
```powershell
Set-Location "D:\Desarrollo\Claude\Projects\budget_familiar"
$env:KEY_STORE_PASSWORD = "contraseña"
$env:KEY_PASSWORD = "contraseña"
& "C:\src\flutter\bin\flutter.bat" build appbundle --release "--dart-define=SUPABASE_URL=https://tnomtsvzkleowdsdfsyq.supabase.co" "--dart-define=SUPABASE_ANON_KEY=<anon_key>"
```

**Build MSIX Windows:**
```powershell
Set-Location "D:\Desarrollo\Claude\Projects\budget_familiar"
& "C:\src\flutter\bin\flutter.bat" build windows --release "--dart-define=SUPABASE_URL=..." "--dart-define=SUPABASE_ANON_KEY=..."
& "C:\src\flutter\bin\dart.bat" run msix:create
```

**Regenerar código Drift/Riverpod:**
```powershell
Set-Location "D:\Desarrollo\Claude\Projects\budget_familiar"
& "C:\src\flutter\bin\dart.bat" run build_runner build --delete-conflicting-outputs
```

**Tests:**
```powershell
Set-Location "D:\Desarrollo\Claude\Projects\budget_familiar"
& "C:\src\flutter\bin\flutter.bat" test test/ --reporter=expanded
```

---

## 2. Stack tecnológico

| Capa | Tecnología |
|------|-----------|
| UI | Flutter 3.33+ (Material 3) |
| Estado | Riverpod 2 (`StateNotifierProvider`, `StreamProvider.autoDispose`) |
| DB local | Drift (SQLite), schema v6 |
| Backend | Supabase (Auth, REST, Realtime, Edge Functions) |
| Pagos | LemonSqueezy — EN MODO TEST, pendiente activación para Venezuela |
| IA | Gemini 2.5 Flash Lite via Edge Function proxy `quick-api` |
| Navegación | GoRouter 14 (`ShellRoute` + `NoTransitionPage`) |
| PDF/CSV | `pdf` + `share_plus` + `csv` |
| Notificaciones | `flutter_local_notifications` v17 (Windows usa SnackBar fallback) |
| JWT seguro Windows | `DpapiStorage` — DPAPI via `crypt32.dll` con `dart:ffi`, sin ATL |
| JWT seguro Android/iOS | supabase_flutter default (Keystore/Keychain), `localStorage: null` |
| JWT seguro Linux | `SharedPrefsStorage` (sin alternativa sin libsecret) |
| Ventana Windows | `window_manager` — persiste tamaño, posición, estado maximizado |
| Generación de código | `build_runner` + `drift_dev` + `riverpod_generator` |

---

## 3. Estructura de archivos

```
lib/
├── main.dart                    # Entry point. DpapiStorage (Windows), default (Android/iOS),
│                                # SharedPrefsStorage (Linux). window_manager init.
│                                # dart-define para claves Supabase.
├── app.dart                     # BudgetApp. Auth listeners (signedIn + initialSession).
│                                # syncFamilyMembership → auto-activa grupo en nuevos dispositivos.
│                                # Pull periódico 60s (syncDown + syncPendingTransactions).
│                                # _SyncTimerNotifier para gestionar el timer.
├── router/
│   └── app_router.dart          # GoRouter. onboardingInitProvider + onboardingDoneProvider.
│                                # Rutas: /onboarding, /auth/*, /dashboard, /transactions,
│                                # /budgets, /savings, /family, /accounts, /recurring,
│                                # /settings, /paywall
├── core/
│   ├── constants/               # AppColors, AppSpacing, AppTypography
│   ├── services/
│   │   ├── dpapi_storage.dart   # LocalStorage cifrado con DPAPI para Windows.
│   │   │                        # CryptProtectData/CryptUnprotectData via crypt32.dll.
│   │   │                        # Sin flutter_secure_storage (requiere ATL).
│   │   ├── local_storage_service.dart  # SharedPrefsStorage para Linux.
│   │   ├── supabase_service.dart       # Singleton client + currentUserId helper.
│   │   ├── sync_service.dart    # syncDown(groupId), syncPendingTransactions(),
│   │   │                        # syncFamilyMembership() — descarga grupos del usuario
│   │   │                        # y cachea en Drift. Soluciona problema de grupo no
│   │   │                        # reconocido en desktop tras crear en móvil.
│   │   ├── realtime_service.dart # Suscripción Realtime para transactions.
│   │   │                        # ⚠️ WebSocket no conecta (causa no determinada).
│   │   │                        # transactions en supabase_realtime publication ✓
│   │   │                        # REPLICA IDENTITY FULL ✓. Mitigado con pull 60s.
│   │   ├── recurring_service.dart     # processOverdue(). advanceDate() público/testeable.
│   │   ├── notification_service.dart  # Budget/recurring/weekly alerts.
│   │   │                        # isoWeekKey() @visibleForTesting.
│   │   │                        # Bug corregido: cálculo W53 incorrecto.
│   │   ├── export_service.dart  # PDF y CSV mensuales.
│   │   ├── ocr_service.dart     # Ollama/Claude/Gemini/Proxy. OcrResult.parse() puro.
│   │   ├── ai_proxy_service.dart # Edge Function 'quick-api'. OCR + recomendaciones.
│   │   ├── investment_advisor_service.dart
│   │   ├── subscription_service.dart  # is_premium + caché SharedPrefs.
│   │   ├── family_service.dart  # createGroup() usa RPC create_family_group SECURITY DEFINER
│   │   │                        # (evita RLS issues en Android). joinGroupByCode() usa RPC.
│   │   ├── csv_import_service.dart    # Parser CSV multi-formato/multi-banco.
│   │   └── exchange_rate_service.dart # Tasas BCV/paralela. Caché 4h en SharedPrefs.
│   └── utils/
│       └── category_utils.dart  # iconFromCode(), colorFromHex(), paletas, kIconOptions.
├── data/
│   └── local/
│       ├── app_database.dart    # AppDatabase Drift schema v6.
│       │                        # AppDatabase.memory() @visibleForTesting.
│       ├── tables/              # Una tabla por archivo.
│       └── daos/                # Un DAO por tabla con @DriftAccessor.
├── features/
│   ├── onboarding/              # OnboardingPage. Bienvenida + CTA auth.
│   │                            # Flag onboarding_done en SharedPrefs. Solo primera vez.
│   ├── auth/                    # Login, Register, AuthNotifier.
│   │                            # Google OAuth: localhost:7777 desktop, deep link Android.
│   ├── dashboard/               # Balance dual USD/VES, gráficas, IA recomendaciones.
│   ├── transactions/            # TransactionForm: OCR cámara/galería móvil,
│   │                            # file_selector desktop. TransferFormDialog.
│   ├── accounts/                # AccountsPage, CsvImportPage stepper.
│   ├── budgets/                 # Alertas de exceso.
│   ├── savings/                 # Metas con progreso.
│   ├── family/                  # Grupos con contador X/5, invite code, ownership transfer.
│   ├── recurring/               # CRUD plantillas recurrentes.
│   ├── settings/                # OCR backend, perfil.
│   ├── categories/              # CategoryCreationDialog.
│   └── subscription/            # Paywall $2.99/mes y $19.99/año.
└── shared/
    └── widgets/
        ├── layout/adaptive_scaffold.dart  # Desktop: NavigationRail sidebar 240px.
        │                                  # Mobile: NavigationBar (onlyShowSelected labels).
        │                                  # FAB central en móvil.
        └── premium_gate.dart

test/
├── data/dao_test.dart                 # 24 — Drift in-memory: getMonthlySummary,
│                                      #       insertTransferPair, getBalance.
├── services/
│   ├── ai_proxy_service_test.dart     # 22 — AiOcrResult, AiRecommendation, InvestmentContext
│   ├── csv_import_service_test.dart   # 24 — detectDelimiter, mapRows, formatos fecha
│   ├── exchange_rate_service_test.dart # 11 — VesRates.isStale, loadCached
│   ├── notification_service_test.dart  # 8  — isoWeekKey ISO 8601 incl. W53
│   ├── ocr_result_test.dart           # 21 — OcrResult.parse y fromJson
│   ├── recurring_service_test.dart    # 13 — advanceDate frecuencias y edge cases
│   └── subscription_service_test.dart # 12 — isActive, planLabel, loadFromCache
└── utils/category_utils_test.dart     # 10 — colorFromHex, iconFromCode, paleta
# Total: 157 tests, todos pasando ✓

supabase/migrations/
├── schema.sql + 003 a 010             # Schema base + features anteriores
├── 011_member_limit.sql               # max_members=5 en family_groups.
│                                      # join_group_by_invite con validación de límite.
└── 012_create_group_rpc.sql           # create_family_group() SECURITY DEFINER.
                                       # Requerido por RLS issues en Android.
supabase/functions/
├── lemon-webhook/ → 'bright-function' # JWT OFF
└── ai-proxy/ → 'quick-api'           # gemini-2.5-flash-lite. JWT OFF.
```

---

## 4. Patrones de código establecidos

### Riverpod
- `StateNotifierProvider.autoDispose` para notifiers con operaciones async.
- `StreamProvider.autoDispose` para streams de Drift.
- No usar `.stream` deprecated — llamar DAO directamente.

### Drift ORM
- `@DriftAccessor` requiere importar tablas directamente (no solo app_database.dart).
- Schema v6 con `MigrationStrategy.onUpgrade`.
- `AppDatabase.memory()` para tests in-memory.
- En test files: `import 'package:drift/drift.dart' hide isNotNull, isNull;` (conflicto con matcher).

### Flutter
- `DropdownButtonFormField` usa `initialValue:` (`value:` deprecado en Flutter 3.33+).
- Formularios complejos: `MaterialPageRoute` en móvil, no Dialog.
- OCR móvil: `showModalBottomSheet` con opciones cámara/galería.
- `defaultTargetPlatform` para branching de plataforma.

### Supabase
- `group_id` es TEXT en todas las tablas (Drift genera UUIDs como strings).
- RLS usa `user_group_ids_text()` helper TEXT↔uuid.
- Funciones SECURITY DEFINER: siempre `SET search_path = public`.
- Operaciones críticas usan RPCs para evitar RLS issues del lado del cliente.

### Seguridad
- Windows: DPAPI vía `dart:ffi` — datos cifrados ligados al usuario Windows.
- Android/iOS: `localStorage: null` → supabase_flutter usa Keystore/Keychain.
- No usar `flutter_secure_storage` en Windows (requiere ATL, no disponible).

### Sincronización
- `syncFamilyMembership()` en AMBOS eventos: `initialSession` y `signedIn`.
- Sin esto, desktop no reconoce grupos creados desde otro dispositivo.
- Pull periódico 60s es el mecanismo principal (Realtime WebSocket no conecta).
- `_SyncTimerNotifier` recibe `SyncService` directamente (no `WidgetRef`) para evitar lifecycle issues.

---

## 5. Supabase — configuración actual

| Recurso | Estado |
|---------|--------|
| Project ID | `tnomtsvzkleowdsdfsyq` |
| Region | sa-east-1 (São Paulo) |
| Auth | Email/pass ✓ · Google OAuth ✓ (Web + Android release + debug) |
| JWT expiry | 1800s |
| Edge Functions | `bright-function` (webhook), `quick-api` (IA proxy) — JWT OFF ambas |
| Gemini API key | ✓ AI Studio, proyecto "Family Budget" |
| Realtime publication | `supabase_realtime` → tabla `transactions` ✓, REPLICA IDENTITY FULL ✓ |
| Migraciones aplicadas | schema.sql + 003–012 |

**Google Cloud Console (my-project-1485369738831):**
- OAuth Web: redirect `https://tnomtsvzkleowdsdfsyq.supabase.co/auth/v1/callback`
- OAuth Android debug: SHA-1 `CD:BD:C6:8B:90:1A:E8:A6:2B:7B:F6:A8:6F:64:07:00:3B:D4:C9:FA`
- OAuth Android release: SHA-1 `D8:81:36:61:8E:96:9F:3B:EF:9A:BC:A8:EA:01:E4:98:36:36:25:EA`
- Google provider habilitado en Supabase Auth > Providers

---

## 6. LemonSqueezy — configuración actual

| Elemento | Valor |
|----------|-------|
| Tienda | EHPD — **EN MODO TEST** |
| Plan mensual | $2.99 — `https://ehpd.lemonsqueezy.com/checkout/buy/de15ef1c-ae27-4d9f-b575-1faf290c11db` |
| Plan anual | $19.99 — `https://ehpd.lemonsqueezy.com/checkout/buy/f101df54-d71f-4466-82f2-d4602fb28147` |
| Webhook | `https://tnomtsvzkleowdsdfsyq.supabase.co/functions/v1/bright-function` |
| Payout | PayPal (x0d1ns0x@gmail.com) |
| Problema | Venezuela: tax form no carga (bug UI de LS). Contactado hello@lemonsqueezy.com + @lmsqueezy. Sin respuesta. |
| Flujo verificado | pago test → webhook → set_user_premium RPC → is_premium=true ✓ |

---

## 7. Android

| Elemento | Valor |
|----------|-------|
| Package | `com.budgetfamiliar.app` |
| minSdk | 21 |
| Keystore | `D:\budget_familiar_release.jks`, alias `budgetfamiliar` |
| Versión actual | **1.0.0+8** (internal testing) |
| Próxima versión | 1.0.0+9 (incrementar en pubspec antes de cada build) |
| Play Console app ID | 4975097147946213931 |
| Deep link OAuth | `io.supabase.budgetfamiliar://login-callback/` |

---

## 8. Estado — ✓ Hecho / ⏳ Pendiente

### ✓ Completado

- Auth completo (email/pass + Google OAuth desktop y Android)
- Onboarding (primera vez, flag persistido)
- Dashboard con balance dual, gráficas, IA recomendaciones
- Transacciones CRUD, paginación, búsqueda, OCR (cámara+galería móvil)
- Transferencias internas entre cuentas
- Presupuestos, metas, recurrentes, cuentas, categorías
- Importación CSV + Exportación PDF/CSV
- Grupos familiares: límite 5 miembros, contador UI, ownership transfer
- Sincronización Supabase: pull 60s + syncFamilyMembership auto-grupo
- Notificaciones locales (alertas, resumen semanal)
- Monetización LemonSqueezy (modo test, flujo completo verificado)
- JWT cifrado: DPAPI Windows, Keystore/Keychain Android/iOS
- Window state persistence (tamaño, posición, maximizado)
- MSIX Windows (self-signed, sideload)
- Android en Play Console Internal Testing
- 157 tests pasando (DAOs in-memory, servicios puros, utils)
- Bug corregido: isoWeekKey W53 incorrecto
- Bug corregido: campos linkedTxId y accountId faltantes en Realtime payload

### ⏳ Pendiente

1. **LemonSqueezy activación** — BLOQUEANTE monetización. Esperando respuesta de soporte.
2. **Realtime WebSocket** — No conecta (mitigado con pull 60s). Investigar con logs debug.
3. **MSIX actualizado** — Build pendiente con cambios recientes.
4. **iOS** — Requiere Mac.
5. **SQLite cifrado** — SQLCipher (fase futura).
6. **Firma MSIX comercial** — Certificado actual self-signed requiere sideload del usuario.
7. **AdMob** — Stub preparado. Al lanzar en móvil.
8. **Actualización automática max_members** — Al cambiar plan de suscripción.
9. **Más tests** — FamilyService, SyncService, ExportService (requieren mocking Supabase).

---

## 9. Decisiones técnicas clave

| Decisión | Razón |
|----------|-------|
| `group_id TEXT` | Drift genera UUIDs como strings; FK directa con uuid imposible en PG |
| `DpapiStorage` sin flutter_secure_storage | ATL no disponible en Windows SDK estándar |
| `create_family_group` RPC | INSERT directo a family_groups fallaba por RLS en Android |
| `syncFamilyMembership` en initialSession | Sin esto desktop no reconocía grupos creados en móvil |
| Pull 60s como sync primario | Realtime WebSocket no conecta; causa no determinada |
| `gemini-2.5-flash-lite` | 1.5-flash deprecado; 2.0-flash-lite retirado jun 2026 |
| `_SyncTimerNotifier` recibe SyncService | WidgetRef puede estar disposed cuando timer dispara |
| LemonSqueezy sobre Stripe | Stripe no soporta Venezuela como merchant |
| `localStorage: null` en Android | Usa Keystore nativo, resuelve expiración JWT sin SharedPrefs |
