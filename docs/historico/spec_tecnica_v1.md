# Especificación Técnica — App de Gestión Financiera Familiar
**Versión:** 1.0  
**Estado:** Borrador de Arquitectura  
**Última actualización:** 2026-05-25

---

## 1. RESUMEN DEL STACK TECNOLÓGICO

| Capa | Tecnología | Justificación |
|---|---|---|
| Frontend multiplataforma | Flutter (Dart) | Un solo codebase para Android, iOS, Windows, macOS. Renderizado propio (Impeller) garantiza consistencia visual entre plataformas. |
| Gestión de estado | Riverpod 2.x | Compilado en tiempo de build, sin magic strings, testeable. |
| Base de datos local | Drift (SQLite) | Wrapper type-safe sobre SQLite. Schema espeja el de Supabase, simplificando la lógica de sync. |
| Backend & Auth | Supabase (PostgreSQL) | Modelo relacional correcto para datos financieros. Row Level Security nativa. Realtime vía PostgreSQL. |
| Funciones serverless | Supabase Edge Functions (Deno/TypeScript) | Cron jobs para tasas, noticias e insights de AI. |
| Push notifications | Firebase Cloud Messaging | Estándar de la industria, SDK oficial para Flutter. |
| API de AI | Anthropic Claude API (claude-sonnet-4-5) | Mejor español, razonamiento financiero sólido, costo controlable. |
| Tasas de cambio | ExchangeRate-API + DolarToday feed | Cobertura internacional + tasa paralela VES real. |
| Noticias | NewsAPI.org | Cobertura de medios venezolanos y latinoamericanos en español. |
| Pagos (comercialización) | Stripe (internacional) + flujo manual (VE) | Stripe no opera con tarjetas venezolanas; se requiere flujo Zelle/PayMóvil con verificación manual. |

---

## 2. ESQUEMA COMPLETO DE BASE DE DATOS — SUPABASE (PostgreSQL)

### 2.1 Tablas de Sistema y Configuración

```sql
-- ============================================================
-- MONEDAS
-- ============================================================
CREATE TABLE currencies (
  code        VARCHAR(3)   PRIMARY KEY,
  name        VARCHAR(100) NOT NULL,
  symbol      VARCHAR(10)  NOT NULL,
  decimal_places INT        NOT NULL DEFAULT 2,
  is_active   BOOLEAN      DEFAULT TRUE,
  created_at  TIMESTAMPTZ  DEFAULT NOW()
);

-- Seed inicial
INSERT INTO currencies (code, name, symbol) VALUES
  ('USD', 'Dólar Estadounidense', '$'),
  ('VES', 'Bolívar Digital',      'Bs.D'),
  ('EUR', 'Euro',                  '€'),
  ('COP', 'Peso Colombiano',       '$'),
  ('BRL', 'Real Brasileño',        'R$'),
  ('ARS', 'Peso Argentino',        '$'),
  ('MXN', 'Peso Mexicano',         '$');


-- ============================================================
-- TASAS DE CAMBIO (SERIE HISTÓRICA)
-- ============================================================
CREATE TABLE exchange_rates (
  id            UUID         DEFAULT gen_random_uuid() PRIMARY KEY,
  from_currency VARCHAR(3)   REFERENCES currencies(code) NOT NULL,
  to_currency   VARCHAR(3)   REFERENCES currencies(code) NOT NULL,
  rate          DECIMAL(20,8) NOT NULL,
  rate_type     VARCHAR(20)  CHECK (rate_type IN ('official','parallel','custom')) NOT NULL,
  source        VARCHAR(100),  -- 'bcv', 'dolartoday', 'exchangerate-api', 'manual'
  valid_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  created_at    TIMESTAMPTZ  DEFAULT NOW()
);

CREATE INDEX idx_exchange_rates_pair_date
  ON exchange_rates (from_currency, to_currency, rate_type, valid_at DESC);


-- ============================================================
-- ÍNDICES DE INFLACIÓN
-- ============================================================
CREATE TABLE inflation_indices (
  id            UUID         DEFAULT gen_random_uuid() PRIMARY KEY,
  country_code  CHAR(2)      NOT NULL,
  period_month  DATE         NOT NULL, -- siempre primer día del mes
  monthly_rate  DECIMAL(8,4),          -- ej: 14.2 = 14.2%
  annual_rate   DECIMAL(8,4),
  source        TEXT,
  created_at    TIMESTAMPTZ  DEFAULT NOW(),
  UNIQUE (country_code, period_month)
);


-- ============================================================
-- PLANES DE SUSCRIPCIÓN
-- ============================================================
CREATE TABLE subscription_plans (
  id                      UUID         DEFAULT gen_random_uuid() PRIMARY KEY,
  name                    VARCHAR(50)  UNIQUE NOT NULL, -- 'beta','free','family','premium'
  display_name            VARCHAR(100) NOT NULL,
  max_members             INT          NOT NULL DEFAULT 1,
  ai_insights_enabled     BOOLEAN      DEFAULT FALSE,
  pdf_export_enabled      BOOLEAN      DEFAULT FALSE,
  desktop_enabled         BOOLEAN      DEFAULT FALSE,
  max_categories          INT          DEFAULT 10,
  price_usd               DECIMAL(10,2) DEFAULT 0,
  price_ves_ref           DECIMAL(20,2) DEFAULT 0, -- precio referencial en VES, actualizable
  billing_period          VARCHAR(20)  DEFAULT 'monthly', -- 'monthly','annual'
  is_active               BOOLEAN      DEFAULT TRUE,
  created_at              TIMESTAMPTZ  DEFAULT NOW()
);

-- Seed: planes iniciales
INSERT INTO subscription_plans
  (name, display_name, max_members, ai_insights_enabled, pdf_export_enabled, desktop_enabled, max_categories, price_usd)
VALUES
  ('beta',    'Beta Tester',    10, TRUE,  TRUE,  TRUE,  50, 0.00),
  ('free',    'Gratuito',        2, FALSE, FALSE, FALSE, 10, 0.00),
  ('family',  'Familiar',        5, FALSE, TRUE,  TRUE,  30, 4.99),
  ('premium', 'Premium',        10, TRUE,  TRUE,  TRUE,  50, 9.99);


-- ============================================================
-- CONFIGURACIÓN GLOBAL DE LA APP
-- ============================================================
CREATE TABLE app_config (
  key         VARCHAR(100) PRIMARY KEY,
  value       TEXT         NOT NULL,
  description TEXT,
  updated_at  TIMESTAMPTZ  DEFAULT NOW()
);

INSERT INTO app_config (key, value, description) VALUES
  ('beta_mode',              'true',  'Asigna plan beta a todos los nuevos registros'),
  ('news_cache_ttl_hours',   '6',     'Horas de vigencia de la caché de noticias'),
  ('insight_ttl_days',       '7',     'Días de vigencia de un AI insight antes de regenerar'),
  ('exchange_rate_cron',     '0 */6 * * *', 'Frecuencia de actualización de tasas'),
  ('insight_cron',           '0 9 * * 1',   'Cron de generación de insights: lunes a las 9am');


-- ============================================================
-- CACHÉ DE NOTICIAS
-- ============================================================
CREATE TABLE news_cache (
  id           UUID         DEFAULT gen_random_uuid() PRIMARY KEY,
  country_code CHAR(2)      NOT NULL,
  query_hash   VARCHAR(64)  NOT NULL, -- hash del query para distinguir búsquedas
  articles     JSONB        NOT NULL,
  cached_at    TIMESTAMPTZ  DEFAULT NOW(),
  expires_at   TIMESTAMPTZ  NOT NULL,
  UNIQUE (country_code, query_hash)
);


-- ============================================================
-- PLANTILLAS DE PROMPTS DE AI
-- ============================================================
CREATE TABLE ai_prompt_templates (
  id          UUID         DEFAULT gen_random_uuid() PRIMARY KEY,
  name        VARCHAR(100) UNIQUE NOT NULL,
  template    TEXT         NOT NULL, -- usa {{variable}} como placeholders
  version     INT          DEFAULT 1,
  is_active   BOOLEAN      DEFAULT TRUE,
  created_at  TIMESTAMPTZ  DEFAULT NOW(),
  updated_at  TIMESTAMPTZ  DEFAULT NOW()
);
```

### 2.2 Tablas de Usuarios y Grupos

```sql
-- ============================================================
-- PERFILES DE USUARIO (extiende auth.users de Supabase)
-- ============================================================
CREATE TABLE users (
  id                 UUID         REFERENCES auth.users(id) PRIMARY KEY,
  display_name       VARCHAR(100),
  avatar_url         TEXT,
  preferred_language VARCHAR(5)   DEFAULT 'es',
  country_code       CHAR(2)      DEFAULT 'VE',
  timezone           VARCHAR(50)  DEFAULT 'America/Caracas',
  created_at         TIMESTAMPTZ  DEFAULT NOW(),
  updated_at         TIMESTAMPTZ  DEFAULT NOW()
);

-- Trigger: crear perfil automáticamente al registrarse
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, display_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();


-- ============================================================
-- GRUPOS FAMILIARES
-- ============================================================
CREATE TABLE family_groups (
  id                 UUID         DEFAULT gen_random_uuid() PRIMARY KEY,
  name               VARCHAR(100) NOT NULL,
  primary_currency   VARCHAR(3)   REFERENCES currencies(code) DEFAULT 'USD',
  secondary_currency VARCHAR(3)   REFERENCES currencies(code) DEFAULT 'VES',
  country_code       CHAR(2)      DEFAULT 'VE',
  timezone           VARCHAR(50)  DEFAULT 'America/Caracas',
  beta_user          BOOLEAN      DEFAULT TRUE,
  created_by         UUID         REFERENCES users(id),
  created_at         TIMESTAMPTZ  DEFAULT NOW(),
  updated_at         TIMESTAMPTZ  DEFAULT NOW()
);

-- Trigger: asignar suscripción beta (o free según app_config) al crear grupo
CREATE OR REPLACE FUNCTION assign_default_subscription()
RETURNS TRIGGER AS $$
DECLARE
  v_beta_mode TEXT;
  v_plan_id   UUID;
BEGIN
  SELECT value INTO v_beta_mode FROM app_config WHERE key = 'beta_mode';
  IF v_beta_mode = 'true' THEN
    SELECT id INTO v_plan_id FROM subscription_plans WHERE name = 'beta';
  ELSE
    SELECT id INTO v_plan_id FROM subscription_plans WHERE name = 'free';
  END IF;

  INSERT INTO subscriptions (group_id, plan_id, status, trial_ends_at)
  VALUES (
    NEW.id,
    v_plan_id,
    CASE WHEN v_beta_mode = 'true' THEN 'active' ELSE 'trialing' END,
    NOW() + INTERVAL '30 days'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_family_group_created
  AFTER INSERT ON family_groups
  FOR EACH ROW EXECUTE FUNCTION assign_default_subscription();

-- Trigger: hacer admin al creador del grupo
CREATE OR REPLACE FUNCTION add_creator_as_admin()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO family_members (group_id, user_id, role)
  VALUES (NEW.id, NEW.created_by, 'admin');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_family_group_created_add_admin
  AFTER INSERT ON family_groups
  FOR EACH ROW EXECUTE FUNCTION add_creator_as_admin();


-- ============================================================
-- MIEMBROS DEL GRUPO
-- ============================================================
CREATE TABLE family_members (
  id        UUID         DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id  UUID         REFERENCES family_groups(id) ON DELETE CASCADE,
  user_id   UUID         REFERENCES users(id)         ON DELETE CASCADE,
  role      VARCHAR(20)  CHECK (role IN ('admin','member')) DEFAULT 'member',
  joined_at TIMESTAMPTZ  DEFAULT NOW(),
  UNIQUE (group_id, user_id)
);


-- ============================================================
-- SUSCRIPCIONES
-- ============================================================
CREATE TABLE subscriptions (
  id                       UUID         DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id                 UUID         REFERENCES family_groups(id) ON DELETE CASCADE,
  plan_id                  UUID         REFERENCES subscription_plans(id),
  status                   VARCHAR(20)  CHECK (status IN ('trialing','active','past_due','cancelled')) DEFAULT 'trialing',
  trial_ends_at            TIMESTAMPTZ,
  current_period_start     TIMESTAMPTZ,
  current_period_end       TIMESTAMPTZ,
  payment_provider         VARCHAR(30), -- 'stripe','zelle','pagomovil','manual'
  external_subscription_id TEXT,
  created_at               TIMESTAMPTZ  DEFAULT NOW(),
  updated_at               TIMESTAMPTZ  DEFAULT NOW()
);
```

### 2.3 Tablas Financieras Core

```sql
-- ============================================================
-- CATEGORÍAS
-- ============================================================
CREATE TABLE categories (
  id          UUID         DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id    UUID         REFERENCES family_groups(id) ON DELETE CASCADE, -- NULL = categoría del sistema
  name        VARCHAR(100) NOT NULL,
  icon_code   VARCHAR(50)  NOT NULL,   -- nombre del ícono en Flutter (MaterialIcons o custom)
  color_hex   CHAR(7)      NOT NULL,   -- formato '#RRGGBB'
  type        VARCHAR(10)  CHECK (type IN ('income','expense','both')) NOT NULL,
  is_system   BOOLEAN      DEFAULT FALSE,
  sort_order  INT          DEFAULT 0,
  is_active   BOOLEAN      DEFAULT TRUE,
  created_at  TIMESTAMPTZ  DEFAULT NOW()
);

-- Seed: categorías del sistema
INSERT INTO categories (group_id, name, icon_code, color_hex, type, is_system, sort_order) VALUES
  (NULL, 'Alimentación',     'restaurant',        '#E74C3C', 'expense', TRUE, 1),
  (NULL, 'Transporte',       'directions_car',    '#E67E22', 'expense', TRUE, 2),
  (NULL, 'Servicios',        'bolt',              '#3498DB', 'expense', TRUE, 3),
  (NULL, 'Salud',            'local_hospital',    '#2ECC71', 'expense', TRUE, 4),
  (NULL, 'Educación',        'school',            '#9B59B6', 'expense', TRUE, 5),
  (NULL, 'Entretenimiento',  'movie',             '#F39C12', 'expense', TRUE, 6),
  (NULL, 'Ropa',             'checkroom',         '#1ABC9C', 'expense', TRUE, 7),
  (NULL, 'Hogar',            'home',              '#34495E', 'expense', TRUE, 8),
  (NULL, 'Deudas',           'credit_card',       '#C0392B', 'expense', TRUE, 9),
  (NULL, 'Otros gastos',     'more_horiz',        '#95A5A6', 'expense', TRUE, 10),
  (NULL, 'Salario',          'work',              '#27AE60', 'income',  TRUE, 1),
  (NULL, 'Freelance',        'laptop',            '#2980B9', 'income',  TRUE, 2),
  (NULL, 'Inversiones',      'trending_up',       '#8E44AD', 'income',  TRUE, 3),
  (NULL, 'Otros ingresos',   'attach_money',      '#16A085', 'income',  TRUE, 4);


-- ============================================================
-- TRANSACCIONES
-- ============================================================
CREATE TABLE transactions (
  id                    UUID         DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id              UUID         REFERENCES family_groups(id)  ON DELETE CASCADE NOT NULL,
  user_id               UUID         REFERENCES users(id)          NOT NULL,
  category_id           UUID         REFERENCES categories(id),
  amount                DECIMAL(20,2) NOT NULL,
  currency_code         VARCHAR(3)   REFERENCES currencies(code)   NOT NULL,
  amount_usd_equivalent DECIMAL(20,8),       -- snapshot del valor en USD al momento del registro
  exchange_rate_id      UUID         REFERENCES exchange_rates(id), -- tasa usada para el snapshot
  type                  VARCHAR(10)  CHECK (type IN ('income','expense')) NOT NULL,
  date                  DATE         NOT NULL,
  description           TEXT,
  payment_method        VARCHAR(20)  CHECK (payment_method IN
                          ('cash','card','transfer','pagomovil','zelle','crypto','other')),
  notes                 TEXT,
  tags                  TEXT[],                -- etiquetas libres ej: ['mercado','familiar']
  created_at            TIMESTAMPTZ  DEFAULT NOW(),
  updated_at            TIMESTAMPTZ  DEFAULT NOW()
);

CREATE INDEX idx_transactions_group_date
  ON transactions (group_id, date DESC);
CREATE INDEX idx_transactions_group_category
  ON transactions (group_id, category_id);
CREATE INDEX idx_transactions_group_type_date
  ON transactions (group_id, type, date DESC);


-- ============================================================
-- PRESUPUESTOS MENSUALES
-- ============================================================
CREATE TABLE budgets (
  id               UUID         DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id         UUID         REFERENCES family_groups(id) ON DELETE CASCADE NOT NULL,
  category_id      UUID         REFERENCES categories(id)   NOT NULL,
  currency_code    VARCHAR(3)   REFERENCES currencies(code) NOT NULL,
  amount           DECIMAL(20,2) NOT NULL,
  month            DATE         NOT NULL, -- siempre el día 1 del mes
  alert_50_sent    BOOLEAN      DEFAULT FALSE,
  alert_80_sent    BOOLEAN      DEFAULT FALSE,
  alert_100_sent   BOOLEAN      DEFAULT FALSE,
  created_at       TIMESTAMPTZ  DEFAULT NOW(),
  updated_at       TIMESTAMPTZ  DEFAULT NOW(),
  UNIQUE (group_id, category_id, month)
);


-- ============================================================
-- METAS DE AHORRO
-- ============================================================
CREATE TABLE savings_goals (
  id                           UUID         DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id                     UUID         REFERENCES family_groups(id) ON DELETE CASCADE NOT NULL,
  name                         VARCHAR(100) NOT NULL,
  description                  TEXT,
  target_amount                DECIMAL(20,2) NOT NULL,
  current_amount               DECIMAL(20,2) DEFAULT 0,
  currency_code                VARCHAR(3)   REFERENCES currencies(code) NOT NULL,
  deadline                     DATE,
  icon_code                    VARCHAR(50),
  color_hex                    CHAR(7),
  inflation_adjustment_enabled BOOLEAN      DEFAULT FALSE,
  adjusted_target_amount       DECIMAL(20,2), -- recalculado por Edge Function periódicamente
  status                       VARCHAR(20)  CHECK (status IN ('active','completed','cancelled','paused'))
                                            DEFAULT 'active',
  created_at                   TIMESTAMPTZ  DEFAULT NOW(),
  updated_at                   TIMESTAMPTZ  DEFAULT NOW()
);


-- ============================================================
-- INVERSIONES
-- ============================================================
CREATE TABLE investments (
  id             UUID         DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id       UUID         REFERENCES family_groups(id) ON DELETE CASCADE NOT NULL,
  user_id        UUID         REFERENCES users(id),
  name           VARCHAR(100) NOT NULL,
  type           VARCHAR(30)  CHECK (type IN
                   ('fixed_term','fund','stock','crypto','real_estate','other')),
  initial_amount DECIMAL(20,2) NOT NULL,
  current_value  DECIMAL(20,2),
  currency_code  VARCHAR(3)   REFERENCES currencies(code) NOT NULL,
  start_date     DATE,
  maturity_date  DATE,
  institution    VARCHAR(100),
  notes          TEXT,
  is_active      BOOLEAN      DEFAULT TRUE,
  created_at     TIMESTAMPTZ  DEFAULT NOW(),
  updated_at     TIMESTAMPTZ  DEFAULT NOW()
);


-- ============================================================
-- SOBRES VIRTUALES
-- ============================================================
CREATE TABLE virtual_envelopes (
  id               UUID         DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id         UUID         REFERENCES family_groups(id) ON DELETE CASCADE NOT NULL,
  category_id      UUID         REFERENCES categories(id),
  name             VARCHAR(100) NOT NULL,
  allocated_amount DECIMAL(20,2) NOT NULL,
  spent_amount     DECIMAL(20,2) DEFAULT 0,
  currency_code    VARCHAR(3)   REFERENCES currencies(code) NOT NULL,
  period_start     DATE         NOT NULL,
  period_end       DATE         NOT NULL,
  is_active        BOOLEAN      DEFAULT TRUE,
  created_at       TIMESTAMPTZ  DEFAULT NOW()
);


-- ============================================================
-- AI INSIGHTS
-- ============================================================
CREATE TABLE ai_insights (
  id               UUID         DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id         UUID         REFERENCES family_groups(id) ON DELETE CASCADE NOT NULL,
  generated_at     TIMESTAMPTZ  DEFAULT NOW(),
  expires_at       TIMESTAMPTZ  NOT NULL,
  context_snapshot JSONB,       -- datos usados para generarlo (para debugging y auditoría)
  recommendations  JSONB        NOT NULL,
  /*
    Estructura de recommendations:
    [
      {
        "type": "spending_alert" | "savings_tip" | "investment_advice" | "macro_context",
        "priority": "high" | "medium" | "low",
        "category": "Alimentación",
        "title": "Gasto elevado en restaurantes",
        "message": "Has gastado 23% más en restaurantes...",
        "action": "Reducir esta categoría liberaría Bs.D 45 para tu meta 'Vacaciones'",
        "related_goal_id": "uuid-or-null",
        "supporting_data": { "current": 120, "average": 97, "delta_pct": 23 }
      }
    ]
  */
  news_sources     JSONB,        -- artículos usados como contexto
  model_used       VARCHAR(100),
  tokens_used      INT,
  language         VARCHAR(5)   DEFAULT 'es',
  created_at       TIMESTAMPTZ  DEFAULT NOW()
);

CREATE INDEX idx_ai_insights_group_expires
  ON ai_insights (group_id, expires_at DESC);
```

### 2.4 Row Level Security (RLS)

```sql
-- ============================================================
-- FUNCIONES HELPER
-- ============================================================
CREATE OR REPLACE FUNCTION is_group_member(group_uuid UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM family_members
    WHERE group_id = group_uuid AND user_id = auth.uid()
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION is_group_admin(group_uuid UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM family_members
    WHERE group_id = group_uuid AND user_id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION get_user_groups()
RETURNS SETOF UUID AS $$
  SELECT group_id FROM family_members WHERE user_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ============================================================
-- HABILITAR RLS EN TODAS LAS TABLAS PROTEGIDAS
-- ============================================================
ALTER TABLE users              ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_groups      ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members     ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories         ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets            ENABLE ROW LEVEL SECURITY;
ALTER TABLE savings_goals      ENABLE ROW LEVEL SECURITY;
ALTER TABLE investments        ENABLE ROW LEVEL SECURITY;
ALTER TABLE virtual_envelopes  ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_insights        ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- POLÍTICAS
-- ============================================================

-- users: solo ves y editas tu propio perfil
CREATE POLICY "users_self_read"   ON users FOR SELECT USING (id = auth.uid());
CREATE POLICY "users_self_update" ON users FOR UPDATE USING (id = auth.uid());

-- family_groups: visible si eres miembro
CREATE POLICY "groups_member_read" ON family_groups
  FOR SELECT USING (is_group_member(id));
CREATE POLICY "groups_admin_update" ON family_groups
  FOR UPDATE USING (is_group_admin(id));
CREATE POLICY "groups_insert" ON family_groups
  FOR INSERT WITH CHECK (created_by = auth.uid());

-- family_members: visibles para miembros del grupo; solo admin puede agregar/quitar
CREATE POLICY "members_read"   ON family_members FOR SELECT USING (is_group_member(group_id));
CREATE POLICY "members_insert" ON family_members FOR INSERT WITH CHECK (is_group_admin(group_id));
CREATE POLICY "members_delete" ON family_members FOR DELETE USING (is_group_admin(group_id));

-- subscriptions: solo admins del grupo
CREATE POLICY "subs_admin_read" ON subscriptions
  FOR SELECT USING (is_group_admin(group_id));

-- categories: sistema (group_id IS NULL) visibles para todos; personalizadas solo para miembros
CREATE POLICY "categories_read" ON categories
  FOR SELECT USING (group_id IS NULL OR is_group_member(group_id));
CREATE POLICY "categories_admin_write" ON categories
  FOR INSERT WITH CHECK (is_group_admin(group_id));
CREATE POLICY "categories_admin_update" ON categories
  FOR UPDATE USING (is_group_admin(group_id));

-- transactions: visibles para miembros; el autor puede editar/borrar; admin puede todo
CREATE POLICY "transactions_read" ON transactions
  FOR SELECT USING (is_group_member(group_id));
CREATE POLICY "transactions_insert" ON transactions
  FOR INSERT WITH CHECK (is_group_member(group_id) AND user_id = auth.uid());
CREATE POLICY "transactions_update" ON transactions
  FOR UPDATE USING (user_id = auth.uid() OR is_group_admin(group_id));
CREATE POLICY "transactions_delete" ON transactions
  FOR DELETE USING (user_id = auth.uid() OR is_group_admin(group_id));

-- budgets, savings_goals, investments, virtual_envelopes: misma lógica de grupo
CREATE POLICY "budgets_read"   ON budgets FOR SELECT USING (is_group_member(group_id));
CREATE POLICY "budgets_write"  ON budgets FOR ALL    USING (is_group_admin(group_id));

CREATE POLICY "goals_read"     ON savings_goals FOR SELECT USING (is_group_member(group_id));
CREATE POLICY "goals_write"    ON savings_goals FOR ALL    USING (is_group_member(group_id));

CREATE POLICY "investments_read"  ON investments FOR SELECT USING (is_group_member(group_id));
CREATE POLICY "investments_write" ON investments FOR ALL    USING (is_group_member(group_id));

CREATE POLICY "envelopes_read"  ON virtual_envelopes FOR SELECT USING (is_group_member(group_id));
CREATE POLICY "envelopes_write" ON virtual_envelopes FOR ALL    USING (is_group_admin(group_id));

CREATE POLICY "insights_read"  ON ai_insights FOR SELECT USING (is_group_member(group_id));
-- insights solo los escribe la Edge Function (service_role), no el usuario
```

---

## 3. ESTRUCTURA DE CARPETAS — PROYECTO FLUTTER

```
budget_app/
├── android/
├── ios/
├── linux/
├── macos/
├── windows/
├── assets/
│   ├── fonts/
│   │   └── Inter/            # Inter Variable — legibilidad financiera
│   ├── icons/
│   │   └── categories/       # SVGs para iconos de categorías
│   └── images/
│       └── onboarding/
├── lib/
│   ├── main.dart
│   ├── app.dart              # MaterialApp + GoRouter + ProviderScope
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart       # Paleta completa + tokens semánticos
│   │   │   ├── app_typography.dart   # Estilos de texto con Inter
│   │   │   ├── app_spacing.dart      # Sistema de espaciado 4px base
│   │   │   └── app_icons.dart        # Map de iconos por categoría
│   │   ├── errors/
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   ├── network/
│   │   │   └── connectivity_service.dart
│   │   ├── services/
│   │   │   ├── supabase_service.dart
│   │   │   ├── exchange_rate_service.dart
│   │   │   ├── notification_service.dart
│   │   │   └── sync_queue_service.dart   # Cola offline-first
│   │   └── utils/
│   │       ├── currency_formatter.dart   # Formatea VES con separadores venezolanos
│   │       ├── date_utils.dart
│   │       └── validators.dart
│   │
│   ├── data/
│   │   ├── local/                        # Capa Drift (SQLite)
│   │   │   ├── app_database.dart         # DriftDatabase principal
│   │   │   ├── tables/
│   │   │   │   ├── transactions_table.dart
│   │   │   │   ├── categories_table.dart
│   │   │   │   ├── budgets_table.dart
│   │   │   │   ├── savings_goals_table.dart
│   │   │   │   ├── exchange_rates_table.dart
│   │   │   │   └── sync_queue_table.dart  # Cola de operaciones pendientes de sync
│   │   │   ├── daos/
│   │   │   │   ├── transactions_dao.dart
│   │   │   │   ├── categories_dao.dart
│   │   │   │   ├── budgets_dao.dart
│   │   │   │   └── sync_queue_dao.dart
│   │   │   └── migrations/
│   │   │       └── migration_1_to_2.dart
│   │   ├── remote/
│   │   │   ├── supabase/
│   │   │   │   ├── auth_datasource.dart
│   │   │   │   ├── transactions_datasource.dart
│   │   │   │   ├── categories_datasource.dart
│   │   │   │   ├── budgets_datasource.dart
│   │   │   │   ├── family_datasource.dart
│   │   │   │   └── insights_datasource.dart
│   │   │   └── api/
│   │   │       ├── exchange_rate_api.dart   # ExchangeRate-API + DolarToday
│   │   │       └── news_api.dart            # NewsAPI.org
│   │   └── repositories/
│   │       ├── auth_repository.dart
│   │       ├── transactions_repository.dart  # Orquesta local + remoto + sync
│   │       ├── categories_repository.dart
│   │       ├── budgets_repository.dart
│   │       ├── family_repository.dart
│   │       ├── exchange_rate_repository.dart
│   │       └── insights_repository.dart
│   │
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── transaction.dart       # @freezed
│   │   │   ├── category.dart
│   │   │   ├── budget.dart
│   │   │   ├── savings_goal.dart
│   │   │   ├── family_group.dart
│   │   │   ├── exchange_rate.dart
│   │   │   └── ai_insight.dart
│   │   └── usecases/
│   │       ├── auth/
│   │       │   ├── sign_in_usecase.dart
│   │       │   └── sign_out_usecase.dart
│   │       ├── transactions/
│   │       │   ├── add_transaction_usecase.dart
│   │       │   ├── get_monthly_summary_usecase.dart
│   │       │   └── check_budget_alert_usecase.dart
│   │       └── insights/
│   │           └── get_latest_insight_usecase.dart
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── presentation/
│   │   │   │   ├── pages/
│   │   │   │   │   ├── login_page.dart
│   │   │   │   │   └── register_page.dart
│   │   │   │   └── widgets/
│   │   │   │       └── social_login_button.dart
│   │   │   └── providers/
│   │   │       └── auth_provider.dart
│   │   ├── dashboard/
│   │   │   ├── presentation/
│   │   │   │   ├── pages/
│   │   │   │   │   └── dashboard_page.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── balance_card.dart
│   │   │   │       ├── mini_pie_chart.dart
│   │   │   │       ├── recent_transactions_list.dart
│   │   │   │       └── goals_progress_row.dart
│   │   │   └── providers/
│   │   │       └── dashboard_provider.dart
│   │   ├── transactions/
│   │   ├── budgets/
│   │   ├── savings/
│   │   ├── investments/
│   │   ├── insights/
│   │   ├── family/
│   │   └── settings/
│   │
│   └── shared/
│       ├── widgets/
│       │   ├── charts/
│       │   │   ├── budget_pie_chart.dart
│       │   │   └── income_expense_bar_chart.dart
│       │   ├── cards/
│       │   │   ├── transaction_card.dart
│       │   │   ├── budget_category_card.dart
│       │   │   └── goal_progress_card.dart
│       │   ├── forms/
│       │   │   └── transaction_form.dart
│       │   └── layout/
│       │       ├── responsive_layout.dart  # Mobile vs Desktop
│       │       └── adaptive_scaffold.dart  # BottomNavBar vs SideNavBar
│       └── providers/
│           ├── theme_provider.dart
│           └── locale_provider.dart
│
├── test/
│   ├── unit/
│   │   ├── repositories/
│   │   └── usecases/
│   └── widget/
│       └── dashboard/
└── pubspec.yaml
```

### 3.1 pubspec.yaml

```yaml
name: budget_familiar
description: Gestión de gastos y presupuesto familiar multiplataforma
version: 1.0.0+1

environment:
  sdk: ">=3.3.0 <4.0.0"
  flutter: ">=3.22.0"

dependencies:
  flutter:
    sdk: flutter

  # === ESTADO ===
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # === BASE DE DATOS LOCAL ===
  drift: ^2.18.0
  drift_flutter: ^0.2.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.3
  path: ^1.9.0

  # === SUPABASE ===
  supabase_flutter: ^2.5.0

  # === NAVEGACIÓN ===
  go_router: ^14.1.4

  # === GRÁFICOS ===
  fl_chart: ^0.68.0

  # === RED Y CONECTIVIDAD ===
  dio: ^5.4.3
  connectivity_plus: ^6.0.3

  # === NOTIFICACIONES ===
  flutter_local_notifications: ^17.2.2
  firebase_messaging: ^15.1.0
  firebase_core: ^3.4.0

  # === UI COMPONENTES ===
  flutter_svg: ^2.0.10
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  gap: ^3.0.1               # Espaciado semántico en filas/columnas
  percent_indicator: ^4.2.3 # Barras de progreso de metas

  # === INTERNACIONALIZACIÓN ===
  intl: ^0.19.0
  flutter_localizations:
    sdk: flutter

  # === UTILIDADES ===
  uuid: ^4.4.2
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  equatable: ^2.0.5
  dartz: ^0.10.1             # Either para manejo de errores funcional
  logger: ^2.4.0

  # === ALMACENAMIENTO SEGURO ===
  flutter_secure_storage: ^9.2.2
  shared_preferences: ^2.3.2

  # === AUTENTICACIÓN SOCIAL ===
  google_sign_in: ^6.2.1
  sign_in_with_apple: ^6.1.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.11
  drift_dev: ^2.18.0
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  custom_lint: ^0.6.4
  riverpod_lint: ^2.3.10
  mocktail: ^1.0.4
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/fonts/Inter/
    - assets/icons/categories/
    - assets/images/onboarding/
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter/Inter-Regular.ttf
          weight: 400
        - asset: assets/fonts/Inter/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter/Inter-Bold.ttf
          weight: 700
```

---

## 4. CONTRATOS DE APIS EXTERNAS

### 4.1 Tasas de Cambio — DolarToday (Tasa Paralela VES)

```
Endpoint (no oficial, estable desde 2015):
GET https://s3.amazonaws.com/dolartoday/data.json

Respuesta relevante:
{
  "USD": {
    "transfer": 42.50,     // tasa de transferencia
    "efectivo": 42.10,
    "promedio": 42.30,
    "promedio_real": 42.35
  },
  "EUR": { ... },
  "datetime": {
    "date": "2026-05-25",
    "time": "09:00:00"
  }
}

Campo a usar: USD.promedio_real como 'parallel' rate para VES/USD.
Frecuencia de actualización: cada 6 horas via Edge Function cron.
Fallback: si el endpoint falla, usar el último rate registrado en exchange_rates.
```

### 4.2 Tasas de Cambio — ExchangeRate-API (Monedas Internacionales)

```
Endpoint:
GET https://v6.exchangerate-api.com/v6/{API_KEY}/latest/USD

Headers: ninguno adicional
Plan gratuito: 1,500 requests/mes (suficiente para cron diario)

Respuesta:
{
  "base_code": "USD",
  "conversion_rates": {
    "VES": 36.80,  // tasa oficial BCV
    "EUR": 0.92,
    "COP": 4100.00,
    "BRL": 5.25,
    ...
  }
}

Nota: el rate de VES aquí es el oficial BCV.
Guardar ambos: BCV (oficial) y DolarToday (paralelo) para que el usuario elija cuál usar.
```

### 4.3 Noticias Financieras — NewsAPI.org

```
Endpoint 1 — Titulares por país:
GET https://newsapi.org/v2/top-headlines
  ?country=ve
  &category=business
  &pageSize=10
  &apiKey={API_KEY}

Endpoint 2 — Búsqueda contextual (más relevante para AI):
GET https://newsapi.org/v2/everything
  ?q=economía+Venezuela+dólar+inflación
  &language=es
  &sortBy=publishedAt
  &pageSize=5
  &from={fecha_hace_7_dias}
  &apiKey={API_KEY}

Plan gratuito: 100 requests/día (suficiente para beta).
Plan Developer ($449/mes): necesario al comercializar si escala.
Alternativa gratuita: GDELT Project (https://api.gdeltproject.org/api/v2/doc/doc)
  — cobertura masiva pero menor calidad editorial que NewsAPI.

Estructura del artículo que se pasa al contexto de AI:
{
  "title": "BCV ajusta tasa oficial en 3.2%",
  "source": "El Nacional",
  "publishedAt": "2026-05-24T14:00:00Z",
  "url": "https://...",
  "description": "Primer párrafo del artículo..."
}
```

### 4.4 Claude API — Generación de Insights

```
Endpoint:
POST https://api.anthropic.com/v1/messages

Headers:
  x-api-key: {ANTHROPIC_API_KEY}
  anthropic-version: 2023-06-01
  content-type: application/json

Body:
{
  "model": "claude-sonnet-4-5",
  "max_tokens": 1024,
  "messages": [
    {
      "role": "user",
      "content": "{PROMPT_CONSTRUIDO_POR_EDGE_FUNCTION}"
    }
  ]
}

Costo estimado (claude-sonnet-4-5):
  Input:  $3.00 / 1M tokens
  Output: $15.00 / 1M tokens
  Prompt típico: ~2,000 tokens entrada + ~600 salida = $0.015 por insight
  1,000 familias × 1 insight/semana = $60 USD/mes en AI

Respuesta esperada — formato JSON estructurado:
{
  "recommendations": [
    {
      "type": "spending_alert",
      "priority": "high",
      "category": "Alimentación",
      "title": "Gasto elevado en alimentación",
      "message": "Este mes gastaste 28% más en alimentación respecto a tu promedio de los últimos 3 meses.",
      "action": "Reducir Bs.D 85 en esta categoría cubriría el 40% de tu meta 'Vacaciones Dic'.",
      "related_goal_id": "uuid-o-null",
      "supporting_data": { "current_month": 450, "3month_avg": 351, "delta_pct": 28 }
    }
  ],
  "macro_context_summary": "El BCV ajustó la tasa oficial esta semana. Considerar conversión de ahorros en VES a USD para proteger el valor.",
  "overall_health_score": 72
}
```

### 4.5 Plantilla de Prompt para AI Insights

```
Eres un asesor financiero personal especializado en economías latinoamericanas,
particularmente Venezuela. Analiza los datos financieros de esta familia y
genera recomendaciones concretas, empáticas y accionables en español neutro.

CONTEXTO MACROECONÓMICO ({{country}}, {{date}}):
- Tasa de cambio oficial (BCV): 1 USD = {{bcv_rate}} VES
- Tasa paralela (referencia): 1 USD = {{parallel_rate}} VES
- Inflación mensual últimos 3 meses: {{inflation_monthly}}%
- Noticias relevantes:
  {{#each news_articles}}
  - [{{source}}] {{title}}: {{description}}
  {{/each}}

ESTADO FINANCIERO DEL GRUPO FAMILIAR:
- Nombre del grupo: {{group_name}}
- Mes en análisis: {{month_name}} {{year}}
- Ingreso total del mes: {{total_income}} {{primary_currency}}
  (equivalente a {{total_income_usd}} USD)
- Gasto total del mes: {{total_expense}} {{primary_currency}}
  (equivalente a {{total_expense_usd}} USD)
- Balance: {{balance}} {{primary_currency}}
- Ratio ahorro/ingreso: {{savings_rate}}%

DESGLOSE POR CATEGORÍA (mes actual vs. promedio 3 meses):
{{#each categories}}
- {{name}}: {{current}} vs {{avg_3m}} {{currency}} ({{delta_pct}}% {{trend}})
  Presupuesto asignado: {{budget}} — Consumido: {{budget_used_pct}}%
{{/each}}

METAS DE AHORRO ACTIVAS:
{{#each goals}}
- "{{name}}": {{current_amount}}/{{target_amount}} {{currency}} ({{progress_pct}}%)
  Fecha objetivo: {{deadline}} — Ritmo necesario: {{monthly_needed}}/mes
{{/each}}

INVERSIONES REGISTRADAS:
{{#each investments}}
- {{name}} ({{type}}): {{initial_amount}} → {{current_value}} {{currency}}
{{/each}}

Genera un análisis conciso con máximo 4 recomendaciones priorizadas.
Devuelve SOLO JSON válido con la estructura indicada, sin texto adicional.
Ten en cuenta la realidad económica venezolana: la inflación y la
dolarización informal son factores centrales en las recomendaciones.
```

---

## 5. MATRIZ DE FEATURE GATING

| Feature | Beta | Free | Family | Premium |
|---|:---:|:---:|:---:|:---:|
| Usuarios por grupo | 10 | 2 | 5 | 10 |
| Transacciones ilimitadas | ✅ | ✅ | ✅ | ✅ |
| Categorías personalizadas | 50 | 10 | 30 | 50 |
| Soporte VES/USD | ✅ | ✅ | ✅ | ✅ |
| Tasa paralela automática | ✅ | ✅ | ✅ | ✅ |
| Presupuestos mensuales | ✅ | ✅ | ✅ | ✅ |
| Alertas de presupuesto | ✅ | ✅ | ✅ | ✅ |
| Metas de ahorro | ✅ | ✅ | ✅ | ✅ |
| Inversiones | ✅ | ❌ | ✅ | ✅ |
| Sobres virtuales | ✅ | ❌ | ✅ | ✅ |
| Reportes y gráficos | ✅ | básico | ✅ | ✅ |
| Exportación PDF | ✅ | ❌ | ✅ | ✅ |
| App de escritorio | ✅ | ❌ | ✅ | ✅ |
| Modo offline-first | ✅ | ✅ | ✅ | ✅ |
| AI Insights semanales | ✅ | ❌ | ❌ | ✅ |
| Historial de insights | ✅ | ❌ | ❌ | ✅ |
| Contexto de noticias en AI | ✅ | ❌ | ❌ | ✅ |
| Precio mensual (USD) | $0 | $0 | $4.99 | $9.99 |

---

## 6. TOKENS DE DISEÑO — PALETA Y TIPOGRAFÍA

### 6.1 Paleta de Colores

```dart
// lib/core/constants/app_colors.dart

class AppColors {
  // === PRIMARIOS ===
  static const Color primary        = Color(0xFF1A56DB); // Azul confiable
  static const Color primaryLight   = Color(0xFFEBF5FF);
  static const Color primaryDark    = Color(0xFF1E429F);

  // === SEMÁNTICOS FINANCIEROS ===
  static const Color income         = Color(0xFF0E9F6E); // Verde claro — ingresos
  static const Color expense        = Color(0xFFF05252); // Rojo suave — gastos
  static const Color savings        = Color(0xFF8B5CF6); // Violeta — ahorro
  static const Color warning        = Color(0xFFFF8C00); // Naranja — alerta presupuesto
  static const Color neutral        = Color(0xFF6B7280); // Gris — neutral

  // === SEMÁFORO DE PRESUPUESTO ===
  static const Color budgetOk       = Color(0xFF0E9F6E); // < 50%
  static const Color budgetWarning  = Color(0xFFF59E0B); // 50–79%
  static const Color budgetAlert    = Color(0xFFEF4444); // 80–99%
  static const Color budgetOver     = Color(0xFF991B1B); // >= 100%

  // === FONDO Y SUPERFICIE ===
  static const Color background     = Color(0xFFF9FAFB);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color border         = Color(0xFFE5E7EB);

  // === TEXTO ===
  static const Color textPrimary    = Color(0xFF111827);
  static const Color textSecondary  = Color(0xFF6B7280);
  static const Color textDisabled   = Color(0xFF9CA3AF);

  // === MODO OSCURO (equivalentes) ===
  static const Color darkBackground = Color(0xFF111827);
  static const Color darkSurface    = Color(0xFF1F2937);
  static const Color darkBorder     = Color(0xFF374151);
}
```

### 6.2 Paleta para Gráficos (alta legibilidad, accesible para daltonismo)

```dart
// Colores de categorías en charts — ordenados por contraste mutuo
static const List<Color> chartPalette = [
  Color(0xFF1A56DB), // Azul
  Color(0xFF0E9F6E), // Verde
  Color(0xFFF05252), // Rojo
  Color(0xFFF59E0B), // Amarillo
  Color(0xFF8B5CF6), // Violeta
  Color(0xFF14B8A6), // Teal
  Color(0xFFF97316), // Naranja
  Color(0xFFEC4899), // Rosa
  Color(0xFF64748B), // Gris azulado
  Color(0xFF84CC16), // Verde lima
];
```

---

## 7. EDGE FUNCTIONS — ESTRUCTURA (Supabase / Deno)

### 7.1 Estructura de carpetas en Supabase

```
supabase/
├── functions/
│   ├── update-exchange-rates/
│   │   └── index.ts         # Cron: cada 6 horas
│   ├── generate-ai-insights/
│   │   └── index.ts         # Cron: lunes 9am / on-demand por familia
│   ├── check-budget-alerts/
│   │   └── index.ts         # Trigger: después de INSERT en transactions
│   ├── update-inflation/
│   │   └── index.ts         # Cron: mensual
│   └── _shared/
│       ├── supabase_client.ts
│       ├── exchange_rate_fetcher.ts
│       └── news_fetcher.ts
└── migrations/
    ├── 20260525000001_initial_schema.sql
    └── 20260525000002_seed_data.sql
```

### 7.2 Pseudocódigo — generate-ai-insights

```typescript
// supabase/functions/generate-ai-insights/index.ts

Deno.serve(async (req) => {
  const { group_id } = await req.json();

  // 1. Verificar si el plan del grupo tiene AI habilitado
  const plan = await getPlanForGroup(group_id);
  if (!plan.ai_insights_enabled) return new Response("Not allowed", { status: 403 });

  // 2. Verificar si hay un insight vigente (TTL de app_config)
  const ttlDays = await getConfig('insight_ttl_days'); // default: 7
  const existing = await getLatestInsight(group_id);
  if (existing && existing.expires_at > new Date()) {
    return new Response(JSON.stringify(existing), { status: 200 });
  }

  // 3. Reunir contexto financiero del grupo
  const financialSummary = await buildFinancialContext(group_id);

  // 4. Obtener o usar caché de noticias
  const countryCode = financialSummary.country_code;
  const news = await getOrFetchNews(countryCode);  // usa news_cache con TTL

  // 5. Obtener tasas e inflación actuales
  const rates = await getLatestRates('USD', 'VES');
  const inflation = await getLatestInflation(countryCode);

  // 6. Obtener plantilla de prompt activa
  const template = await getActivePromptTemplate('family_insights_v1');
  const prompt = renderTemplate(template, { ...financialSummary, news, rates, inflation });

  // 7. Llamar a Claude API
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': Deno.env.get('ANTHROPIC_API_KEY'),
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: 'claude-sonnet-4-5',
      max_tokens: 1024,
      messages: [{ role: 'user', content: prompt }]
    })
  });
  const aiResult = await response.json();
  const recommendations = JSON.parse(aiResult.content[0].text);

  // 8. Guardar en ai_insights
  const insight = await saveInsight({
    group_id,
    recommendations,
    news_sources: news,
    context_snapshot: financialSummary,
    model_used: 'claude-sonnet-4-5',
    tokens_used: aiResult.usage.input_tokens + aiResult.usage.output_tokens,
    expires_at: addDays(new Date(), ttlDays)
  });

  return new Response(JSON.stringify(insight), { status: 201 });
});
```

---

## 8. PLAN DE DESARROLLO — FASES DETALLADAS

### Fase 1 — MVP Beta (Semanas 1–12)
**Objetivo:** App funcional para uso familiar diario.

- [ ] Semana 1–2: Setup Supabase (schema + RLS + seed), proyecto Flutter con arquitectura base, configuración de Riverpod y Drift.
- [ ] Semana 3–4: Autenticación completa (email + Google + Apple ID). Creación de grupo familiar. Invitación por email.
- [ ] Semana 5–7: CRUD de transacciones. Categorías del sistema. Ingreso manual de tasa VES/USD. Balance mensual en pantalla principal.
- [ ] Semana 8–9: Dashboard básico (balance, últimas transacciones, distribución por categoría en texto/tabla). Navegación completa (mobile).
- [ ] Semana 10–11: Plan beta activo (todos los features habilitados). Notificaciones locales básicas.
- [ ] Semana 12: Testing familiar, ajustes de UX, fix de bugs críticos.

### Fase 2 — Producto Completo (Semanas 13–22)
- [ ] Gráficos con fl_chart (pie chart, barras, tendencia).
- [ ] Sistema de presupuestos con alertas (local + push).
- [ ] Automatización de tasas de cambio (Edge Function cron).
- [ ] Offline-first completo con Drift + cola de sync.
- [ ] Metas de ahorro con ajuste por inflación.
- [ ] Exportación PDF de resumen mensual.
- [ ] Versión escritorio (Windows/macOS responsive).

### Fase 3 — AI y Features Avanzados (Semanas 23–32)
- [ ] Pipeline completo de AI insights (Edge Function + NewsAPI + Claude API).
- [ ] Módulo de inversiones.
- [ ] Sobres virtuales.
- [ ] Historial de insights con contexto de noticias visible.
- [ ] Internacionalización (i18n) — estructura lista para inglés/portugués.

### Fase 4 — Comercialización (Semanas 33–38)
- [ ] Feature gating activo (free/family/premium).
- [ ] Integración Stripe para pagos internacionales.
- [ ] Flujo de pago manual Zelle/PayMóvil con verificación.
- [ ] Migración de beta testers con período de gracia de 30 días.
- [ ] Publicación en Google Play Store y Apple App Store.
- [ ] Landing page de marketing.

---

*Documento generado el 2026-05-25. Próxima actualización al iniciar Fase 1.*
