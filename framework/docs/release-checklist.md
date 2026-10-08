# Release Checklist

1) All end-to-end tests passed.
2) Independent review is done (see `framework/review/`).
3) The review handoff is prepared (`framework/review/handoff.md`).
4) Framework review is done (see `framework/framework-review/`).
5) Critical flow checked: Wizard, then Results, then Report, then PDF.
6) Auth and subscriptions checked (mock or real).
7) Email and web-push notifications checked (mock or real).
8) Database migrations applied.
9) Row-level security policies checked.
10) Legal pages updated.
11) Accessibility checked against basic WCAG requirements.
12) Rollback plan is ready.
13) For legacy projects: changes went through the `legacy-migration` branch and approval.
