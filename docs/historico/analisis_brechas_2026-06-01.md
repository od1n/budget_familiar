# Análisis de brechas — Budget Familiar
**Fecha:** 2026-06-01  
**Base:** spec_tecnica_v1.md vs. resumen de integración (junio 2026)

---

## Resumen ejecutivo

El proyecto implementó bien el núcleo funcional (transacciones, presupuestos, metas, familia, sync básico) y está en Play Console internal testing. Sin embargo, hay tres categorías de problemas significativos:

1. **La arquitectura de suscripción no escala** — `is_premium` boolean vs. el modelo de 4 planes de la spec.
2. **Varias features diferenciadores están incompletas o ausentes** — inversiones, sobres virtuales, AI insights reales, noticias.
3. **Requisitos operacionales para producción no cumplidos** — eliminación de cuenta, FCM push, Realtime roto.

---

## 1. Tablas de base de datos ausentes

La spec define 11 tablas. Las migraciones aplicadas (schema.sql + 003–012) no mencionan:

| Tabla | Por qué importa |
|-------|----------------|
| `exchange_rates` (serie histórica) | La app llama directo a APIs externas desde el cliente. Sin esta tabla no hay historial de tasas ni snapshots confiables por transacción. |
| `inflation_indices` | Necesaria para ajuste de metas por inflación y para el contexto AI. |
| `subscription_plans` | Sin esta tabla el feature gating es un boolean hardcoded, no un sistema escalable. |
| `app_config` | Parámetros como TTL de insights o modo beta están hardcoded en el cliente. |
| `news_cache` | Sin caché servidor, cada cliente hace su propia llamada a NewsAPI (agota el límite gratis rápido). |
| `ai_prompt_templates` | Prompts versionados en base de datos vs. hardcoded en la Edge Function. |
| `ai_insights` | Las recomendaciones Gemini actuales son efímeras. No hay historial, no hay TTL, no hay contexto guardado. |
| `investments` | Feature no implementado. |
| `virtual_envelopes` | Feature no implementado. |
| `currencies` | Probablemente manejada como enum en cliente; sin tabla no hay soporte dinámico de monedas. |

**Recomendación:** Antes de salir de internal testing, aplicar las migraciones faltantes de `exchange_rates`, `subscription_plans` y `ai_insights`. Las demás pueden quedar para fases posteriores.

---

## 2. Edge Functions ausentes

Solo están deployadas `bright-function` (webhook LemonSqueezy) y `quick-api` (proxy Gemini). La spec define 4 más:

| Edge Function | Impacto de no tenerla |
|---|---|
| `update-exchange-rates` (cron 6h) | Las tasas BCV/paralela las pide cada cliente directamente. Si la API cambia o cae, todos los clientes fallan al mismo tiempo. Con cron server-side, un fallo es transparente. |
| `generate-ai-insights` (cron + on-demand) | El pipeline AI actual (Gemini quick recommendations) no usa historial de 3 meses, no usa noticias, no guarda resultados. No es el producto Premium prometido. |
| `check-budget-alerts` (trigger post-INSERT) | Las alertas de presupuesto 50%/80%/100% se evalúan en el cliente. Si la app está cerrada cuando se alcanza el límite, el usuario no se entera. |
| `update-inflation` (cron mensual) | Sin datos de inflación server-side, el ajuste de metas no tiene base de datos. |

---

## 3. Features incompletos o ausentes

### 3.1 Inversiones (alta prioridad)
La tabla está en la spec, el módulo está en la estructura Flutter (`features/investments/`), pero no aparece como completado. Es una feature diferenciadora para el contexto venezolano (USD en efectivo, criptos, depósitos a plazo). **Estimado: 1–2 semanas.**

### 3.2 Sobres virtuales (media prioridad)
Método de presupuesto más intuitivo que las categorías fijas para familias con ingresos variables (muy común en Venezuela). La spec lo incluye como feature Premium. **Estimado: 1 semana.**

### 3.3 AI Insights real vs. lo que hay
Lo que está implementado (`quick-api` + Gemini) es un generador de recomendaciones superficiales en tiempo real. Lo que la spec describe es diferente:
- Historial financiero de **3 meses** como contexto
- **Noticias económicas** recientes (NewsAPI)
- **Tasas e inflación** actuales del servidor
- Resultado **guardado con TTL** (no regenerado en cada pantalla)
- **`overall_health_score`** — score numérico de salud financiera

Esto sí justifica el plan Premium. Sin esto, cobrar por IA es difícil de defender.

### 3.4 Noticias financieras (NewsAPI)
No integradas en ningún lugar. La spec las usa como contexto para AI y como feed en el dashboard para usuarios Premium. Agregar un feed de noticias económicas venezolanas es bajo costo (100 req/día gratis) y alto impacto en diferenciación.

### 3.5 Metas con ajuste por inflación
El campo `inflation_adjustment_enabled` está en la spec pero no se menciona como implementado. Para Venezuela es una feature única: la meta "Computadora $500" necesita actualizarse si la inflación es 14%/mes.

### 3.6 Sign in with Apple
Listado en la spec y en el pubspec original, no mencionado como implementado. **Requerido para iOS** (App Store obliga a ofrecer Sign in with Apple si ofreces otros OAuth).

### 3.7 Modo oscuro
La spec define todos los tokens `dark*` en `AppColors`. No se menciona como implementado. Muchos usuarios de presupuesto usan la app de noche.

---

## 4. Problemas que bloquean producción

Estos son requisitos que Google Play y Apple exigen (o que afectan directamente la retención) para salir de internal testing:

### 4.1 Eliminación de cuenta — BLOQUEANTE para Play Store / App Store
Google Play requiere que apps con autenticación ofrezcan eliminación de cuenta **y datos** desde dentro de la app. Sin esto, la app no puede pasar de internal testing a open testing ni a producción. No está mencionada en ningún lugar del proyecto.

Debe incluir:
- Botón en Settings
- Confirmación con texto escrito
- Borrado en Supabase Auth + todas las tablas (cascade o función)
- Cancelación de suscripción activa (si aplica)

### 4.2 Firebase Cloud Messaging — push notifications
`flutter_local_notifications` solo funciona cuando la app está en primer plano o background activo. Si el presupuesto se excede a las 2am con la app cerrada, el usuario no recibe la alerta. Para una app de presupuesto esto es un fallo funcional serio. La spec incluye FCM; no se implementó.

### 4.3 Realtime WebSocket no conecta
Causa no determinada. En modo solo-usuario es tolerable (pull 60s). En modo familiar (múltiples usuarios) es un problema visible: si tu pareja registra un gasto, tú lo ves con hasta 60s de retraso. Hay que debuggear esto antes de comercializar el plan familiar.

**Pasos para diagnóstico:**
```powershell
# Activar logs verbose en supabase_flutter:
# En main.dart, antes de Supabase.initialize():
# Logger.level = Level.verbose; (si tienes logger configurado)
# Revisar en supabase dashboard: Realtime > Inspector
# Verificar que la publication 'supabase_realtime' incluya la tabla transactions con REPLICA IDENTITY FULL
```

### 4.4 LemonSqueezy bloqueado para Venezuela
Este es el bloqueante de monetización. Mientras no resuelvan el formulario de impuestos, la tienda está en modo test. La alternativa inmediata: activar la tienda con dirección de otro país (si tienes residencia/contacto fuera de Venezuela) y manejar el pago a tu cuenta PayPal como está configurado.

---

## 5. Inconsistencias entre spec e implementación

### 5.1 Modelo de suscripción — discrepancia crítica

| Aspecto | Spec | Implementación actual |
|---|---|---|
| Planes | beta / free / family / premium | free / pro (is_premium boolean) |
| Precios | $4.99/mes family, $9.99/mes premium | $2.99/mes, $19.99/año |
| Límite miembros | 2 / 5 / 10 según plan | hardcoded 5 |
| Categorías | 10 / 30 / 50 según plan | sin límite diferenciado |
| App de escritorio | solo family/premium | sin gate implementado |
| Inversiones | solo family/premium | no implementado |
| Sobres virtuales | solo family/premium | no implementado |

El modelo de 2 planes ($2.99/$19.99) es más simple de vender pero rompe la lógica de la spec. **Hay que decidir** si van con el modelo simple o el de 4 planes, y actualizar el gating en consecuencia. El boolean `is_premium` no es escalable a 4 planes.

### 5.2 Arquitectura Flutter
La spec propone Clean Architecture (domain/usecases/repositories). La implementación usa `features/ + services/` directo (más flat). No es un problema hoy, pero si el equipo crece o si se agregan los módulos faltantes (inversiones, sobres, insights), la ausencia de una capa de dominio va a generar lógica duplicada entre la pantalla y el servicio.

### 5.3 group_id TEXT vs UUID
Conocida y documentada. La fricción real está en las migraciones y en cualquier JOIN con tablas de Supabase que usan UUID nativo. Considerar si en schema v7 vale la pena hacer la migración a uuid usando `uuid_generate_v4()` y una función de conversión, o mantenerlo como está.

---

## 6. Deuda técnica

| Ítem | Severidad |
|---|---|
| Tests para FamilyService, SyncService, ExportService | Media — requieren mocking Supabase |
| Sin tests de integración (Supabase real) | Media — los mocks no detectaron el bug de RLS en Android |
| Error handling estructurado no visible | Media — ¿qué ve el usuario cuando falla el sync? |
| Sync queue offline-first real | Media — pull 60s no es offline-first |
| `max_members` dinámico según plan | Baja (hardcoded 5 funciona hoy) |
| Deeplink de invitación (no solo código) | Baja |

---

## 7. Oportunidades no contempladas en la spec

Estas no estaban en la spec original pero tienen alto valor:

**Widget de Android (home screen):** balance rápido del día sin abrir la app. Alta retención, bajo esfuerzo con `home_widget` package.

**Backup/restore manual:** exportar todos los datos como JSON y restaurarlos. Necesario para usuarios que cambien de dispositivo antes de tener sync completo. También es buena práctica ante riesgo de pérdida de datos.

**Confirmación biométrica:** para transacciones grandes o acceso a exportación. `local_auth` package. Relevante en Windows (fingerprint) y Android.

**Precio en VES en la pantalla de paywall:** el usuario venezolano que trabaja en bolívares necesita ver el precio equivalente en VES al momento actual. Con la tasa paralela ya implementada, esto es cuestión de mostrarla en el paywall.

---

## 8. Orden de atención sugerido

### Inmediato (para pasar a open testing)
1. Implementar eliminación de cuenta con borrado de datos
2. Decidir modelo de suscripción (2 planes vs. 4) y actualizar feature gating
3. Debuggear Realtime WebSocket
4. Resolver LemonSqueezy (bloqueante de monetización real)

### Próximo sprint (diferenciación del producto)
5. Módulo de inversiones (feature diferenciadora para VE)
6. Pipeline AI real: Edge Function `generate-ai-insights` con historial + noticias
7. FCM para push notifications cuando app está cerrada
8. Metas con ajuste por inflación

### Más adelante
9. Sobres virtuales
10. Modo oscuro
11. Sign in with Apple (necesario para iOS)
12. Widget de Android
13. Backend de tasas de cambio (Edge Function cron)
14. i18n (inglés/portugués para expansión)
