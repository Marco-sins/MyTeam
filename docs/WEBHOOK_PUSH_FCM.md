# Notificaciones con la app cerrada (obligatorio: webhook + FCM)

Con la aplicación **cerrada o forzada a parar**, el código Flutter **no se ejecuta**: Supabase **Realtime** no recibe el `INSERT` en `match_events`, así que `MatchEventAppNotificationCoordinator` **no puede** mostrar nada.  
Para que **siempre** haya un aviso en el teléfono, hace falta un envío **FCM** desde el **servidor** cada vez que haya un evento de partido.

Este repo incluye la Edge Function **`push-match-event`** en `supabase/functions/push-match-event/`, que:

1. Recibe el **webhook** de base de datos al insertar en `public.match_events`.
2. Resuelve el partido, el equipo, los **miembros** (`team_members`) y sus **tokens** (`fcm_tokens`).
3. Envía a la **API HTTP v1 de FCM** un mensaje con `notification` (título y texto) y prioridad **HIGH** y canal `fcm_default_channel` (el mismo que declara la app en Android).

Sin desplegar esta función, configurar secretos y el **Database Webhook**, **no** habrá notificaciones con la app matada, aunque el permiso del sistema esté concedido.

---

## Requisitos previos

- Proyecto **Firebase** con la app Android `com.marco.myteam` y **API FCM (v1)** habilitada en Google Cloud.
- Cuenta de servicio (JSON) con permiso de envío a FCM: en Firebase, **Cuenta de servicio** → generar clave privada, o en Google Cloud **IAM** → clave de cuenta de servicio.
- **Supabase** con tablas: `match_events`, `matches`, `teams`, `team_members`, `fcm_tokens`, `players` (usadas por la función).
- [Supabase CLI](https://supabase.com/docs/guides/cli) y proyecto enlazado: `supabase link`.

---

## 1. Secretos en Supabase

```bash
# Clave de cuenta de servicio (JSON completo en una sola variable)
supabase secrets set FCM_SERVICE_ACCOUNT_JSON @ruta/descargada-firebase.json

# Secreto compartido: misma cadena luego en el webhook (cabecera)
openssl rand -hex 32
supabase secrets set PUSH_WEBHOOK_SECRET "pega_un_string_largo_aleatorio"
```

No subas el JSON a Git. El contenido es el de **Firebase** / **Google Cloud** (mismo `project_id` que en la consola, p. ej. `myteam-1f0c8`).

---

## 2. Desplegar la función

**Importante:** los webhooks de la base de datos **no** envían el JWT de un usuario, así que hay que publicar la función **sin** verificar JWT:

```bash
supabase functions deploy push-match-event --no-verify-jwt
```

(Alternativa: en el panel del proyecto, desactiva “Enforce JWT” / verificación estricta para esta función, según la versión del panel.)

---

## 3. Webhook de base de datos

> **¿No te sale “Webhooks” en el panel?** En muchos proyectos está en **Integrations → Webhooks** o en la URL  
> `https://supabase.com/dashboard/project/TU_REF/integrations/webhooks/overview`.  
> Si aun así no aparece, usa el **mismo disparo** con SQL y `pg_net`: **[WEBHOOK_SIN_PANEL_SQL.md](./WEBHOOK_SIN_PANEL_SQL.md)**.

En el panel (si lo tienes): **Database → Webhooks** o **Integrations → Webhooks** → *Create a new hook*.

- **Table:** `public.match_events`
- **Events:** al menos `INSERT` (o solo INSERT).
- **Type of webhook:** Supabase / HTTP según ofrezca el panel; la URL ha de ser:

`https://<PROJECT_REF>.supabase.co/functions/v1/push-match-event`

- **HTTP Headers:** añade:

`X-Webhook-Secret: <mismo valor que PUSH_WEBHOOK_SECRET>`

Guarda y, si hace falta, prueba insertando un `match_events` de prueba (desde el SQL Editor o la app con la sesión que corresponda).

---

## 4. Comprobar

1. Usuario con sesión en el móvil, permisos de notificaciones aceptados.
2. Fila en `fcm_tokens` con el `user_id` correcto.
3. Usuario en `team_members` del equipo del partido.
4. Cerrar la app por completo, generar un evento: debe aparecer la notificación del sistema.
5. Si no llega, revisa **Edge Functions → Logs** en Supabase y la respuesta de FCM (token inválido, proyecto incorrecto, API deshabilitada, etc.).

---

## Con la app en primer plano

Puede haber **dos** avisos (Realtime local + FCM) si ambos se disparan. Si molesta, se puede afinar luego (p. ej. ignorar FCM mientras haya Realtime, o un `collapse_key`); no bloquea el caso “app cerrada”.

---

## iOS

La función incluye un bloque básico `apns`. Para iOS hace falta app iOS en Firebase, `GoogleService-Info.plist` y `flutterfire configure`; hasta entonces, el cliente iOS no registrará FCM de forma fiable.
