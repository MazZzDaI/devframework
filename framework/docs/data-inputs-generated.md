# Required data and secrets (self-host devframework)

## Data and templates
- Discovery answers — `docs/discovery/interview.md`.
- Data templates (if domain tables are needed) — `docs/data-templates.md`.
- Additionally: The agent itself determines the full volume and format of the required data and asks as the need arises; the user expects to be told what to provide in order to start.

## Secrets and access
- Policy: Development proceeds without credentials until they are actually needed. When they are needed, the agent makes a stop point and asks for them. Secrets go in an env file; access is provided for deploying to the required services (secrets, edge functions, and similar), and deployment then follows their rules. The security requirement is critical (minimizing and redacting secrets in logs is implied).
- Integrations: Only Supabase and Stripe for now; sending email alerts through Amazon SES may also be needed. Do not add anything else at this stage.
## Baseline secret list (defaults)
- Supabase: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_KEY`.
- Stripe: `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` (if webhooks).
- SES (optional): `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `SES_SENDER`.
- Vercel/Netlify: access token + project identifier.
