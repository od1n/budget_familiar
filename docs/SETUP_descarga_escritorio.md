# Setup — Descarga de escritorio (Windows) desde el landing

El botón "Descargar para Windows" ya está en el landing pero **oculto**. Se
muestra/oculta leyendo la tabla `app_config` de Supabase (sin re-desplegar el
landing). Este es el flujo completo, una sola vez para dejarlo funcionando.

## 1. Crear la tabla `app_config` (migración)
Aplica la migración `supabase/migrations/019_app_config.sql`:

```powershell
cd D:\Desarrollo\Claude\Projects\budget_familiar
npx supabase db push --project-ref tnomtsvzkleowdsdfsyq
```

(O pega el contenido del `.sql` en el SQL Editor del dashboard:
https://supabase.com/dashboard/project/tnomtsvzkleowdsdfsyq/sql )

La tabla queda con lectura pública (RLS) y una fila `landing` con la descarga
**desactivada** por defecto.

## 2. Compilar y empaquetar el instalador de Windows
```powershell
cd D:\Desarrollo\Claude\Projects\budget_familiar
.\build_desktop.ps1 -Zip
```
Genera:
`D:\Desarrollo\Claude\Projects\budget_familiar\dist\BudgetFamiliar-Windows-vX.Y.Z.zip`

Es un ZIP portable: el usuario lo descomprime y ejecuta `budget_familiar.exe`
(no requiere instalación ni permisos de administrador).

## 3. Subir el ZIP a un GitHub Release
- Ve a tu repo → **Releases → Draft a new release**.
- Crea un tag (ej. `windows-v1.0.0`), sube el ZIP como *asset* y publica.
- Copia la **URL del asset** (clic derecho sobre el archivo subido → copiar
  enlace). Se ve así:
  `https://github.com/<usuario>/<repo>/releases/download/windows-v1.0.0/BudgetFamiliar-Windows-v1.0.0.zip`

## 4. Encender el interruptor (mostrar el botón)
En el SQL Editor de Supabase:

```sql
update public.app_config
set value = jsonb_build_object(
  'desktop_download_enabled', true,
  'desktop_download_url', 'https://github.com/<usuario>/<repo>/releases/download/windows-v1.0.0/BudgetFamiliar-Windows-v1.0.0.zip',
  'desktop_version', '1.0.0'
), updated_at = now()
where key = 'landing';
```

El botón aparece en el landing en el próximo refresco (nav, hero y CTA), sin
tocar código ni re-desplegar GitHub Pages.

## Apagar el interruptor (ocultar el botón)
```sql
update public.app_config
set value = jsonb_set(value, '{desktop_download_enabled}', 'false'),
    updated_at = now()
where key = 'landing';
```

## Actualizar a una versión nueva
Repite pasos 2 y 3 con la nueva versión y actualiza `desktop_download_url` y
`desktop_version` en la fila `landing` (paso 4). No hay que re-desplegar nada.

## Notas
- El landing usa la clave **publishable** (pública por diseño) solo para leer
  `app_config`; la RLS impide escrituras desde el cliente.
- El ZIP portable es la vía más simple. Si más adelante quieres un instalador
  `.msix` o `.exe` con Inno Setup (icono en menú inicio, auto-update), se puede
  agregar sobre este mismo flujo.
