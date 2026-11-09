# Diseño de nuevas funciones — Budget Familiar

Documento de diseño técnico para incorporar seis mejoras inspiradas en el análisis de la competencia (Platica), aterrizadas en la arquitectura actual de la aplicación: base de datos local **Drift**, sincronización con **Supabase**, estado con **Riverpod**, tasas de cambio propias, proxy de **inteligencia artificial** (Gemini) y planes de suscripción (`set_user_plan`).

Alcance de este documento: qué se construye, cómo encaja en el código existente, qué archivos se tocan, el esfuerzo estimado, los riesgos y el orden recomendado. No es código final; es el plano para implementarlo por partes y sin sorpresas.

> Nota de verificación: la sesión perdió el enlace con tu computadora al escribir esto, así que algunos nombres exactos de archivos o columnas hay que confirmarlos contra el código cuando reconecte. Donde aplica, lo señalo con "verificar".

---

## 0. Decisiones que necesito que apruebes antes de programar

Tres puntos cambian el diseño según tu respuesta. Te doy mi recomendación en cada uno:

1. **USDT (criptomoneda).** Platica maneja USDT. **Recomiendo NO incluirlo.** Acabamos de pasar semanas quitando toda señal financiera para salir del rechazo de Google por la política de Servicios Financieros, y "criptomonedas" es exactamente una de las palabras que dispara ese clasificador. Agregar USDT arriesga volver al rechazo. Sí incluimos monedas normales (COP, BRL).

2. **Cobro por Pago Móvil.** Dentro de una app publicada en Google Play, cobrar funciones digitales por fuera de la facturación de Google **viola la política de pagos** de Google. La ruta segura es cobrar el Pago Móvil **fuera de la app de Play** (en la versión web o de escritorio) y que la app de Play siga usando Google Play Billing. Lo detallo en la sección 6. Necesito que confirmes que vamos por la ruta segura.

3. **Orden y planes.** Propongo un orden de implementación (sección 7) y en qué plan (Gratuito / Familiar / Premium) queda cada función. Puedes ajustarlo.

---

## 1. Registro de movimientos por voz

**Qué hace.** El usuario pulsa un botón de micrófono, dice en lenguaje natural "gasté diez mil bolívares en un pago móvil de comida", y la app: (a) transcribe la voz a texto, (b) interpreta el texto y arma un movimiento (monto, moneda, categoría sugerida, descripción, fecha), y (c) muestra el formulario de "Nuevo movimiento" **ya rellenado** para que el usuario solo confirme.

**Arquitectura propuesta (dos etapas).**

- **Etapa 1 — Voz a texto (transcripción):** usar el paquete `speech_to_text` de Flutter, que aprovecha el reconocimiento de voz **del propio teléfono** (Android/iOS). Ventajas: es gratis, funciona en español, no consume tu cuota de IA y respeta la privacidad (el audio no sale a un servidor tuyo). Requiere permiso de micrófono (`RECORD_AUDIO` en Android).

- **Etapa 2 — Texto a movimiento (interpretación):** enviar el texto transcrito a tu **proxy de IA existente** (`ai_proxy_service.dart`, que ya llama a Gemini). Se agrega un método nuevo, por ejemplo `parseTransactionFromText(String frase)`, con un prompt que pida devolver **solo JSON** con los campos: `amount`, `currency` (USD/VES/EUR/COP/BRL), `type` (gasto/ingreso), `categoryHint`, `description`, `date`. Es el mismo patrón que ya usas para el escaneo de recibos (`extractReceipt`), así que reutilizas casi toda la infraestructura.

**Flujo de datos:** botón micrófono → `speech_to_text` (texto) → `ai_proxy_service.parseTransactionFromText` (JSON) → precargar `TransactionForm` → usuario confirma → se guarda igual que hoy (mismo `transactions_provider.save`, misma conversión a USD equivalente, misma sincronización a Supabase).

**Interfaz de usuario.**
- Un botón de micrófono flotante en la pantalla de transacciones (o junto al botón "+"), y/o dentro del formulario de nuevo movimiento.
- Mientras escucha: animación de onda + el texto que va reconociendo en vivo.
- Al terminar: abre el formulario precargado. **Nunca guarda sin confirmación del usuario** (evita errores de transcripción).

**Archivos afectados.**
- Nuevo: `lib/core/services/voice_input_service.dart` (envuelve `speech_to_text`).
- `lib/core/services/ai_proxy_service.dart` (nuevo método `parseTransactionFromText`).
- `lib/features/transactions/presentation/widgets/transaction_form.dart` (aceptar valores iniciales precargados).
- `lib/features/transactions/presentation/pages/transactions_page.dart` (botón de micrófono).
- Opcional en servidor: una Edge Function nueva o extender la de recibos si prefieres que el prompt viva en el servidor (recomendado, para no exponer el prompt en la app).
- `pubspec.yaml`: `speech_to_text`.
- `android/app/src/main/AndroidManifest.xml`: permiso de micrófono.
- Textos en los tres idiomas (`.arb`).

**Plan sugerido:** Premium (es una función "estrella" y de valor, como en Platica que la pone en Pro/Premium). El plan Gratuito podría tener un número limitado de usos por mes.

**Esfuerzo:** medio. 2–3 días de trabajo. El riesgo técnico es bajo porque reutiliza el patrón del escaneo de recibos.

**Riesgos:** calidad de transcripción con acentos/ruido (se mitiga con la confirmación obligatoria); permisos de micrófono (declararlo bien en la ficha de Data safety de Play como dato procesado de forma efímera, igual que las fotos).

---

## 2. Más monedas (COP y BRL)

**Qué hace.** Sumar el **peso colombiano (COP)** y el **real brasileño (BRL)** a las monedas actuales (USD, VES, EUR), para registrar y convertir montos en ellas. **Sin USDT** (ver decisión 1).

**Cómo encaja.** Tu servicio de tasas (`exchange_rate_service.dart`) ya maneja un modelo `VesRates` con BCV, paralelo y euro. Se extiende para incorporar las tasas de COP y BRL frente al USD:
- Fuente de tasa: la misma `frankfurter.dev` (BCE/mercado) ya te da USD↔EUR; también da **USD↔COP** y **USD↔BRL** (son monedas soportadas). Como respaldo, `open.er-api.com`. Así no dependes de una fuente venezolana para monedas que no son bolívar.
- Se agregan campos `usdCop` y `usdBrl` al modelo de tasas y al caché (subir la versión de clave de caché, por ejemplo `_v4`).
- La Edge Function `update-exchange-rates` se amplía para traer y guardar esas dos tasas (igual que ya hiciste con el euro).

**Conversión.** Tu lógica de "equivalente en USD" (`usdEquiv`) ya centraliza todo en dólares. Solo hay que añadir las reglas: monto en COP → USD dividiendo por `usdCop`; monto en BRL → USD dividiendo por `usdBrl`. El resto (mostrar en la moneda principal, balances) funciona igual.

**Interfaz.**
- Agregar las opciones COP y BRL en: el selector de moneda del formulario de movimiento (los "chips" de moneda), el selector de **moneda principal** en Ajustes, y el conmutador de moneda del panel principal.
- Símbolos y formato: COP y BRL usan separadores distintos; usar `intl` con el `locale` de cada moneda.

**Archivos afectados.**
- `lib/core/services/exchange_rate_service.dart` (modelo + fetch COP/BRL).
- `supabase/functions/update-exchange-rates/index.ts` (traer y guardar COP/BRL).
- `lib/features/dashboard/providers/display_prefs_provider.dart` (permitir COP/BRL como principal).
- `lib/features/transactions/.../transaction_form.dart` (chips de moneda) — **cuidado**: recordar la regla de que un widget que devuelve `Expanded` no puede ir dentro de un `Wrap`; con 5 monedas quizá el `Row` de chips ya no quepa y haya que rediseñar esa fila a una lista horizontal desplazable, no a un `Wrap` de `Expanded`.
- `transactions_provider.dart` (reglas de `usdEquiv` para COP/BRL).
- Textos `.arb`.

**Plan sugerido:** todas las monedas disponibles en todos los planes (no tiene sentido cobrar por una moneda).

**Esfuerzo:** bajo-medio. 1–2 días. Lo más delicado es el rediseño de la fila de selección de moneda con 5 opciones.

**Riesgo de política:** ninguno con COP/BRL (moneda normal). USDT queda fuera a propósito.

---

## 3. Agenda de pagos programados con recordatorios

**Qué hace.** Una lista de "próximos pagos e ingresos" con fecha y recordatorio (por ejemplo, "alquiler el día 5", "cobro de sueldo el 15"), que avisa al usuario antes de la fecha y permite registrar el movimiento con un toque cuando ocurre.

**Cómo encaja.** Ya tienes **transacciones recurrentes** (`recurring_service.dart`) y **notificaciones** (`fcm_service.dart` / `notification_service.dart`). La agenda se puede construir de dos maneras:
- **Opción A (recomendada, más rápida):** extender lo recurrente con un campo de "próxima fecha" y una **vista de agenda** que liste las próximas ocurrencias (de recurrentes + pagos puntuales programados), ordenadas por fecha, con su recordatorio. Reutilizas casi todo.
- **Opción B (más trabajo):** una tabla nueva `scheduled_payments` independiente de lo recurrente. Da más flexibilidad pero duplica lógica.

Propongo la **Opción A**.

**Recordatorios.** Programar notificaciones **locales** (con `flutter_local_notifications`, que probablemente ya usas junto a FCM) X días/horas antes de la fecha. Las notificaciones locales no dependen del servidor y funcionan sin conexión, ideal para recordatorios de calendario.

**Interfaz.**
- Nueva pestaña o sección "Agenda" (o "Próximos pagos") con la lista cronológica.
- Cada ítem: nombre, monto, moneda, fecha, y botón "Registrar ahora" (crea el movimiento real).
- Ajuste de "avisarme con X días de anticipación".

**Archivos afectados.**
- `lib/core/services/recurring_service.dart` (o nuevo `scheduled_payments`).
- Migración Supabase (campo de próxima fecha / tabla nueva) + tabla Drift equivalente + regenerar `app_database.g.dart` con `build_runner`.
- `lib/core/services/notification_service.dart` (programar locales).
- Nueva pantalla `lib/features/agenda/…`.
- Textos `.arb`.

**Plan sugerido:** Gratuito con límite (por ejemplo, hasta 3 pagos programados); ilimitado en Familiar/Premium.

**Esfuerzo:** medio. 3–4 días (la parte de notificaciones locales programadas y la migración de base de datos son las que más cuidado piden).

---

## 4. Proyecciones (previsión de los próximos meses)

**Qué hace.** Estimar cómo quedará el saldo en los próximos 1–6 meses, a partir del historial de ingresos/gastos, los movimientos recurrentes y los pagos programados de la agenda. Responde a "¿cuánto puedo ahorrar?" y "¿me va a alcanzar?".

**Cómo encaja.** Es cálculo local, no necesita servidor ni IA. Un servicio nuevo `projection_service.dart` que:
- Toma el promedio de ingresos y gastos de los últimos N meses (ya calculas resúmenes mensuales en `transactions_dao`).
- Suma los recurrentes conocidos y los pagos programados de la agenda (sección 3).
- Proyecta el saldo mes a mes hacia adelante.
- Todo en la moneda principal del usuario, usando tu conversión existente.

**Interfaz.**
- Una tarjeta en el panel principal ("Proyección: fin de mes ~ X") y/o una pantalla con un gráfico de línea de saldo proyectado por mes. Para el gráfico, usar el mismo enfoque que ya tienes en la sección de tendencias.
- Mostrar claramente que es una **estimación** basada en tus promedios, no una promesa.

**Archivos afectados.**
- Nuevo `lib/core/services/projection_service.dart`.
- Nuevo proveedor Riverpod y widget/pantalla en `lib/features/dashboard/…`.
- Reutiliza `transactions_dao` (resúmenes), recurrentes y agenda.
- Textos `.arb`.

**Plan sugerido:** Premium (es análisis avanzado). Una versión simple (solo fin de mes actual) podría estar en Familiar.

**Esfuerzo:** medio. 2–3 días. Depende de que la agenda (sección 3) exista para que la proyección sea buena, así que conviene hacerla después.

**Nota de honestidad:** una proyección es una estimación estadística; hay que redactar los textos con cuidado para que no se lea como asesoría financiera (que dispararía la política de Google). "Estimación de tu saldo según tus promedios" es seguro; "te recomendamos invertir/ahorrar en X" no.

---

## 5. Edición manual de la tasa de cambio

**Qué hace.** Permitir que el usuario **ajuste a mano** la tasa (por ejemplo, la paralela) cuando la automática no coincide con la que él usó en una compra concreta, o para fijar una tasa personal.

**Cómo encaja.** Hoy tu `display_prefs_provider` guarda qué tasa usar (BCV / paralela). Se agrega:
- **Nivel global:** un campo opcional "tasa manual" en las preferencias; si está puesto, la app lo usa en lugar de la automática, y muestra un aviso "usando tu tasa manual: X". Botón para "volver a la automática".
- **Nivel por movimiento (opcional, más potente):** permitir escribir la tasa concreta al cargar un movimiento en VES, de modo que ese movimiento quede con su tasa real. Esto requiere guardar la tasa usada en cada transacción (campo `rate_used`), lo cual además mejora la exactitud histórica.

Recomiendo empezar por el **nivel global** (rápido) y dejar el por-movimiento como mejora posterior.

**Interfaz.**
- En Ajustes → sección de moneda/tasa: un campo editable con la tasa actual y un interruptor "usar tasa manual".
- En el banner de tasa que ya muestras cuando la moneda es VES, un lápiz para editar rápido.

**Archivos afectados.**
- `lib/features/dashboard/providers/display_prefs_provider.dart` (campo tasa manual + persistencia).
- `lib/features/settings/presentation/pages/settings_page.dart` (UI).
- Donde se resuelve la tasa efectiva (el servicio/lugar que hoy decide BCV vs paralela).
- Si haces el nivel por-movimiento: migración para `rate_used` + Drift + `build_runner`.
- Textos `.arb`.

**Plan sugerido:** disponible en todos los planes.

**Esfuerzo:** bajo (nivel global): 1 día. Medio si agregas el por-movimiento con campo nuevo en base de datos.

---

## 6. Evaluación e incorporación de cobros por Pago Móvil

Esta es la más delicada, por eso la trato aparte y con honestidad total.

### 6.1 El problema con Google Play

La política de pagos de Google Play exige que, para **bienes y servicios digitales dentro de una app distribuida en Google Play** (como desbloquear el plan Premium), se use **Google Play Billing**. Cobrar ese desbloqueo por **Pago Móvil dentro de la app de Play** viola esa política y puede hacer que suspendan la app. Es decir: **no** podemos poner "paga tu Premium por Pago Móvil" dentro de la app que está en Play. Platica lo hace, pero es una zona gris y no es una razón para exponerte a una suspensión, sobre todo ahora que acabas de limpiar tu cuenta de un problema de política.

### 6.2 La ruta segura (recomendada)

Cobrar el Pago Móvil **fuera de la app de Play**:

- **En la versión web y de escritorio** (que tú ya tienes y distribuyes desde tu landing, fuera de Google Play), sí puedes cobrar el Premium por Pago Móvil libremente: ahí Google no tiene injerencia.
- El usuario paga por Pago Móvil, y ese pago le activa el plan Premium **en su cuenta** (que es la misma cuenta de Supabase que usa en el teléfono). Como el plan vive en Supabase (`profiles.plan_name`, activado por tu función `set_user_plan`), **el Premium comprado por la web se refleja automáticamente en la app del teléfono** al iniciar sesión. Así el usuario venezolano paga por un canal que sí funciona para él, y disfruta Premium en el móvil, sin que la app de Play cobre nada por dentro.
- Dentro de la app de Play: si quieres, un texto neutro tipo "También puedes gestionar tu plan desde budget-familiar.app" **sin** enlace de pago directo (Google tampoco permite dirigir agresivamente al pago externo; conviene revisar el matiz vigente, que ha ido cambiando con fallos judiciales recientes).

### 6.3 Flujo operativo del Pago Móvil (web/escritorio)

1. El usuario elige plan y ve los datos de Pago Móvil (teléfono, cédula/RIF, banco) y el monto en bolívares del día (usando tu propia tasa).
2. Hace el Pago Móvil desde su banco y **registra la referencia** (número de confirmación) en tu web.
3. **Verificación del pago.** Dos niveles:
   - **Manual (para empezar, rápido y sin costo):** tú (o un ayudante) confirmas la referencia contra tu cuenta y activas el plan ejecutando/`set_user_plan`. Sirve para el volumen inicial.
   - **Semi-automática (después):** una Edge Function que reciba la referencia y, si tu banco lo permite, la valide; o una conciliación por lote. La automatización total del Pago Móvil en Venezuela es difícil porque pocos bancos dan interfaz de consulta; casi todos los proyectos arrancan con verificación manual.
4. Al confirmar, se llama a tu función **ya existente** `set_user_plan(user_id, 'premium'|'family', ciclo, vencimiento)`, que activa el plan. No hay que inventar nada nuevo del lado del plan: esa tubería ya está construida.
5. Como no hay renovación automática por Pago Móvil, se maneja por **vencimiento**: el plan trae `premium_expires_at`; unos días antes, un recordatorio para volver a pagar.

### 6.4 Qué construir

- **Web de pago** (en tu landing o una sección nueva): selección de plan, datos de Pago Móvil, monto en bolívares calculado con tu tasa, formulario de referencia. Esto vive en `docs/` (Vercel) o en la app web.
- **Registro de solicitudes de pago** en Supabase (tabla `payment_requests`: usuario, plan, monto, referencia, estado pendiente/confirmado).
- **Panel simple de confirmación** para ti (aunque sea una consulta o una pantalla mínima) para aprobar y disparar `set_user_plan`.
- **Recordatorio de vencimiento** (notificación + correo).

**Esfuerzo:** medio-alto. 4–6 días, la mayor parte en la web de pago, la tabla y el flujo de confirmación. La ventaja es que reutiliza `set_user_plan`.

**Beneficio:** desbloquea el mercado venezolano de verdad (el que no puede pagar por Google Play) y te quedas con casi todo el ingreso (menos comisiones locales), sin el 15–30 % de Google. Es, según el análisis de la competencia, probablemente tu mayor palanca de ingresos.

---

## 7. Orden de implementación recomendado

Ordenado por dependencia y por relación valor/esfuerzo:

1. **Edición manual de la tasa (nivel global)** — 1 día, valor inmediato, sin base de datos. Buen primer paso.
2. **Más monedas (COP, BRL)** — 1–2 días, amplía mercado, bajo riesgo.
3. **Registro por voz** — 2–3 días, es el diferenciador de marketing más fuerte frente a Platica.
4. **Agenda de pagos programados** — 3–4 días, base para la proyección.
5. **Proyecciones** — 2–3 días, se apoya en la agenda; hacerla después.
6. **Cobro por Pago Móvil (web/escritorio)** — 4–6 días, mayor palanca de ingresos; se puede hacer en paralelo porque toca sobre todo la web, no la app.

**Total aproximado:** 3 a 4 semanas de trabajo enfocado para las seis, hechas por partes y probando cada una antes de la siguiente.

Cada función implica: cambios de código, en varios casos una **migración de base de datos** (con `build_runner` para Drift) y **regenerar los idiomas** (`flutter gen-l10n`), y luego **compilar y subir un `.aab` nuevo**. La del Pago Móvil además implica trabajo en la web/escritorio, no solo en la app.

---

## 8. Resumen de decisiones pendientes

- ¿Confirmas **excluir USDT** y agregar solo COP y BRL? (Recomendado: sí.)
- ¿Confirmas la **ruta segura** de Pago Móvil (cobro por web/escritorio, no dentro de la app de Play)? (Recomendado: sí.)
- ¿Te sirve el **orden** de la sección 7, o prefieres priorizar otra función primero (por ejemplo, la voz o el Pago Móvil antes que el resto)?

Cuando me confirmes estos tres puntos, empiezo a implementar la primera función de la lista, con commits limpios y entregándote el comando de push para que tú lo ejecutes, como siempre.
