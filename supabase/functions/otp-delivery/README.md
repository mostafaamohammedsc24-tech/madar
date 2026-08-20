# otp-delivery

WhatsApp Cloud API (Meta Graph) is the **primary** OTP channel.
Twilio **Programmable Messaging SMS** is the **fallback** only.

`twilio-verify` remains intact for bank buyer OTP and employee phone verify.

## Secrets

```bash
supabase secrets set \
  WHATSAPP_ACCESS_TOKEN=... \
  WHATSAPP_PHONE_NUMBER_ID=... \
  WHATSAPP_OTP_TEMPLATE=... \
  WHATSAPP_OTP_LANGUAGE=en_US \
  WHATSAPP_GRAPH_API_VERSION=v26.0 \
  TWILIO_ACCOUNT_SID=... \
  TWILIO_AUTH_TOKEN=... \
  TWILIO_SMS_FROM=+1... 
# or TWILIO_MESSAGING_SERVICE_SID=MG...
```

Optional: `WHATSAPP_BUSINESS_ACCOUNT_ID` (ops only).

## Actions

| action | purpose |
|--------|---------|
| `status` | Config probe |
| `send` | Generate + hash + deliver OTP (managed login) |
| `verify` | Verify OTP + return `hashed_token` for session |
| `deliver` / `auth_hook` | Deliver an OTP already generated (e.g. Supabase Auth Hook) |
| `prefer_channel` | Force next send to `sms` or `whatsapp` |

## Fallback rules

- WhatsApp success → stop (no SMS).
- WhatsApp not configured / network / 5xx / rate limit → Twilio SMS once.
- Permanent WhatsApp recipient/template errors → no SMS dual-send.

## Deploy

```bash
supabase functions deploy otp-delivery
supabase db push   # applies 012_phone_otp_delivery.sql
```
