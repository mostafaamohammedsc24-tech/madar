# Twilio Verify — Madar SMS OTP

## Secrets (Supabase Edge Function — never commit real values)

```bash
supabase secrets set \
  TWILIO_API_KEY=SKxxxxxxxx \
  TWILIO_API_SECRET=xxxxxxxx \
  TWILIO_VERIFY_FRIENDLY_NAME="Madar Verify"
```

Optional once you have a Service SID:

```bash
supabase secrets set TWILIO_VERIFY_SERVICE_SID=VAxxxxxxxx
```

Fallback auth (instead of API key):

```bash
supabase secrets set TWILIO_ACCOUNT_SID=ACxxxxxxxx TWILIO_AUTH_TOKEN=xxxxxxxx
```

## Create Verify service (Twilio docs)

```bash
curl -X POST "https://verify.twilio.com/v2/Services" \
  --data-urlencode "FriendlyName=Madar Verify" \
  -u $TWILIO_API_KEY:$TWILIO_API_SECRET
```

Or from the app (System Admin → **Create / ensure Madar Verify service**), which calls the same API via the edge function.

## Deploy function

```bash
supabase functions deploy twilio-verify
```

## App usage

- `TwilioVerifyService` → `functions.invoke('twilio-verify')`
- Employee Profile → Verify phone
- Bank buyer OTP → Send/Check via Twilio when gateway is configured
- System Admin can toggle `system_config.twilio.verify.enabled`
