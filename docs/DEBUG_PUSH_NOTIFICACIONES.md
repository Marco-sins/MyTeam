# Depurar por qué no llegan las notificaciones (app cerrada)

Hazlo en **este orden**. Casi siempre el fallo está en **servidor** (función, secretos, trigger, datos) **antes** que en el código Flutter.

---

## 1) ¿La Edge Function está viva y ve los secretos?

En el navegador (sustituye `TU_REF`):

`https://TU_REF.supabase.co/functions/v1/push-match-event`

Debería devolver JSON parecido a:

```json
{ "name": "push-match-event", "ok": true, "hasPUSH_WEBHOOK_SECRET": true, "hasFCM_SERVICE_ACCOUNT_JSON": true }
```

- Si **`ok: false`**: los secretos no están en el proyecto o el nombre no coincide (`PUSH_WEBHOOK_SECRET` / `FCM_SERVICE_ACCOUNT_JSON`).
- Si **404**: la función no está desplegada:  
  `npx supabase functions deploy push-match-event --no-verify-jwt`

---

## 2) Respuesta de `pg_net` (¿llega la petición a la función?)

En **SQL Editor** (no uses `SELECT *`: el editor de Supabase a veces muestra *“restricted wildcard (*)”*; enumera columnas):

```sql
select status_code, error_msg, left(content, 2000) as content, created
from net._http_response
order by created desc
limit 10;
```

- **`status_code` 401** en el cuerpo `unauthorized` → el `X-Webhook-Secret` del **SQL del trigger** no es **idéntico** al secreto `PUSH_WEBHOOK_SECRET` en el panel. Corrige el `v_secret` en el SQL, vuelve a ejecutar `create or replace function ...` y prueba otra inserción.
- **Sin filas nuevas** al insertar en `match_events` → el trigger no está o la URL es incorrecta. Comprueba:
  ```sql
  select tgname from pg_trigger where tgrelid = 'public.match_events'::regclass;
  ```
- Cuerpo con **`sent: 0, reason: "no fcm tokens"`** → no hay fila en `fcm_tokens` para los usuarios de `team_members` de ese partido. Abre la app, inicia sesión, comprueba `fcm_tokens`.
- Cuerpo con **`no team members`** → nadie en `team_members` para el `team_id` del partido.
- Cuerpo con error **OAuth2** o **FCM 403/404** → mira sección 3.

---

## 3) Cuenta de servicio, proyecto y API

- En **Google Cloud** (mismo proyecto que Firebase, `project_id` del JSON): habilita **Firebase Cloud Messaging API (V1)**.
- El **`project_id` dentro de `FCM_SERVICE_ACCOUNT_JSON`** debe ser el **mismo** proyecto Firebase en el que registraste la app Android (`com.marco.myteam`) y en el que generas tokens FCM. Si mezclas proyectos, el token del móvil no vale para el servidor.
- Vuelve a desplegar la función tras tocar el código:  
  `npx supabase functions deploy push-match-event --no-verify-jwt`

---

## 4) Móvil (solo si 2 y 3 están bien: la función devuelve `sent > 0`)

- Ajustes → Apps → **tu app** → Batería → **Sin restricciones** (según fabricante: Xiaomi, Samsung, etc.).
- **Google Play services** actualizado.
- Prueba de **Mensajería** de Firebase a un **token** (copiado de `fcm_tokens`) desde la consola: si tampoco llega, el problema es del dispositivo/red, no de tu app.

---

## 5) Logs de la Edge Function

**Edge Functions** → `push-match-event` → **Logs**. Cualquier error con mensaje (OAuth2, FCM) confirma el tramo roto (credenciales vs token vs FCM API).

---

Tras un redeploy con la versión actual del repositorio, los errores de OAuth2/FCM deberían verse en el **JSON** de `net._http_response.content` o en los logs, no fallar en silencio.
