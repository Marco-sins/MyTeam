// Edge Function: insert en `match_events` → FCM a miembros del equipo.
// Secretos: FCM_SERVICE_ACCOUNT_JSON, PUSH_WEBHOOK_SECRET
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { importPKCS8, SignJWT } from "npm:jose@5.2.0";

const FCM_CHANNEL = "fcm_default_channel";

type ServiceAccount = {
  type: string;
  project_id: string;
  private_key: string;
  client_email: string;
};

type WebhookBody = {
  type?: string;
  table?: string;
  record?: Record<string, unknown>;
  [key: string]: unknown;
};

function normalizeTypeKey(raw: unknown): string {
  if (raw == null) return "";
  let k = String(raw).split(".").pop() ?? "";
  k = k.toLowerCase().trim();
  k = k.replaceAll("_", "").replaceAll(" ", "").replaceAll("-", "");
  for (const [a, b] of [
    ["á", "a"],
    ["é", "e"],
    ["í", "i"],
    ["ó", "o"],
    ["ú", "u"],
    ["ñ", "n"],
  ] as const) {
    k = k.split(a).join(b);
  }
  const aliases: Record<string, string> = {
    buenpase: "goodpass",
    malpase: "badpass",
    tiro: "shot",
    tirorival: "rivalshot",
  };
  return aliases[k] ?? k;
}

function buildTitleBody(
  rec: Record<string, unknown>,
  teamName: string,
  opponent: string,
  playerName: string | null,
): { title: string; body: string } {
  const t = normalizeTypeKey(rec["type"]);
  const note = String(rec["note"] ?? "").trim();
  const min = rec["minute"] != null ? String(rec["minute"]) : "";
  const who = playerName && playerName.length > 0 ? playerName : "Jugador";
  const title = `${teamName} · En vivo`;
  const vs = `vs ${opponent}`;

  if (t === "statuschange") {
    const n = note.toLowerCase();
    if (n.includes("descanso")) {
      return { title, body: `Descanso · ${min ? min + "′ · " : ""}${vs}` };
    }
    if (n.includes("final") && n.includes("partido")) {
      return { title, body: `Fin del partido · ${vs}` };
    }
    if (n.includes("inicio") && n.includes("1")) {
      return { title, body: `1ª parte · ${vs}` };
    }
    if (n.includes("2") && n.includes("mitad")) {
      return { title, body: `2ª parte · ${vs}` };
    }
    return { title, body: `Actualización: ${note || "Estado"}` };
  }
  if (t === "scoregoal" || t === "penalty") {
    return { title, body: `⚽ Gol · ${who} · ${min ? min + "′" : ""} · ${vs}`.trim() };
  }
  if (t === "owngoal") {
    return { title, body: `⚽ Gol en propia · ${who} · ${min ? min + "′" : ""} · ${vs}`.trim() };
  }
  if (t === "concedegoal") {
    return { title, body: `⚽ Gol de ${opponent} · ${min ? min + "′" : ""} · ${vs}`.trim() };
  }
  if (t === "yellowcard") {
    return { title, body: `🟨 Amonestación · ${who} · ${min ? min + "′" : ""}`.trim() };
  }
  if (t === "redcard") {
    return { title, body: `🟥 Expulsión · ${who} · ${min ? min + "′" : ""}`.trim() };
  }
  if (t === "rivalyellowcard") {
    return { title, body: `🟨 Amonestación rival · ${min ? min + "′" : ""} · ${vs}`.trim() };
  }
  if (t === "rivalredcard") {
    return { title, body: `🟥 Expulsión rival · ${min ? min + "′" : ""} · ${vs}`.trim() };
  }
  if (t === "substitution") {
    return { title, body: `🔄 Cambio · ${min ? min + "′" : ""} · ${vs}`.trim() };
  }
  if (t === "formation") {
    return { title, body: `📋 Alineación actualizada · ${vs}`.trim() };
  }
  return {
    title,
    body: `Evento en el partido · ${min ? min + "′ · " : ""}${vs}`.trim(),
  };
}

/**
 * Token OAuth2 para FCM (sin `google-auth-library`, más estable en Deno/Edge).
 */
async function getAccessTokenFromServiceAccount(sa: ServiceAccount): Promise<string> {
  const pk = sa.private_key.replace(/\\n/g, "\n");
  const privateKey = await importPKCS8(pk, "RS256");
  const jwt = await new SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt()
    .setExpirationTime("55m")
    .sign(privateKey);

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const text = await res.text();
  if (!res.ok) {
    throw new Error(`OAuth2 ${res.status}: ${text.substring(0, 800)}`);
  }
  const data = JSON.parse(text) as { access_token?: string; error?: string };
  if (!data.access_token) {
    throw new Error(`OAuth2 sin access_token: ${text.substring(0, 500)}`);
  }
  return data.access_token;
}

async function sendFcm(
  projectId: string,
  accessToken: string,
  fcmToken: string,
  title: string,
  body: string,
): Promise<void> {
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: {
        token: fcmToken,
        notification: { title, body },
        data: { source: "edge_match_event" },
        android: {
          priority: "HIGH",
          notification: {
            channel_id: FCM_CHANNEL,
            default_sound: true,
            default_vibrate_timings: true,
          },
        },
        apns: {
          headers: { "apns-priority": "10" },
          payload: { aps: { sound: "default" } },
        },
      },
    }),
  });
  if (!res.ok) {
    const t = await res.text();
    throw new Error(`FCM ${res.status}: ${t.substring(0, 1000)}`);
  }
}

function json(
  data: unknown,
  status: number,
): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  try {
    if (req.method === "OPTIONS") {
      return new Response("ok", { headers: { "Access-Control-Allow-Origin": "*" } });
    }

    if (req.method === "GET") {
      const hasSecret = Boolean(Deno.env.get("PUSH_WEBHOOK_SECRET")?.length);
      const hasFcm = Boolean(Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")?.length);
      return json(
        {
          name: "push-match-event",
          ok: hasSecret && hasFcm,
          hasPUSH_WEBHOOK_SECRET: hasSecret,
          hasFCM_SERVICE_ACCOUNT_JSON: hasFcm,
        },
        200,
      );
    }

    const secret = Deno.env.get("PUSH_WEBHOOK_SECRET");
    if (!secret || secret.length < 8) {
      return json({ error: "PUSH_WEBHOOK_SECRET not configured" }, 500);
    }
    const hdr = req.headers.get("X-Webhook-Secret");
    if (hdr !== secret) {
      return json({ error: "unauthorized" }, 401);
    }

    const raw = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
    if (!raw) {
      return json({ error: "FCM_SERVICE_ACCOUNT_JSON not set" }, 500);
    }
    let sa: ServiceAccount;
    try {
      sa = JSON.parse(raw) as ServiceAccount;
    } catch (e) {
      return json({ error: "FCM_SERVICE_ACCOUNT_JSON no es JSON válido", detail: String(e) }, 500);
    }
    if (!sa.project_id || !sa.private_key || !sa.client_email) {
      return json({ error: "FCM JSON incompleto (project_id, private_key, client_email)" }, 500);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceKey) {
      return json({ error: "Supabase env missing" }, 500);
    }

    let payload: WebhookBody;
    try {
      payload = (await req.json()) as WebhookBody;
    } catch {
      return json({ error: "invalid json" }, 400);
    }

    if (payload.table && payload.table !== "match_events") {
      return json({ skipped: "wrong table" }, 200);
    }
    if (payload.type && !["INSERT", "insert"].includes(String(payload.type))) {
      return json({ skipped: "not insert" }, 200);
    }

    const record = payload.record;
    if (!record || typeof record !== "object") {
      return json({ error: "no record" }, 400);
    }

    const rec = record as Record<string, unknown>;
    const matchId = typeof rec["match_id"] === "number"
      ? rec["match_id"] as number
      : parseInt(String(rec["match_id"] ?? ""), 10);
    if (!Number.isFinite(matchId)) {
      return json({ error: "bad match_id" }, 400);
    }

    const supa = createClient(supabaseUrl, serviceKey);

    const { data: match, error: eM } = await supa
      .from("matches")
      .select("id, team_id, opponent")
      .eq("id", matchId)
      .maybeSingle();
    if (eM) {
      return json({ error: eM.message }, 500);
    }
    if (!match) {
      return json({ error: "match not found" }, 404);
    }
    const teamId = match.team_id as number;
    const opponent = String(match.opponent ?? "Rival");

    const { data: team, error: eT } = await supa
      .from("teams")
      .select("id, name")
      .eq("id", teamId)
      .maybeSingle();
    if (eT) {
      return json({ error: eT.message }, 500);
    }
    const teamName = String(team?.name ?? "Equipo");

    const pid1 = rec["player_id1"];
    let playerName: string | null = null;
    if (pid1 != null) {
      const pId = typeof pid1 === "number" ? pid1 : parseInt(String(pid1), 10);
      if (Number.isFinite(pId)) {
        const { data: p } = await supa
          .from("players")
          .select("firstname, lastname")
          .eq("id", pId)
          .eq("team_id", teamId)
          .maybeSingle();
        if (p) {
          const row = p as Record<string, string | undefined>;
          const a = (row.firstname ?? "").trim();
          const b = (row.lastname ?? "").trim();
          const full = [a, b].filter((x) => x.length).join(" ");
          if (full.length) playerName = full;
        }
      }
    }

    const { title, body: msgBody } = buildTitleBody(rec, teamName, opponent, playerName);

    const { data: members, error: eMem } = await supa
      .from("team_members")
      .select("id_user")
      .eq("id_team", teamId);
    if (eMem) {
      return json({ error: eMem.message }, 500);
    }
    const userIds = (members ?? [])
      .map((m) => (m as { id_user: string }).id_user)
      .filter((u) => u && u.length > 0);

    if (userIds.length === 0) {
      return json({ sent: 0, reason: "no team members" }, 200);
    }

    const { data: tokenRows, error: eTok } = await supa
      .from("fcm_tokens")
      .select("token, user_id")
      .in("user_id", userIds);
    if (eTok) {
      return json({ error: eTok.message }, 500);
    }

    const seen = new Set<string>();
    const tokens: string[] = [];
    for (const r of tokenRows ?? []) {
      const row = r as { token: string; user_id: string };
      if (!row.token || seen.has(row.token)) continue;
      seen.add(row.token);
      tokens.push(row.token);
    }

    if (tokens.length === 0) {
      return json(
        { sent: 0, reason: "no fcm tokens", userIds: userIds.length },
        200,
      );
    }

    const accessToken = await getAccessTokenFromServiceAccount(sa);
    const projectId = sa.project_id;

    const results: { ok: boolean; err?: string }[] = [];
    for (const tok of tokens) {
      try {
        await sendFcm(projectId, accessToken, tok, title, msgBody);
        results.push({ ok: true });
      } catch (e) {
        results.push({ ok: false, err: e instanceof Error ? e.message : String(e) });
      }
    }

    return json(
      {
        sent: results.filter((r) => r.ok).length,
        failed: results.filter((r) => !r.ok).length,
        projectId,
        errors: results
          .filter((r) => !r.ok)
          .map((r) => r.err)
          .slice(0, 3),
      },
      200,
    );
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error("push-match-event", msg);
    return json({ error: "internal", message: msg.substring(0, 2000) }, 500);
  }
});
