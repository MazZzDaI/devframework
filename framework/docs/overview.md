# Overview (self-host devframework)

## The idea in one paragraph
The framework's goal is to produce a complete technical specification so that an agent can carry out the entire development cycle fully autonomously; the framework asks questions and produces everything required, and it is designed for non-technical users who can describe a product in plain language.

## Success criterion
In any host project (empty or with legacy), the framework:
1) determines the project type (empty/legacy),
2) if legacy is present, performs the analysis and produces the migration artifacts,
3) **always starts the interview (discovery)** to clarify the requirements,
4) generates or corrects the spec and the work plan,
5) requests confirmation to start development,
6) performs development, testing, and the application build, and notifies the user.
That end-to-end pass counts as success for the first iteration.

## User role
The only role is the author and owner of the product idea; they are also the product owner, analyst, and business sponsor, but not a developer. They understand the value and the user flows well, but are weak at answering technical questions.

## Stack and deployment
- Stack: Base stack: React + Node.js + Supabase; Stripe for payments; Tailwind. Python utilities are allowed. For WordPress projects, PHP and the accompanying stack. For now the focus is on this set; expansion is possible later.
- Deploy: Two main deployment options: Vercel or Netlify. (The stack is React/Node/Supabase/Stripe.) Environments were not stated explicitly; the standard dev/staging/prod set can be proposed.

## Table of contents (key artifacts)
1) Spec: `docs/tech-spec-generated.md`
2) Work plan: `docs/plan-generated.md`
3) Inputs and secrets: `docs/data-inputs-generated.md`
4) Test plan: `review/test-plan.md`
5) Improvement backlog: `docs/backlog.md`
6) Bug report template: `docs/reporting/bug-report-template.md`
7) Orchestration map: `docs/orchestrator-plan.md`
8) Required inputs: `docs/inputs-required.md`
