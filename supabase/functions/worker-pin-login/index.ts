import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import bcrypt from "npm:bcryptjs@2.4.3";

// Login por PIN para funcionários de produção (login_mode = 'pin').
// O funcionário não tem JWT ainda, então esta função NÃO usa verify_jwt — ela
// implementa a própria autenticação via PIN. O PIN valida contra profiles.pin_hash
// (bcrypt); a senha real do auth user é derivada do PIN (HMAC com pepper server-side)
// e serve só para emitir uma sessão Supabase real, que o cliente aplica via setSession.

const MAX_ATTEMPTS = 3;
const DEFAULT_DEV_ORIGINS = new Set([
  "http://localhost:3000",
  "http://localhost:8080",
  "http://localhost:5173",
  "http://127.0.0.1:3000",
  "http://127.0.0.1:8080",
  "http://127.0.0.1:5173",
]);
const configuredAllowedOrigins = (Deno.env.get("WORKER_PIN_ALLOWED_ORIGINS") ?? "")
  .split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);
const ALLOWED_ORIGINS = configuredAllowedOrigins.length > 0
  ? new Set(configuredAllowedOrigins)
  : DEFAULT_DEV_ORIGINS;

const MIN_PIN_LENGTH = Number(Deno.env.get("WORKER_PIN_MIN_LENGTH") ?? "4");
const MAX_PIN_LENGTH = Number(Deno.env.get("WORKER_PIN_MAX_LENGTH") ?? "6");
if (
  !Number.isInteger(MIN_PIN_LENGTH) || !Number.isInteger(MAX_PIN_LENGTH) ||
  MIN_PIN_LENGTH < 4 || MAX_PIN_LENGTH > 8 || MIN_PIN_LENGTH > MAX_PIN_LENGTH
) {
  throw new Error("Configuração de PIN inválida");
}
const PIN_REGEX = new RegExp(`^\\d{${MIN_PIN_LENGTH},${MAX_PIN_LENGTH}}$`);

const PEPPER = Deno.env.get("WORKER_PIN_SECRET");
if (!PEPPER) {
  throw new Error("WORKER_PIN_SECRET é obrigatório");
}

function corsHeadersFor(req: Request): HeadersInit {
  const origin = req.headers.get("origin");
  const isAllowed = origin ? ALLOWED_ORIGINS.has(origin) : false;
  return {
    "Access-Control-Allow-Origin": isAllowed && origin ? origin : "",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
  };
}

function json(body: unknown, status = 200, headers: HeadersInit = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...headers, "Content-Type": "application/json" },
  });
}

function delay(ms: number): Promise<void> {
  return new Promise((r) => setTimeout(r, ms));
}

const enc = new TextEncoder();

// Senha do auth user derivada de (worker_id, pin) com pepper server-side. Longa o
// suficiente para o mínimo do Supabase; nunca exposta ao cliente.
async function derivePassword(workerId: string, pin: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    enc.encode(PEPPER),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, enc.encode(`${workerId}:${pin}`));
  return "wpk_" + btoa(String.fromCharCode(...new Uint8Array(sig)));
}

Deno.serve(async (req: Request) => {
  const corsHeaders = corsHeadersFor(req);
  const respond = (body: unknown, status = 200) => json(body, status, corsHeaders);

  if (req.method === "OPTIONS") {
    const origin = req.headers.get("origin");
    if (origin && !ALLOWED_ORIGINS.has(origin)) {
      return respond({ error: "Origin não permitida" }, 403);
    }
    return new Response("ok", { headers: corsHeaders });
  }

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const admin = createClient(url, serviceKey, { auth: { persistSession: false } });

  try {
    const body = await req.json();
    const action = body.action as string;

    // --- list: lista pública mínima dos funcionários de PIN (tela "Quem é você?") ---
    if (action === "list") {
      const { data, error } = await admin
        .from("profiles")
        .select("id, name")
        .eq("login_mode", "pin")
        .eq("active", true)
        .order("name", { ascending: true });
      if (error) return respond({ error: error.message }, 500);
      return respond({ workers: data ?? [] });
    }

    const workerId = body.worker_id as string | undefined;
    const pin = body.pin as string | undefined;

    // --- set: primeiro acesso self-service — só permitido enquanto não há PIN.
    // A guarda pin_set torna isto de uso único: depois de definido, set recusa
    // (already_set) e a troca passa a exigir sessão própria via 'change'.
    if (action === "set") {
      if (!workerId || !pin || !PIN_REGEX.test(pin)) {
        return respond({ error: `PIN deve ter entre ${MIN_PIN_LENGTH} e ${MAX_PIN_LENGTH} dígitos` }, 400);
      }
      const profile = await loadPinWorker(admin, workerId);
      if (!profile) return respond({ error: "Funcionário não encontrado" }, 404);
      if (profile.blocked) return respond({ error: "Acesso bloqueado", code: "blocked" }, 403);
      if (profile.pin_set) {
        return respond({ error: "PIN já definido", code: "already_set" }, 409);
      }
      const hash = await bcrypt.hash(pin, 10);
      const password = await derivePassword(workerId, pin);
      const { error: updErr } = await admin.auth.admin.updateUserById(workerId, {
        password,
      });
      if (updErr) return respond({ error: updErr.message }, 500);
      await admin
        .from("profiles")
        .update({ pin_hash: hash, pin_set: true, failed_attempts: 0, blocked: false })
        .eq("id", workerId);
      return await mintSession(url, anonKey, profile.email, password, corsHeaders);
    }

    // --- verify: logins seguintes ---
    if (action === "verify") {
      if (!workerId || !pin || !PIN_REGEX.test(pin)) {
        return respond({ error: "PIN inválido", code: "wrong_pin" }, 400);
      }
      const profile = await loadPinWorker(admin, workerId);
      if (!profile) return respond({ error: "Funcionário não encontrado" }, 404);
      if (profile.blocked) return respond({ error: "Acesso bloqueado", code: "blocked" }, 403);
      if (!profile.pin_set || !profile.pin_hash) {
        return respond({ error: "PIN não definido", code: "not_set" }, 409);
      }

      const ok = await bcrypt.compare(pin, profile.pin_hash);
      if (!ok) {
        const { data: updated, error: updErr } = await admin
          .from("profiles")
          .update({ failed_attempts: profile.failed_attempts + 1 })
          .eq("id", workerId)
          .select("failed_attempts")
          .single();
        if (updErr || !updated) return respond({ error: "Falha ao verificar PIN" }, 500);
        const attempts = updated.failed_attempts as number;
        const willBlock = attempts >= MAX_ATTEMPTS;
        if (willBlock) {
          await admin.from("profiles").update({ blocked: true }).eq("id", workerId);
        }
        await delay(attempts >= 3 ? 5000 : attempts === 2 ? 2000 : 1000);
        if (willBlock) return respond({ error: "Acesso bloqueado", code: "blocked" }, 403);
        return respond({
          error: "PIN incorreto",
          code: "wrong_pin",
          remaining: MAX_ATTEMPTS - attempts,
        }, 401);
      }

      await admin
        .from("profiles")
        .update({ failed_attempts: 0 })
        .eq("id", workerId);
      const password = await derivePassword(workerId, pin);
      return await mintSession(url, anonKey, profile.email, password, corsHeaders);
    }

    // --- change: troca de PIN (exige sessão do próprio funcionário) ---
    if (action === "change") {
      const authHeader = req.headers.get("Authorization") ?? "";
      const token = authHeader.replace("Bearer ", "");
      if (!token) return respond({ error: "Não autenticado" }, 401);
      const { data: { user }, error: authErr } = await admin.auth.getUser(token);
      if (authErr || !user) return respond({ error: "Sessão inválida" }, 401);

      const currentPin = body.current_pin as string | undefined;
      const newPin = body.new_pin as string | undefined;
      if (!currentPin || !newPin || !PIN_REGEX.test(newPin)) {
        return respond({ error: `Novo PIN deve ter entre ${MIN_PIN_LENGTH} e ${MAX_PIN_LENGTH} dígitos` }, 400);
      }
      if (currentPin === newPin) {
        return respond({ error: "O novo PIN deve ser diferente do atual" }, 400);
      }
      const profile = await loadPinWorker(admin, user.id);
      if (!profile || !profile.pin_hash) {
        return respond({ error: "Funcionário não encontrado" }, 404);
      }
      const ok = await bcrypt.compare(currentPin, profile.pin_hash);
      if (!ok) return respond({ error: "PIN atual incorreto", code: "wrong_pin" }, 401);

      const hash = await bcrypt.hash(newPin, 10);
      const password = await derivePassword(user.id, newPin);
      const { error: updErr } = await admin.auth.admin.updateUserById(user.id, {
        password,
      });
      if (updErr) return respond({ error: updErr.message }, 500);
      await admin.from("profiles").update({ pin_hash: hash }).eq("id", user.id);
      return respond({ ok: true });
    }

    return respond({ error: "Ação desconhecida" }, 400);
  } catch (e) {
    console.error("worker-pin-login error:", e);
    return respond({ error: "Erro interno do servidor" }, 500);
  }
});

type PinWorker = {
  id: string;
  email: string;
  pin_hash: string | null;
  pin_set: boolean;
  blocked: boolean;
  failed_attempts: number;
  login_mode: string;
  active: boolean;
};

async function loadPinWorker(
  admin: ReturnType<typeof createClient>,
  id: string,
): Promise<PinWorker | null> {
  const { data } = await admin
    .from("profiles")
    .select("id, email, pin_hash, pin_set, blocked, failed_attempts, login_mode, active")
    .eq("id", id)
    .eq("login_mode", "pin")
    .eq("active", true)
    .maybeSingle();
  return (data as PinWorker | null) ?? null;
}

async function mintSession(
  url: string,
  anonKey: string,
  email: string,
  password: string,
  headers: HeadersInit,
): Promise<Response> {
  const client = createClient(url, anonKey, { auth: { persistSession: false } });
  const { data, error } = await client.auth.signInWithPassword({ email, password });
  if (error || !data.session) {
    return json({ error: "Falha ao iniciar sessão" }, 500, headers);
  }
  return json({
    session: {
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
      expires_in: data.session.expires_in,
      expires_at: data.session.expires_at,
    },
  }, 200, headers);
}
