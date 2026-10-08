# Required Inputs

Minimum artifacts and access needed for the framework to run correctly.

## 1) Required documents
- Discovery log: `framework/docs/discovery/interview.md`.
- Generated specification, plan, and inputs:
  `framework/docs/tech-spec-generated.md`,
  `framework/docs/plan-generated.md`,
  `framework/docs/data-inputs-generated.md`.
- Domain data templates when needed: `framework/docs/data-templates.md`.

## 2) Data (when applicable)
- CSV files in `framework/data/` (2026 domain example):
  `plans_2026.csv`, `zip_rating_map_2026.csv`, `fpl_2026.csv`, `slcsp_2026.csv`.

## 3) Access and secrets (ask only when first needed)
- Policy: work without credentials until they are actually required. The first real use is a stop point.
- `.env` (example variables):
  - Example file: `framework/.env.example`.
  - Supabase: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_KEY`.
  - Stripe: `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` (if webhooks are used).
  - SES (optional): `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `SES_SENDER`.
  - Vercel or Netlify: an access token and a project id.

## 4) Tools
- Cursor CLI `agent` on `PATH` (`curl https://cursor.com/install -fsS | bash`), signed in with `agent login` or `CURSOR_API_KEY`. The default model is Grok `grok-4.7` (`FRAMEWORK_CURSOR_MODEL`).
- A Git repository and write access to `framework/logs`.
