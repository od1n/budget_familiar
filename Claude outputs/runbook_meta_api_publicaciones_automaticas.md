# Runbook — Conectar Instagram/Facebook (El Hato Pascher) a n8n para publicar automáticamente

Objetivo: que n8n pueda publicar posts (imagen + texto) en Instagram y Facebook de El Hato Pascher sin intervención manual, combinando contenido reciclado (blog/catálogo de la web) y contenido nuevo generado con IA.

**Ya hecho (04/09/2026):** verificación del negocio "El Hato Pascher c.a" completada en el Centro de seguridad de Meta Business Suite.

Investigué los requisitos actuales (2026) de la API de Meta antes de armar esta guía — quedan las fuentes al final.

---

## Parte 1 — Lo que tienes que hacer tú en Meta (yo no puedo entrar a tu cuenta de Meta)

### Paso 1 — Confirmar que la cuenta de Instagram es de tipo profesional

1. Entra a `https://business.facebook.com` con tu cuenta.
2. En el menú lateral, busca "Cuentas de Instagram" (ya la vi en tu captura anterior, dentro de "Cuentas").
3. Haz clic en la cuenta de Instagram de El Hato Pascher.
4. Verifica que el tipo de cuenta sea "Empresa" o "Creador" (no "Personal"). La API de publicación de Meta **no funciona con cuentas personales**. Si todavía es personal, cámbiala a Empresa desde la app de Instagram (Ajustes → Cuenta → Cambiar a cuenta profesional).
5. Confirma que esa cuenta de Instagram esté vinculada a la Página de Facebook "El Hato Pascher c.a" (en el mismo panel de "Cuentas de Instagram" debería mostrar la Página vinculada).

### Paso 2 — Crear la app en Meta for Developers

1. Entra a `https://developers.facebook.com/apps/`
2. Haz clic en el botón "Crear app" (arriba a la derecha).
3. Cuando pregunte el tipo de app, selecciona "Empresa" ("Business") — esto da acceso tanto a la API de Facebook como a la de Instagram con la misma app.
4. Asocia la app a tu Portafolio empresarial "El Hato Pascher c.a" (la misma verificada el 04/09) cuando te lo pida durante la creación.
5. Ponle un nombre descriptivo, por ejemplo "EHP Publicaciones Automaticas".

### Paso 3 — Agregar el producto de Instagram a la app

1. Dentro del panel de la app que acabas de crear, en el menú lateral izquierdo, busca la sección "Agregar productos" ("Add products").
2. Busca "Instagram Graph API" (o "Instagram" según cómo lo muestre el panel) y haz clic en "Configurar" / "Set up".
3. Sigue el asistente para vincular la Página de Facebook y la cuenta de Instagram de El Hato Pascher a esta app (debería aparecer directo porque ya están conectadas entre sí desde Meta Business Suite).

### Paso 4 — Confirmar los permisos necesarios

La app necesita estos 5 permisos para poder publicar (anótalos, los vas a ver pedidos durante la generación del token en el Paso 6):

- `pages_show_list`
- `pages_read_engagement`
- `pages_manage_posts`
- `instagram_basic`
- `instagram_content_publish`

**Dato importante que te ahorra un paso:** Meta exige una revisión formal de la app ("App Review") solo cuando la app va a operar sobre cuentas de **otras personas**. Como tú vas a ser el administrador tanto de la app como de la Página/cuenta de Instagram, puedes usar estos 5 permisos en "modo Desarrollo" sin pasar por App Review — mientras la app se quede sobre tus propias cuentas, no hace falta ese trámite.

### Paso 5 — Crear un "Usuario del sistema" (System User) — más estable que un token normal

Un token de acceso normal (el que se genera al loguearte) expira en 1 hora, y aunque se puede extender, solo dura 60 días — tendrías que renovarlo cada 2 meses a mano. Para una automatización que corre sola, conviene un **token de Usuario del sistema**, que no expira.

1. Entra a `https://business.facebook.com/settings/system-users` (dentro de "Usuarios" → "Usuarios del sistema", que ya vi en el menú de tu captura).
2. Haz clic en "Añadir" para crear un usuario del sistema nuevo.
3. Ponle un nombre, por ejemplo "n8n-publicaciones", y asígnale el rol "Empleado" (no hace falta "Administrador").
4. Una vez creado, haz clic en él y luego en "Añadir activos" ("Assign assets"):
   - Asígnale la Página de Facebook "El Hato Pascher c.a" con permiso de "Gestionar la Página" ("Manage Page").
   - Asígnale la app que creaste en el Paso 2, con permiso de control total.
5. Con el usuario del sistema seleccionado, haz clic en "Generar nuevo token" ("Generate new token").
6. Selecciona la app que creaste, marca los 5 permisos del Paso 4, y genera el token.
7. **Copia ese token y guárdalo en tu gestor de contraseñas de inmediato** — Meta solo lo muestra una vez. Ese token no tiene fecha de expiración mientras no lo revoques.

### Paso 6 — Conseguir dos identificadores que voy a necesitar

1. Entra a `https://developers.facebook.com/tools/explorer/`
2. En el selector de la app (arriba), elige la app que creaste.
3. En el campo de consulta, escribe `me/accounts` y haz clic en "Enviar" ("Submit"). Ahí va a aparecer el **ID de la Página** de El Hato Pascher — anótalo.
4. Cambia la consulta a `{ID-DE-LA-PAGINA}?fields=instagram_business_account` (reemplazando por el ID real que anotaste) y envíala. Ahí va a aparecer el **ID de la cuenta de Instagram Business** — anótalo también.

Con el token del Paso 5 y estos dos IDs, ya tengo todo lo que necesito para armar el flujo en n8n.

---

## Parte 2 — Lo que armo yo en n8n una vez que me pases esos 3 datos

Guarda el token, el ID de Página y el ID de Instagram en un lugar seguro (no me los pegues en el chat en texto plano — te aviso el paso exacto para cargarlos directo como credencial en n8n cuando lleguemos ahí, igual que hicimos antes con la API key de Evolution API).

El flujo que voy a construir en n8n:

1. **Cola de contenido:** una tabla (Postgres, la misma base que ya usas) con una fila por publicación pendiente — con columnas: fuente (blog/catálogo o "generar con IA"), texto del post, URL de la imagen, estado (pendiente/publicado), fecha programada.
2. **Para el contenido reciclado** (blog/catálogo): un paso que arma el texto del post a partir del artículo o producto (resumen corto + llamado a la acción) y usa la imagen ya existente en la web.
3. **Para el contenido nuevo con IA:** un paso que genera el texto del post con Claude API, y la imagen (a definir contigo si se genera con IA o se usa una foto real del catálogo).
4. **Paso de revisión humana** (igual que ya documentamos para el módulo de SistemaGestion): antes de publicar, te llega una notificación por WhatsApp con una vista previa del post, y tienes que aprobarlo — nada sale sin tu confirmación.
5. **Publicación real vía Instagram Graph API** (dos pasos técnicos, uno por publicación):
   - Crear el "contenedor de medios": `POST /{ID-INSTAGRAM}/media` con la URL de la imagen y el texto.
   - Publicar el contenedor: `POST /{ID-INSTAGRAM}/media_publish`.
6. **Publicación en Facebook** (más simple, un solo paso): `POST /{ID-PAGINA}/feed` con el texto y la imagen.
7. **Registro:** marcar la fila de la cola como publicada, con fecha y enlace al post real.

**Límite a tener presente:** Meta limita cuántas publicaciones puede hacer una cuenta por API en una ventana de tiempo (no es un número fijo público, varía). Para el volumen normal de un negocio (1-2 posts al día), no debería ser un problema.

---

## Siguiente paso para ti

Completa los Pasos 1 a 6 de la Parte 1 (todo dentro de Meta, no requiere que yo intervenga), y cuando tengas el token del Usuario del sistema + los dos IDs, avísame y seguimos con la Parte 2.

---

## Fuentes consultadas

- [How to Automate Facebook & Instagram Posts with n8n in 2026 — Growwstacks](https://growwstacks.com/blog/automate-facebook-instagram-posts-n8n-meta-setup)
- [Instagram Graph API in 2026: Versions, Rate Limits & Content Publishing — Netrows](https://www.netrows.com/blog/instagram-graph-api-guide-2026)
- [Facebook Graph API | Nodes | n8n Docs](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.facebookgraphapi)
