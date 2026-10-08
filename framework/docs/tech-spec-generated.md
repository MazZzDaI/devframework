# Generated spec (self-host devframework)

## 1. Goal and success criterion
- The framework's goal is to produce a complete technical specification so that an agent can carry out the entire development cycle fully autonomously; the framework asks questions and produces everything required, and it is designed for non-technical users who can describe a product in plain language.
- In any host project (empty or with legacy) the framework itself runs the interview, prepares a complete spec, launches an agent that carries out development, testing, and the application build, and finishes correctly, notifying the user. That end-to-end pass counts as success for the first iteration.

## 2. User and experience
- Roles: The only role is the author and owner of the product idea; they are also the product owner, analyst, and business sponsor, but not a developer. They understand the value and the user flows well, but are weak at answering technical questions.
- Minimum contact after the interview: The ideal is fully autonomous work with no further questions; if unavoidable clarifications arise along the way, they will tolerate them, but they count on those cases being rare and justified.
- Key scenario: The only scenario is to start the framework, go through the questions until it marks them "enough", receive the generated spec, give final approval, and go rest; the framework itself does the development, tests, and release and sends an alert when it is finished or when a rare clarification is needed.
- Final notification: A reply right in the current channel (chat or terminal) is enough, in the same tone as now: a short "the work is done, take a look"; if a clarification is needed, ask the question right there. The channel, language, attachments, or buttons do not matter.

## 3. Scope
- In scope: discovery → spec → plan → orchestrator → review/post-run.
- Host project types: The approach is intended to be general: the classic cycle "gather requirements → spec → plan → parallel tasks → orchestrator". It should work the same way for any host projects (web, mobile, books, and others), with no tie to a stack or PaaS; for simple projects, out-of-the-box applicability is expected.
- Out of scope: optimizations and performance work in the MVP (see SLO).

## 4. Architecture and processes
- Orchestrator + a worktree per task + main/post/legacy phases.
- Parallel task map: `docs/orchestrator-plan.md`.
- Self-review and bug-report collection: That flow is already provided for: the framework must analyze itself (framework-review), collect bug reports from host projects into a central repository, and improve itself. The templates are in the repo; they should be used and followed.  Note: the framework must log every question and answer in this file.
- Stop points: Fully autonomous work is expected. Stop points appear only in abnormal situations (not enough information, access is required, and similar); the agent itself must decide the criteria for when to slow down and ask.

## 5. Default stack
- Base stack: React + Node.js + Supabase; Stripe for payments; Tailwind. Python utilities are allowed. For WordPress projects, PHP and the accompanying stack. For now the focus is on this set; expansion is possible later.

## 6. Deployment and environments
- Two main deployment options: Vercel or Netlify. (The stack is React/Node/Supabase/Stripe.) Environments were not stated explicitly; the standard dev/staging/prod set can be proposed.

## 7. Integrations
- Only Supabase and Stripe for now; sending email alerts through Amazon SES may also be needed. Do not add anything else at this stage.

## 8. Secrets and access
- Development proceeds without credentials until they are actually needed. When they are needed, the agent makes a stop point and asks for them. Secrets go in an env file; access is provided for deploying to the required services (secrets, edge functions, and similar), and deployment then follows their rules. The security requirement is critical (minimizing and redacting secrets in logs is implied).

## 9. Logging and reporting
- Every logging artifact that makes it possible to catch and fix errors effectively is needed. The agent itself produces the required logs, bug reports, and reports (orchestrator steps, test results, and so on) in suitable formats, so that bugs can be analyzed and fixed from them.

## 10. Non-functional requirements (MVP)
- At the MVP stage the key requirement is full operation with no errors and passing every test. Speed and availability targets are not set yet; optimization will come after stable operation.

## 11. Artifact format
- One overview file is needed, with the idea and a table of contents, linking to the detailed files. The structure must be clear and sufficient for the agent to work autonomously. (The project language is English.)

## 12. TODO / UNKNOWN
- None
