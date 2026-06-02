# Inicio Rápido — Budget Familiar

## Prerrequisitos

- Flutter SDK >= 3.22 (`flutter --version`)
- Dart SDK >= 3.3 (incluido con Flutter)
- Proyecto activo en [supabase.com](https://supabase.com)
- (Opcional para push) Proyecto en Firebase Console

---

## 1. Instalar dependencias

```powershell
cd "D:\Desarrollo\Claude\Projects\budget_familiar"
flutter pub get
```

---

## 2. Configurar Supabase

1. Crea el proyecto en [app.supabase.com](https://app.supabase.com).
2. En **SQL Editor**, ejecuta el esquema del archivo:
   `C:\Users\Toor\Documents\Claude\Projects\Casa y Presupeusto\spec_tecnica_v1.md`
   — sección **2. ESQUEMA COMPLETO DE BASE DE DATOS** — en orden:
   tablas de sistema → usuarios y grupos → financieras → políticas RLS.
3. Copia tu **Project URL** y **anon key** desde *Project Settings → API*.

---

## 3. Generar código derivado

```powershell
dart run build_runner build --delete-conflicting-outputs
```

Ejecutar cada vez que modifiques tablas Drift, entidades @freezed o providers @riverpod.
Para desarrollo continuo usa `watch` en lugar de `build`.

---

## 4. Ejecutar la app

```powershell
# Android / iOS
flutter run `
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=TU_ANON_KEY

# Windows (escritorio)
flutter run -d windows `
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=TU_ANON_KEY
```

**Tip VS Code:** Crea `.vscode/launch.json` con los `--dart-define` para no
escribirlos en cada ejecución.

---

## 5. Archivos generados (NO editar manualmente)

| Archivo | Generado por |
|---|---|
| `*.g.dart` | build_runner (Drift, Riverpod, json_serializable) |
| `*.freezed.dart` | freezed |
| `app_database.g.dart` | drift_dev |

---

## 6. Próximos pasos (Fase 1 — semanas 5–7)

- [ ] Reemplazar `_devGroupId` en `dashboard_page.dart` con el grupo real de la sesión
- [ ] Implementar `TransactionsPage` con formulario de registro rápido
- [ ] Implementar `FamilyPage` con creación de grupo e invitación por email
- [ ] Agregar datasource de Supabase para sync de transacciones
- [ ] Implementar `SyncQueueService` para operaciones offline

---

## Comandos útiles

```powershell
flutter devices        # Ver dispositivos disponibles
flutter analyze        # Analizar el código
flutter test           # Ejecutar tests
dart run build_runner watch   # Regenerar al guardar cambios
flutter upgrade        # Actualizar Flutter SDK
```
