// Madar — Twilio Verify SMS gateway (Supabase Edge Function)
// Secrets (set via `supabase secrets set`):
//   TWILIO_API_KEY
//   TWILIO_API_SECRET
//   TWILIO_VERIFY_SERVICE_SID   (optional — auto-created as "Madar Verify")
//   TWILIO_ACCOUNT_SID         (optional fallback auth with TWILIO_AUTH_TOKEN)
//   TWILIO_AUTH_TOKEN          (optional fallback)
//
// Actions: ensure_service | send | check | status

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

function twilioAuthHeader(): string | null {
  const apiKey = Deno.env.get("TWILIO_API_KEY");
  const apiSecret = Deno.env.get("TWILIO_API_SECRET");
  if (apiKey && apiSecret) {
    return "Basic " + btoa(`${apiKey}:${apiSecret}`);
  }
  const sid = Deno.env.get("TWILIO_ACCOUNT_SID");
  const token = Deno.env.get("TWILIO_AUTH_TOKEN");
  if (sid && token) {
    return "Basic " + btoa(`${sid}:${token}`);
  }
  return null;
}

async function twilioForm(
  url: string,
  params: Record<string, string>,
): Promise<{ ok: boolean; status: number; data: Record<string, unknown> }> {
  const auth = twilioAuthHeader();
  if (!auth) {
    return {
      ok: false,
      status: 500,
      data: { message: "twilio_credentials_missing" },
    };
  }
  const body = new URLSearchParams(params);
  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: auth,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body,
  });
  const data = await res.json().catch(() => ({}));
  return { ok: res.ok, status: res.status, data: data as Record<string, unknown> };
}

async function ensureServiceSid(): Promise<string | null> {
  const existing = Deno.env.get("TWILIO_VERIFY_SERVICE_SID");
  if (existing && existing.startsWith("VA")) return existing;

  const created = await twilioForm("https://verify.twilio.com/v2/Services", {
    FriendlyName: Deno.env.get("TWILIO_VERIFY_FRIENDLY_NAME") ?? "Madar Verify",
  });
  if (!created.ok) return null;
  const sid = created.data["sid"];
  return typeof sid === "string" ? sid : null;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }
  if (req.method !== "POST") {
    return json({ success: false, message: "method_not_allowed" }, 405);
  }

  let payload: Record<string, unknown> = {};
  try {
    payload = await req.json();
  } catch {
    return json({ success: false, message: "invalid_json" }, 400);
  }

  const action = String(payload["action"] ?? "");

  if (action === "status") {
    const auth = twilioAuthHeader();
    return json({
      success: true,
      configured: auth != null,
      has_service_sid: Boolean(Deno.env.get("TWILIO_VERIFY_SERVICE_SID")),
      auth_mode: Deno.env.get("TWILIO_API_KEY")
        ? "api_key"
        : Deno.env.get("TWILIO_ACCOUNT_SID")
        ? "account_sid"
        : "none",
    });
  }

  if (action === "ensure_service") {
    const sid = await ensureServiceSid();
    if (!sid) {
      return json({
        success: false,
        message: "unable_to_create_verify_service",
        hint:
          "Set TWILIO_API_KEY + TWILIO_API_SECRET (or ACCOUNT_SID + AUTH_TOKEN).",
      }, 502);
    }
    return json({
      success: true,
      service_sid: sid,
      note:
        "Persist this SID as TWILIO_VERIFY_SERVICE_SID in Supabase secrets.",
    });
  }

  if (action === "send") {
    const to = String(payload["to"] ?? "").trim();
    const channel = String(payload["channel"] ?? "sms");
    if (!to.startsWith("+")) {
      return json({
        success: false,
        message: "phone_must_be_e164",
        hint: "Use +9647XXXXXXXX format",
      }, 400);
    }
    const serviceSid = await ensureServiceSid();
    if (!serviceSid) {
      return json({ success: false, message: "verify_service_missing" }, 502);
    }
    const result = await twilioForm(
      `https://verify.twilio.com/v2/Services/${serviceSid}/Verifications`,
      { To: to, Channel: channel },
    );
    if (!result.ok) {
      return json({
        success: false,
        message: "twilio_send_failed",
        twilio: result.data,
      }, result.status);
    }
    return json({
      success: true,
      status: result.data["status"],
      sid: result.data["sid"],
      to: result.data["to"],
      channel: result.data["channel"],
      service_sid: serviceSid,
    });
  }

  if (action === "check") {
    const to = String(payload["to"] ?? "").trim();
    const code = String(payload["code"] ?? "").trim();
    if (!to.startsWith("+") || code.length < 4) {
      return json({ success: false, message: "invalid_check_params" }, 400);
    }
    const serviceSid = await ensureServiceSid();
    if (!serviceSid) {
      return json({ success: false, message: "verify_service_missing" }, 502);
    }
    const result = await twilioForm(
      `https://verify.twilio.com/v2/Services/${serviceSid}/VerificationCheck`,
      { To: to, Code: code },
    );
    if (!result.ok) {
      return json({
        success: false,
        message: "twilio_check_failed",
        twilio: result.data,
      }, result.status);
    }
    const approved = result.data["status"] === "approved";
    return json({
      success: approved,
      status: result.data["status"],
      sid: result.data["sid"],
      to: result.data["to"],
    });
  }

  return json({
    success: false,
    message: "unknown_action",
    allowed: ["status", "ensure_service", "send", "check"],
  }, 400);
});
