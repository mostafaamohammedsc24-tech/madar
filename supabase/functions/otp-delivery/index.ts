// Madar — OTP delivery (WhatsApp Cloud API primary, Twilio SMS fallback)
//
// Secrets (supabase secrets set):
//   WHATSAPP_ACCESS_TOKEN
//   WHATSAPP_PHONE_NUMBER_ID
//   WHATSAPP_BUSINESS_ACCOUNT_ID   (optional, docs/ops only)
//   WHATSAPP_OTP_TEMPLATE
//   WHATSAPP_OTP_LANGUAGE          (e.g. en_US, ar)
//   WHATSAPP_GRAPH_API_VERSION     (default v26.0)
//   TWILIO_ACCOUNT_SID / TWILIO_AUTH_TOKEN  OR  TWILIO_API_KEY / TWILIO_API_SECRET
//   TWILIO_SMS_FROM                OR  TWILIO_MESSAGING_SERVICE_SID
//   SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY (auto in Edge Functions)
//
// Actions: status | send | verify | deliver (Auth Hook / raw OTP) | prefer_channel
//
// Does NOT use Twilio WhatsApp. Meta Graph API only for WhatsApp.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type DeliveryChannel = "whatsapp" | "sms";

type ProviderResult = {
  ok: boolean;
  channel: DeliveryChannel;
  retryable: boolean;
  errorCode?: string;
  detail?: string;
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

function graphVersion(): string {
  const v = Deno.env.get("WHATSAPP_GRAPH_API_VERSION")?.trim();
  if (v && /^v\d+\.\d+$/.test(v)) return v;
  // Latest Graph API version documented by Meta for WhatsApp Business (2026).
  return "v26.0";
}

function normalizeE164(raw: string): string | null {
  const trimmed = raw.trim();
  if (trimmed.startsWith("+") && /^\+[1-9]\d{7,14}$/.test(trimmed)) {
    return trimmed;
  }
  const digits = trimmed.replace(/\D/g, "");
  if (digits.length >= 8 && digits.length <= 15) {
    return `+${digits}`;
  }
  return null;
}

function generateOtp(): string {
  const n = crypto.getRandomValues(new Uint32Array(1))[0]! % 1_000_000;
  return n.toString().padStart(6, "0");
}

function adminClient() {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) return null;
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
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

function whatsappConfigured(): boolean {
  return Boolean(
    Deno.env.get("WHATSAPP_ACCESS_TOKEN") &&
      Deno.env.get("WHATSAPP_PHONE_NUMBER_ID") &&
      Deno.env.get("WHATSAPP_OTP_TEMPLATE"),
  );
}

function smsConfigured(): boolean {
  const auth = twilioAuthHeader();
  const from = Deno.env.get("TWILIO_SMS_FROM");
  const messagingSid = Deno.env.get("TWILIO_MESSAGING_SERVICE_SID");
  const accountSid = Deno.env.get("TWILIO_ACCOUNT_SID") ||
    Deno.env.get("TWILIO_API_KEY");
  return Boolean(auth && accountSid && (from || messagingSid));
}

/** Send OTP via Meta WhatsApp Cloud API authentication template. */
async function sendWhatsAppOtp(
  phoneE164: string,
  otp: string,
): Promise<ProviderResult> {
  const token = Deno.env.get("WHATSAPP_ACCESS_TOKEN");
  const phoneNumberId = Deno.env.get("WHATSAPP_PHONE_NUMBER_ID");
  const template = Deno.env.get("WHATSAPP_OTP_TEMPLATE");
  const language = Deno.env.get("WHATSAPP_OTP_LANGUAGE") || "en_US";

  if (!token || !phoneNumberId || !template) {
    return {
      ok: false,
      channel: "whatsapp",
      retryable: true,
      errorCode: "whatsapp_not_configured",
    };
  }

  const url =
    `https://graph.facebook.com/${graphVersion()}/${phoneNumberId}/messages`;

  const body = {
    messaging_product: "whatsapp",
    to: phoneE164.replace(/^\+/, ""),
    type: "template",
    template: {
      name: template,
      language: { code: language },
      components: [
        {
          type: "body",
          parameters: [{ type: "text", text: otp }],
        },
        {
          type: "button",
          sub_type: "url",
          index: "0",
          parameters: [{ type: "text", text: otp }],
        },
      ],
    },
  };

  try {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });
    const data = await res.json().catch(() => ({})) as Record<string, unknown>;
    if (res.ok) {
      return { ok: true, channel: "whatsapp", retryable: false };
    }

    const err = data["error"] as Record<string, unknown> | undefined;
    const code = err?.["code"] != null ? String(err["code"]) : String(res.status);
    const sub = err?.["error_subcode"] != null
      ? String(err["error_subcode"])
      : undefined;
    // Permanent / non-retryable: invalid recipient, template issues, auth config
    const permanentCodes = new Set([
      "100",
      "131026", // Message undeliverable
      "131047", // Re-engagement
      "131051", // Unsupported message type
      "132000", // Template param mismatch
      "132001", // Template does not exist
      "132005", // Template hydrated
      "132007", // Template format
      "132012", // Template param format
      "132015", // Template paused
      "132016", // Template disabled
      "190", // Access token
    ]);
    const retryable = !permanentCodes.has(code) &&
      res.status >= 500;
    console.error("[otp-delivery] WhatsApp send failed", {
      status: res.status,
      code,
      sub,
      // never log token or otp
    });
    return {
      ok: false,
      channel: "whatsapp",
      retryable: retryable || code === "4" || code === "80007" ||
        res.status === 429 || res.status >= 500,
      errorCode: `whatsapp_${code}`,
      detail: typeof err?.["message"] === "string"
        ? err["message"] as string
        : undefined,
    };
  } catch (e) {
    console.error("[otp-delivery] WhatsApp network error", String(e));
    return {
      ok: false,
      channel: "whatsapp",
      retryable: true,
      errorCode: "whatsapp_network",
    };
  }
}

/** Twilio Programmable Messaging SMS — delivers the SAME OTP (not Verify). */
async function sendTwilioSmsOtp(
  phoneE164: string,
  otp: string,
): Promise<ProviderResult> {
  const auth = twilioAuthHeader();
  const accountSid = Deno.env.get("TWILIO_ACCOUNT_SID");
  if (!auth || !accountSid) {
    return {
      ok: false,
      channel: "sms",
      retryable: false,
      errorCode: "twilio_sms_not_configured",
    };
  }

  const from = Deno.env.get("TWILIO_SMS_FROM");
  const messagingSid = Deno.env.get("TWILIO_MESSAGING_SERVICE_SID");
  if (!from && !messagingSid) {
    return {
      ok: false,
      channel: "sms",
      retryable: false,
      errorCode: "twilio_sms_from_missing",
    };
  }

  const params = new URLSearchParams();
  params.set("To", phoneE164);
  params.set(
    "Body",
    `Madar verification code: ${otp}. Do not share this code.`,
  );
  if (messagingSid) {
    params.set("MessagingServiceSid", messagingSid);
  } else if (from) {
    params.set("From", from);
  }

  try {
    const res = await fetch(
      `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`,
      {
        method: "POST",
        headers: {
          Authorization: auth,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: params,
      },
    );
    const data = await res.json().catch(() => ({})) as Record<string, unknown>;
    if (res.ok) {
      return { ok: true, channel: "sms", retryable: false };
    }
    console.error("[otp-delivery] Twilio SMS failed", {
      status: res.status,
      code: data["code"],
    });
    const code = data["code"] != null ? String(data["code"]) : String(res.status);
    const retryable = res.status >= 500 || res.status === 429;
    return {
      ok: false,
      channel: "sms",
      retryable,
      errorCode: `twilio_${code}`,
    };
  } catch (e) {
    console.error("[otp-delivery] Twilio SMS network error", String(e));
    return {
      ok: false,
      channel: "sms",
      retryable: true,
      errorCode: "twilio_network",
    };
  }
}

/**
 * Deliver OTP once: WhatsApp first (unless SMS forced), then Twilio SMS
 * only when WhatsApp failure is retryable/config-related — never dual-send.
 */
async function deliverOtp(
  phoneE164: string,
  otp: string,
  prefer: "auto" | DeliveryChannel,
): Promise<ProviderResult> {
  if (prefer === "sms") {
    return await sendTwilioSmsOtp(phoneE164, otp);
  }

  if (prefer === "whatsapp" || prefer === "auto") {
    const wa = await sendWhatsAppOtp(phoneE164, otp);
    if (wa.ok) return wa;

    if (prefer === "whatsapp") return wa;

    // Fallback only for transient / config / network failures — not invalid numbers.
    if (wa.retryable || wa.errorCode === "whatsapp_not_configured") {
      const sms = await sendTwilioSmsOtp(phoneE164, otp);
      return sms;
    }
    return wa;
  }

  return {
    ok: false,
    channel: "whatsapp",
    retryable: false,
    errorCode: "invalid_prefer",
  };
}

async function logDelivery(
  admin: ReturnType<typeof createClient>,
  phone: string,
  result: ProviderResult,
) {
  try {
    await admin.from("otp_delivery_logs").insert({
      phone_e164: phone,
      channel: result.channel,
      success: result.ok,
      error_code: result.errorCode ?? null,
    });
  } catch (e) {
    console.error("[otp-delivery] log insert failed", String(e));
  }
}

async function issueAndDeliver(
  phoneE164: string,
  prefer: "auto" | DeliveryChannel,
) {
  const admin = adminClient();
  if (!admin) {
    return json({
      success: false,
      message: "service_unavailable",
    }, 503);
  }

  const otp = generateOtp();
  // Probe preferred channel for storage label (actual channel after deliver).
  const delivery = await deliverOtp(phoneE164, otp, prefer);
  await logDelivery(admin, phoneE164, delivery);

  if (!delivery.ok) {
    return json({
      success: false,
      message: "delivery_failed",
      channel: delivery.channel,
      // user-safe code only
      error: "unable_to_send_code",
    }, 502);
  }

  const { error } = await admin.rpc("phone_otp_issue", {
    p_phone: phoneE164,
    p_otp: otp,
    p_channel: delivery.channel,
    p_ttl_seconds: 600,
  });

  if (error) {
    console.error("[otp-delivery] phone_otp_issue failed", error.message);
    return json({ success: false, message: "store_failed" }, 500);
  }

  return json({
    success: true,
    channel: delivery.channel,
    expires_in_seconds: 600,
  });
}

async function verifyManaged(phoneE164: string, code: string) {
  const admin = adminClient();
  if (!admin) {
    return json({ success: false, message: "service_unavailable" }, 503);
  }

  const { data, error } = await admin.rpc("phone_otp_verify", {
    p_phone: phoneE164,
    p_otp: code,
  });

  if (error) {
    console.error("[otp-delivery] verify rpc failed", error.message);
    return json({ success: false, message: "verify_failed" }, 500);
  }

  const row = Array.isArray(data) ? data[0] : data;
  const ok = row?.ok === true;
  const reason = String(row?.reason ?? "invalid");

  if (!ok) {
    const userMessage = reason === "expired"
      ? "expired"
      : reason === "locked"
      ? "too_many_attempts"
      : "invalid";
    return json({ success: false, message: userMessage }, 400);
  }

  // Create or load Auth user, then issue a magic-link hashed token for setSession.
  const syntheticEmail =
    `phone.${phoneE164.replace(/\D/g, "")}@otp.madar.local`;

  let userId: string | null = null;

  const created = await admin.auth.admin.createUser({
    phone: phoneE164,
    phone_confirm: true,
    email: syntheticEmail,
    email_confirm: true,
    user_metadata: { phone_e164: phoneE164, auth_via: "managed_otp" },
  });

  if (created.data.user?.id) {
    userId = created.data.user.id;
  } else {
    // User may already exist — try generateLink which resolves by email.
    const updated = await admin.auth.admin.listUsers({ page: 1, perPage: 1000 });
    const match = updated.data.users.find((u) =>
      u.phone === phoneE164 || u.email === syntheticEmail
    );
    userId = match?.id ?? null;
    if (userId) {
      await admin.auth.admin.updateUserById(userId, {
        phone: phoneE164,
        phone_confirm: true,
        email: syntheticEmail,
        email_confirm: true,
      });
    }
  }

  if (!userId) {
    console.error("[otp-delivery] unable to resolve auth user");
    return json({ success: false, message: "session_failed" }, 500);
  }

  const link = await admin.auth.admin.generateLink({
    type: "magiclink",
    email: syntheticEmail,
  });

  const hashed = link.data.properties?.hashed_token;
  if (!hashed) {
    console.error("[otp-delivery] generateLink missing hashed_token");
    return json({ success: false, message: "session_failed" }, 500);
  }

  return json({
    success: true,
    user_id: userId,
    hashed_token: hashed,
    email: syntheticEmail,
  });
}

/** Supabase Auth Send SMS Hook / raw deliver of an already-generated OTP. */
async function deliverExistingOtp(payload: Record<string, unknown>) {
  // Hook shapes vary; support both custom and SMS hook-ish payloads.
  const sms = payload["sms"] as Record<string, unknown> | undefined;
  const phoneRaw = String(
    payload["phone"] ??
      payload["to"] ??
      sms?.["phone"] ??
      (payload["user"] as Record<string, unknown> | undefined)?.["phone"] ??
      "",
  );
  const otp = String(
    payload["otp"] ??
      payload["code"] ??
      sms?.["otp"] ??
      "",
  );
  const preferRaw = String(payload["prefer"] ?? payload["channel"] ?? "auto");
  const prefer = (preferRaw === "sms" || preferRaw === "whatsapp")
    ? preferRaw
    : "auto";

  const phone = normalizeE164(phoneRaw);
  if (!phone || !/^\d{4,8}$/.test(otp)) {
    return json({ success: false, message: "invalid_params" }, 400);
  }

  const delivery = await deliverOtp(phone, otp, prefer);
  const admin = adminClient();
  if (admin) await logDelivery(admin, phone, delivery);

  if (!delivery.ok) {
    // Auth hooks expect non-2xx on hard failure so Supabase can surface errors.
    return json({
      success: false,
      message: "delivery_failed",
      error: "unable_to_send_code",
    }, 502);
  }

  return json({ success: true, channel: delivery.channel });
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

  // Supabase Auth Hook may POST without action — treat as deliver.
  const action = String(payload["action"] ?? "deliver");

  if (action === "status") {
    return json({
      success: true,
      whatsapp_configured: whatsappConfigured(),
      sms_fallback_configured: smsConfigured(),
      graph_api_version: graphVersion(),
      twilio_verify_still_available: true,
      primary_channel: "whatsapp",
      fallback_channel: "sms",
    });
  }

  if (action === "prefer_channel") {
    const phone = normalizeE164(String(payload["phone"] ?? ""));
    const channel = String(payload["channel"] ?? "");
    if (!phone || (channel !== "sms" && channel !== "whatsapp")) {
      return json({ success: false, message: "invalid_params" }, 400);
    }
    const admin = adminClient();
    if (!admin) {
      return json({ success: false, message: "service_unavailable" }, 503);
    }
    const { error } = await admin.from("otp_channel_preferences").upsert({
      phone_e164: phone,
      preferred_channel: channel,
      expires_at: new Date(Date.now() + 15 * 60 * 1000).toISOString(),
      updated_at: new Date().toISOString(),
    });
    if (error) {
      return json({ success: false, message: "prefer_failed" }, 500);
    }
    return json({ success: true, channel });
  }

  if (action === "send") {
    const phone = normalizeE164(String(payload["phone"] ?? payload["to"] ?? ""));
    if (!phone) {
      return json({ success: false, message: "phone_must_be_e164" }, 400);
    }
    let prefer: "auto" | DeliveryChannel = "auto";
    const channel = String(payload["channel"] ?? "auto");
    if (channel === "sms" || channel === "whatsapp") prefer = channel;

    // Honor short-lived preference row when channel=auto
    if (prefer === "auto") {
      const admin = adminClient();
      if (admin) {
        const { data } = await admin
          .from("otp_channel_preferences")
          .select("preferred_channel, expires_at")
          .eq("phone_e164", phone)
          .maybeSingle();
        if (
          data &&
          new Date(String(data.expires_at)).getTime() > Date.now() &&
          (data.preferred_channel === "sms" ||
            data.preferred_channel === "whatsapp")
        ) {
          prefer = data.preferred_channel;
        }
      }
    }

    return await issueAndDeliver(phone, prefer);
  }

  if (action === "verify") {
    const phone = normalizeE164(String(payload["phone"] ?? payload["to"] ?? ""));
    const code = String(payload["code"] ?? payload["otp"] ?? "").trim();
    if (!phone || code.length < 4) {
      return json({ success: false, message: "invalid_check_params" }, 400);
    }
    return await verifyManaged(phone, code);
  }

  if (action === "deliver" || action === "auth_hook") {
    return await deliverExistingOtp(payload);
  }

  return json({
    success: false,
    message: "unknown_action",
    allowed: [
      "status",
      "send",
      "verify",
      "deliver",
      "auth_hook",
      "prefer_channel",
    ],
  }, 400);
});
