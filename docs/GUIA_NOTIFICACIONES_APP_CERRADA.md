# Guion: notificaciones con la app **cerrada** (push)

Objetivo: que el sistema muestre un aviso aunque matéis la app. Eso exige **FCM** (Google) + **un envío desde backend** (p. ej. **Supabase Edge Function** al insertar en `match_events`). Los datos siguen en **Supabase**; Firebase solo hace de “cartero” hacia el móvil.

**Tiempo aproximado:** 1–2 sesiones si ya tenéis el proyecto en Firebase/Supabase.

> **Imprescindible con la app cerrada:** el cliente Android ya puede recibir FCM, pero **hay que enviar** el push desde el servidor. En este repo está la Edge Function `supabase/functions/push-match-event/` y la guía paso a paso en **[WEBHOOK_PUSH_FCM.md](./WEBHOOK_PUSH_FCM.md)** (secretos, despliegue y **Database Webhook** en `match_events`). Sin eso, **no** verás notificaciones al matar la app: Realtime **no** corre sin proceso.

---

## Parte 1 — Firebase (solo para FCM)

1. Entra en [Firebase Console](https://console.firebase.google.com) y **crea un proyecto** (puede ser solo para mensajería).
2. **Añade la app Android** con el id `com.marco.myteam` (o el `applicationId` de `android/app/build.gradle.kts`).
3. **Descargá** `google-services.json` y ponedlo en **`android/app/google-services.json`**.
4. (Opcional iOS) Añadí la app iOS, descargad **`GoogleService-Info.plist`** en `ios/Runner/`, y en Apple Developer el certificado/keys que pida FCM.
5. En Firebase → **Project settings** → **Service accounts** → **Generate new private key** → guardad el **JSON** (lo usará el backend, **no** lo subáis a Git).
6. Comprobad en Google Cloud (mismo proyecto) que la **Firebase Cloud Messaging API (V1)** esté habilitada.

---

## Parte 2 — Flutter (proyecto ya preparado en parte)

1. En la raíz del repo:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Eso **sustituye** el placeholder de `lib/firebase_options.dart` (hoy `YOUR_FIREBASE_PROJECT_ID` hace que FCM no arranque).
2. **Android — plugin de Google Services**
   - En `android/settings.gradle.kts` añadid el plugin (versión 4.4.2 o la que use la [doc de FlutterFire](https://firebase.flutter.dev)):
     `id("com.google.gms.google-services") version "4.4.2" apply false`
   - En `android/app/build.gradle.kts` descomentad o añadid:
     `id("com.google.gms.google-services")`
3. Asegurad que en `main` sigue el arranque de FCM:  
   `await PushNotificationService.instance.initializePluginBinding();` (ya lo tenéis).
4. **Login:** el token se registra con la sesión (ya conectado en `football_app` al pasar a `Authenticated`). La tabla de Supabase debe existir (parte 3) para que el `upsert` no falle.
5. Compilad y comprobad en logs que **no** salga el aviso de “configura `firebase_options`”.

---

## Parte 3 — Supabase: tabla de tokens

En el **SQL Editor** del panel de Supabase, ejecutad algo como:

```sql
create table if not exists public.fcm_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  token text not null,
  platform text not null default 'android',
  updated_at timestamptz not null default now(),
  unique (user_id, token)
);

alter table public.fcm_tokens enable row level security;

create policy "fcm_tokens own rows"
  on public.fcm_tokens for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
```

(Equivalente a lo que hace vuestro `upsert` con `onConflict: user_id,token`.)

- Activad **Realtime** solo si lo necesitáis; el push **no** depende de Realtime.
- Asegurad que con el usuario de la app podéis **insert/upsert** en `fcm_tokens` (política anterior).

---

## Parte 4 — “Quién envía” el push (backend)

Hace falta un proceso en **servidor** que, cuando haya un evento (p. ej. **nuevo `match_events`**), llame a la **API HTTP v1 de FCM** con el JSON de cuenta de servicio.

**Opción recomendada:** **Supabase Edge Function** (Deno):

1. Instalad Supabase CLI y enlazad el proyecto: `supabase link`.
2. Cread una función, por ejemplo `push-match-event`, que:
   - Reciba el evento (webhook de **Database** → “Insert” en `match_events`, o lógica que prefiráis).
   - Con **service role** o consultas controladas, resolváis `team_id` del partido, usuarios del equipo, tokens en `fcm_tokens`, y enviéis un POST a FCM v1 (payload `notification` con `title` y `body` para que el sistema muestre bandeja).
3. Secretos de la función (en el panel o `supabase secrets set`):
   - El **JSON** de la cuenta de servicio de Firebase (a veces en una sola variable `FCM_SERVICE_ACCOUNT_JSON`).
   - Si usáis webhook, un **secreto compartido** en cabecera para que no abra a cualquiera la URL.
4. En **Database** → **Webhooks** (o **Integrations**), disparad un POST a la URL de la función al **INSERT** en `match_events` (misma idea que comentábamos en sesiones anteriores).

**Documentación de referencia:** [FCM v1 con OAuth2](https://firebase.google.com/docs/cloud-messaging/send-message), [Edge Functions Supabase](https://supabase.com/docs/guides/functions).

---

## Parte 5 — Probar

1. Instalad la app en un **dispositivo real** (en emulador FCM a veces falla o es distinto).
2. Iniciad sesión y verificad en Supabase que hay **filas** en `fcm_tokens`.
3. Desde otra llave o desde SQL, insertad un `match_events` de prueba (o haced una acción en la app) y comprobad en logs de la Edge Function que el envío a FCM devuelve **200**.
4. **Cerrad la app por completo** (quitar de recientes) y repetid: si el insert/webhook y FCM están bien, debe aparecer la notificación.

---

## Resumen de archivos clave en este repo

| Qué | Dónde |
|-----|--------|
| Config FCM al arranque + token en Supabase | `lib/core/push/push_notification_service.dart` |
| Fondo / handler mínimo | `lib/core/push/firebase_messaging_background.dart` |
| Opciones (tras `flutterfire configure`) | `lib/firebase_options.dart` |
| Registro de token al loguear | `lib/app/football_app.dart` (listener de `AuthCubit`) |
| Android: `google-services.json` | `android/app/` + plugin comentado en `build.gradle.kts` |

---

## Si algo falla

- **No se crea fila en `fcm_tokens`:** Firebase no está bien enlazado (`firebase_options` sigue con placeholder) o faltan permisos/RLS.
- **Hay token pero no aviso con la app cerrada:** falla la **Edge Function**, el **webhook**, o el JSON/permisos de FCM; revisad logs de la función y respuestas de la API.
- **Solo iOS no suena / no llega:** APNs + capacidades de la app en Xcode y en Firebase; **no** es lo mismo que solo Android con `google-services.json`.

**Recordatorio:** las notificaciones **locales** (Realtime) que ya tenéis con la app abierta no sustituyen al push: son dos caminos distintos.
