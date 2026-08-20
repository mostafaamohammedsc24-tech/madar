-- Madar phone OTP delivery (WhatsApp primary, Twilio SMS fallback)
-- OTP codes are stored hashed (bcrypt via pgcrypto). Never store plaintext.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.phone_otps (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_e164 text NOT NULL,
  otp_hash text NOT NULL,
  delivery_channel text NOT NULL DEFAULT 'whatsapp',
  attempts int NOT NULL DEFAULT 0,
  max_attempts int NOT NULL DEFAULT 5,
  expires_at timestamptz NOT NULL,
  consumed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS phone_otps_phone_active_idx
  ON public.phone_otps (phone_e164, created_at DESC)
  WHERE consumed_at IS NULL;

CREATE TABLE IF NOT EXISTS public.otp_delivery_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_e164 text NOT NULL,
  channel text NOT NULL,
  success boolean NOT NULL,
  error_code text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.otp_channel_preferences (
  phone_e164 text PRIMARY KEY,
  preferred_channel text NOT NULL CHECK (preferred_channel IN ('whatsapp', 'sms')),
  expires_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.phone_otp_issue(
  p_phone text,
  p_otp text,
  p_channel text,
  p_ttl_seconds int DEFAULT 600
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  UPDATE public.phone_otps
  SET consumed_at = now()
  WHERE phone_e164 = p_phone
    AND consumed_at IS NULL;

  INSERT INTO public.phone_otps (phone_e164, otp_hash, delivery_channel, expires_at)
  VALUES (
    p_phone,
    crypt(p_otp, gen_salt('bf')),
    p_channel,
    now() + make_interval(secs => p_ttl_seconds)
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.phone_otp_verify(
  p_phone text,
  p_otp text
)
RETURNS TABLE (
  ok boolean,
  reason text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.phone_otps%ROWTYPE;
BEGIN
  SELECT * INTO v_row
  FROM public.phone_otps
  WHERE phone_e164 = p_phone
    AND consumed_at IS NULL
  ORDER BY created_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'not_found';
    RETURN;
  END IF;

  IF v_row.expires_at < now() THEN
    UPDATE public.phone_otps SET consumed_at = now() WHERE id = v_row.id;
    RETURN QUERY SELECT false, 'expired';
    RETURN;
  END IF;

  IF v_row.attempts >= v_row.max_attempts THEN
    RETURN QUERY SELECT false, 'locked';
    RETURN;
  END IF;

  UPDATE public.phone_otps
  SET attempts = attempts + 1
  WHERE id = v_row.id;

  IF v_row.otp_hash = crypt(p_otp, v_row.otp_hash) THEN
    UPDATE public.phone_otps SET consumed_at = now() WHERE id = v_row.id;
    RETURN QUERY SELECT true, 'ok';
    RETURN;
  END IF;

  RETURN QUERY SELECT false, 'invalid';
END;
$$;

REVOKE ALL ON FUNCTION public.phone_otp_issue(text, text, text, int) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.phone_otp_verify(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.phone_otp_issue(text, text, text, int) TO service_role;
GRANT EXECUTE ON FUNCTION public.phone_otp_verify(text, text) TO service_role;

ALTER TABLE public.phone_otps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.otp_delivery_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.otp_channel_preferences ENABLE ROW LEVEL SECURITY;
