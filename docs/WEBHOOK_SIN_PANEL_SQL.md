# Webhook sin menú en el panel (SQL + `pg_net`)

Si en Supabase **no** ves *Integrations → Webhooks* ni *Database → Hooks*, puedes disparar la Edge Function **desde la base de datos** con un **trigger** y **`net.http_post`** (extensión [pg_net](https://supabase.com/docs/guides/database/extensions/pg_net)).

Hazlo en el **SQL Editor** del panel (o en una migración), en este orden.

---

## 1. Activar `pg_net`

**Database → Extensions** → busca **pg_net** → activar.  
O en SQL:

```sql
create extension if not exists pg_net;
```

---

## 2. Sustituir en el script (antes de ejecutar)

- **`TU_PROJECT_REF`**: *Settings → General → Reference ID* (aparece en la URL del dashboard, p. ej. `abcdxyzfghij`).
- **`MISMO_SECRETO_QUE_PUSH_WEBHOOK_SECRET`**: el valor del secreto `PUSH_WEBHOOK_SECRET` (el que ya creaste en Supabase; tiene que ser **idéntico** a lo que pone la variable en la función, no hace falta “subirlo” otra vez a sitio raro, solo **coincidir** en el SQL).

---

## 3. SQL (pega y ajusta los dos valores de arriba)

```sql
-- Función: al insertar en match_events, llama a tu Edge Function con el mismo JSON que el webhook del panel
create or replace function public.match_events_push_fcm()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_url text;
  v_secret text;
  v_body jsonb;
begin
  v_url := 'https://TU_PROJECT_REF.supabase.co/functions/v1/push-match-event';
  v_secret := 'MISMO_SECRETO_QUE_PUSH_WEBHOOK_SECRET';

  v_body := jsonb_build_object(
    'type', 'INSERT',
    'table', 'match_events',
    'schema', 'public',
    'record', to_jsonb(NEW)
  );

  perform net.http_post(
    url := v_url,
    body := v_body,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'X-Webhook-Secret', v_secret
    ),
    timeout_milliseconds := 15000
  );

  return NEW;
end;
$$;

drop trigger if exists trg_match_events_push_fcm on public.match_events;

create trigger trg_match_events_push_fcm
  after insert on public.match_events
  for each row
  execute function public.match_events_push_fcm();
```

Ejecuta el bloque entero. Si la función ya existía, `create or replace` la actualiza.

---

## 4. Comprobar

- La Edge Function **debe** estar desplegada: `supabase functions deploy push-match-event --no-verify-jwt`
- Secreto `FCM_SERVICE_ACCOUNT_JSON` configurado
- Tras un `INSERT` en `match_events`, mira:
  - **Edge Functions → Logs** en Supabase
  - o `select * from net._http_response order by created desc limit 5;` (respuestas recientes de `pg_net`)

---

## 5. Quitar el trigger (si lo necesitas)

```sql
drop trigger if exists trg_match_events_push_fcm on public.match_events;
drop function if exists public.match_events_push_fcm();
```

**Seguridad:** no subas a Git un SQL con el secreto en claro. Guárdalo solo en notas privadas o vuelve a generar un `PUSH_WEBHOOK_SECRET` nuevo si alguien vio el valor.

---

## Dónde “debería” estar el Webhook en el panel (por si luego lo encuentras)

- Ruta de la [documentación](https://supabase.com/docs/guides/database/webhooks):  
  `https://supabase.com/dashboard/project/TU_REF/integrations/webhooks/overview`  
- Menú: **Integrations** → sección de **Webhooks** / **Overview**.

Si no existe en tu plan o región, el SQL de arriba es el sustituto oficial vía `pg_net`.
