-- ── app_config: configuración remota pública para el landing ──────────────────
-- Permite mostrar/ocultar la descarga de escritorio y actualizar su URL/versión
-- sin re-desplegar la landing (GitHub Pages). El landing lee esta tabla con la
-- clave publishable (anon) vía REST; solo el rol de servicio / dashboard escribe.

create table if not exists public.app_config (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.app_config enable row level security;

-- Lectura pública (landing sin sesión + usuarios autenticados).
drop policy if exists "app_config public read" on public.app_config;
create policy "app_config public read"
  on public.app_config
  for select
  to anon, authenticated
  using (true);

-- Sin políticas de escritura: solo service_role / dashboard pueden modificar.

-- Fila inicial del landing (descarga de escritorio desactivada por defecto).
insert into public.app_config (key, value)
values (
  'landing',
  jsonb_build_object(
    'desktop_download_enabled', false,
    'desktop_download_url', '',
    'desktop_version', ''
  )
)
on conflict (key) do nothing;
