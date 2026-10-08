# GPT-5.2 Pro + Claude Code: Architect + Executor

> **NOTE**: This document uses example file paths (formal-spec.md, architecture-decisions.md, review-report.md, and others). These files **will be generated** by agents while tasks run. The paths are shown to illustrate the structure.

## Concept

**Key idea**: Use the strengths of both agents in one pipeline.

```
GPT-5.2 Pro reasoning → Removes ambiguities
         ↓
Claude Code → Can work autonomously
```

## Why this pairing works

### The Claude Code problem
❌ Asks many questions because the spec is ambiguous
❌ Stops when something is uncertain
❌ Requires constant user involvement

### The strength of GPT-5.2 Pro reasoning
✅ Formalizes requirements to a machine-readable level
✅ Finds contradictions and gaps
✅ Describes invariants, edge cases, and criteria
✅ Creates a detailed architecture

### Result
✅ Claude Code gets a spec so detailed that **it does not need to ask questions**
✅ Autonomous work for hours without interruptions
✅ High code quality (Claude's strength)
✅ A security audit from GPT-5.2 Pro at the final stage

---

## Pipeline architecture

```
┌─────────────────────────────────────────────────────┐
│ USER INPUT                                          │
│ "Implement a notification system with email and push" │
└──────────────────┬──────────────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────────────┐
│ PHASE 1: FORMAL SPECIFICATION                       │
│ Agent: GPT-5.2 Pro reasoning                        │
│ Mode: Interactive (asks the user questions)         │
│ Duration: 45-90 min                                 │
│                                                     │
│ Process:                                            │
│ 1. Analyzes the requirements                       │
│ 2. Asks clarifying questions                       │
│ 3. Formalizes the architecture                     │
│ 4. Describes invariants                            │
│ 5. Defines acceptance criteria                     │
│ 6. Creates a test matrix                           │
│                                                     │
│ Output:                                             │
│ - formal-spec.md (detailed specification)          │
│ - architecture-decisions.md (ADR)                  │
│ - test-plan.md (test plan)                         │
└──────────────────┬──────────────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────────────┐
│ PHASE 2: IMPLEMENTATION                             │
│ Agent: Claude Code                                  │
│ Mode: AUTONOMOUS (no questions!)                    │
│ Duration: 2-6 hours                                 │
│                                                     │
│ Input:                                              │
│ - formal-spec.md                                    │
│ - architecture-decisions.md                         │
│ - autonomous-mode-protocol.md                       │
│                                                     │
│ Why it is autonomous:                               │
│ ✓ All architectural decisions are made            │
│ ✓ Technologies are chosen                          │
│ ✓ Edge cases are described                         │
│ ✓ Done criteria are explicit                       │
│ ✓ Patterns are specified                           │
│                                                     │
│ Process:                                            │
│ 1. Reads formal-spec.md                            │
│ 2. Implements from the specification               │
│ 3. Follows project patterns                        │
│ 4. Writes tests according to test-plan.md         │
│ 5. Documents decisions in handoff.md              │
│                                                     │
│ Output:                                             │
│ - Implemented functionality                        │
│ - Tests (unit + integration)                       │
│ - handoff.md (decision documentation)              │
└──────────────────┬──────────────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────────────┐
│ PHASE 3: CODE REVIEW & SECURITY AUDIT               │
│ Agent: GPT-5.2 Pro reasoning                        │
│ Mode: Analytical                                    │
│ Duration: 30-60 min                                 │
│                                                     │
│ Input:                                              │
│ - formal-spec.md (original specification)          │
│ - Code from Claude Code                            │
│ - handoff.md (Claude's decisions)                  │
│                                                     │
│ Process:                                            │
│ 1. Checks conformance to the specification         │
│ 2. Looks for logic bugs                            │
│ 3. Checks invariants                               │
│ 4. Finds race conditions                           │
│ 5. Security audit                                  │
│ 6. Checks edge cases                               │
│                                                     │
│ Output:                                             │
│ - review-report.md                                  │
│   - Critical issues (block the merge)              │
│   - Warnings (should be fixed)                     │
│   - Suggestions (optional improvements)            │
└──────────────────┬──────────────────────────────────┘
                   │
              [If critical issues are found]
                   │
                   ↓
┌─────────────────────────────────────────────────────┐
│ PHASE 4: FIXES (optional)                           │
│ Agent: Claude Code                                  │
│ Mode: Autonomous                                    │
│ Duration: 30-90 min                                 │
│                                                     │
│ Input: review-report.md (critical issues only)      │
│ Fixes the critical problems that were found        │
│                                                     │
│ Output: Fixed code                                  │
└──────────────────┬──────────────────────────────────┘
                   │
                   ↓
              [DONE]
```

---

## Formal Specification template from GPT-5.2 Pro

### Structure of `formal-spec.md`

```markdown
# Formal Specification: [Feature Name]

**Created by**: GPT-5.2 Pro reasoning
**Date**: [YYYY-MM-DD]
**For**: Claude Code (autonomous implementation)

---

## 1. EXECUTIVE SUMMARY

**What**: [A short description of the feature in 2-3 sentences]

**Why**: [The business reason this is needed]

**Success Criteria**: [How to measure success]
- Metric 1: [a concrete metric]
- Metric 2: [a concrete metric]

---

## 2. FUNCTIONAL REQUIREMENTS

### 2.1 Core Features (Must Have)

#### Feature 1: [Name]
**Description**: [Detailed description]

**User Story**: As a [role], I want [action], so that [benefit]

**Acceptance Criteria**:
- [ ] Given [precondition], when [action], then [expected result]
- [ ] Given [precondition], when [action], then [expected result]

**Invariants** (conditions that must ALWAYS be true):
- Invariant 1: [formal description]
- Invariant 2: [formal description]

**Edge Cases**:
- Case 1: [description] → Expected behavior: [what should happen]
- Case 2: [description] → Expected behavior: [what should happen]

---

### 2.2 Optional Features (Should Have)

[The same structure for optional features]

---

### 2.3 Out of Scope

**Explicitly NOT included**:
- Item 1: [what is excluded] — Reason: [why]
- Item 2: [what is excluded] — Reason: [why]

---

## 3. TECHNICAL ARCHITECTURE

### 3.1 Technology Stack

**Confirmed Choices** (already decided, do NOT change):

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| Database | PostgreSQL 15 | Existing stack, JSONB support |
| Backend | Node.js + Express | Project standard |
| Frontend | React 18 + TypeScript | Project standard |
| Styling | Tailwind CSS | Project standard |
| Testing | Jest + React Testing Library | Project standard |

**New Dependencies** (need to be added):
- Package: `nodemailer` — Purpose: Email sending
- Package: `web-push` — Purpose: Push notifications

---

### 3.2 Database Schema

**New Tables**:

```sql
-- Table: notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL CHECK (type IN ('email', 'push', 'in_app')),
  title TEXT NOT NULL CHECK (length(title) > 0 AND length(title) <= 200),
  body TEXT CHECK (length(body) <= 2000),
  data JSONB DEFAULT '{}',
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Constraints
  CONSTRAINT valid_data CHECK (jsonb_typeof(data) = 'object')
);

-- Indexes
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, created_at DESC)
  WHERE read_at IS NULL;
CREATE INDEX idx_notifications_user_all ON notifications(user_id, created_at DESC);

-- RLS Policies
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY notifications_select_own ON notifications
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY notifications_update_own ON notifications
  FOR UPDATE USING (user_id = auth.uid());
```

**Schema Invariants**:
1. `user_id` must always reference valid user
2. `type` must be one of allowed values
3. `title` cannot be empty
4. `read_at` can only be set, never unset (monotonic)
5. `created_at` is immutable

---

### 3.3 API Endpoints

#### GET /api/notifications

**Purpose**: Fetch user's notifications

**Auth**: Required (JWT token)

**Query Parameters**:
```typescript
{
  unread?: boolean;      // Filter by read status (optional)
  limit?: number;        // Default: 20, Max: 100
  offset?: number;       // Default: 0
  type?: 'email' | 'push' | 'in_app';  // Filter by type (optional)
}
```

**Response**:
```typescript
{
  data: Array<{
    id: string;
    type: 'email' | 'push' | 'in_app';
    title: string;
    body: string | null;
    data: object;
    read_at: string | null;
    created_at: string;
  }>;
  pagination: {
    total: number;
    limit: number;
    offset: number;
    has_more: boolean;
  };
}
```

**Error Responses**:
- 401: Unauthorized (no/invalid token)
- 400: Bad request (invalid query params)
- 500: Internal server error

**Validation Rules**:
- `limit`: Must be 1-100
- `offset`: Must be >= 0
- `type`: Must be one of allowed values

**Edge Cases**:
1. User has no notifications → Return empty array with total=0
2. Offset > total → Return empty array with has_more=false
3. Invalid type filter → 400 error with descriptive message

---

#### POST /api/notifications/:id/read

**Purpose**: Mark notification as read

**Auth**: Required (JWT token)

**Path Parameters**:
- `id`: UUID of notification

**Request Body**: None

**Response**:
```typescript
{
  data: {
    id: string;
    read_at: string;  // Timestamp when marked as read
  }
}
```

**Error Responses**:
- 401: Unauthorized
- 404: Notification not found or not owned by user
- 400: Notification already marked as read
- 500: Internal server error

**Invariants**:
- Cannot unmark as read (read_at is monotonic)
- Can only mark own notifications
- Idempotent: calling twice returns same result

---

### 3.4 File Structure

**New Files to Create**:

```
src/
├── api/
│   └── notifications/
│       ├── index.ts              # Router
│       ├── list.ts               # GET /api/notifications
│       ├── markRead.ts           # POST /api/notifications/:id/read
│       └── __tests__/
│           └── notifications.test.ts
│
├── services/
│   ├── notificationService.ts    # Business logic
│   └── emailService.ts           # Email sending
│
├── components/
│   ├── NotificationBell.tsx      # Bell icon with badge
│   ├── NotificationList.tsx      # Dropdown list
│   └── NotificationItem.tsx      # Single notification
│
├── hooks/
│   └── useNotifications.ts       # React hook for real-time
│
└── types/
    └── notification.ts           # TypeScript types

db/
└── migrations/
    └── 007_create_notifications.sql
```

---

### 3.5 Code Patterns to Follow

**Pattern Source**: Check these files for existing patterns

| Pattern | Reference File | What to Match |
|---------|---------------|---------------|
| API endpoint structure | `src/api/auth/me.ts` | Middleware, error handling, response format |
| Database queries | `src/db/queries/users.ts` | Prepared statements, error handling |
| React components | `src/components/UserMenu.tsx` | TypeScript typing, hooks usage |
| Testing | `src/api/__tests__/auth.test.ts` | Test structure, mocking |

**Naming Conventions**:
- API files: `camelCase.ts`
- Components: `PascalCase.tsx`
- Hooks: `useCamelCase.ts`
- Database tables: `snake_case`
- Database columns: `snake_case`
- TypeScript types: `PascalCase`

---

## 4. NON-FUNCTIONAL REQUIREMENTS

### 4.1 Performance

- GET /api/notifications: < 200ms p95
- POST /api/notifications/:id/read: < 100ms p95
- Notification list load: < 500ms perceived (with skeleton loader)

### 4.2 Security

**Threats to Mitigate**:
1. **IDOR**: User accessing other user's notifications
   - Mitigation: RLS policies + server-side user_id check
2. **XSS**: Malicious content in notification body
   - Mitigation: Sanitize HTML, use DOMPurify in frontend
3. **SQL Injection**: Malicious query params
   - Mitigation: Parameterized queries only
4. **DoS**: Excessive notifications
   - Mitigation: Rate limiting on notification creation

**Security Checklist**:
- [ ] All queries use parameterized statements
- [ ] RLS policies tested with different user contexts
- [ ] HTML content sanitized before rendering
- [ ] Rate limiting implemented (100 req/min per user)

### 4.3 Accessibility

- Bell icon has `aria-label="Notifications"`
- Notification count has `aria-live="polite"`
- Keyboard navigation (Tab, Enter, Escape)
- Screen reader friendly (ARIA labels on all interactive elements)

---

## 5. TEST PLAN

### 5.1 Unit Tests

**Backend** (`src/api/notifications/__tests__/notifications.test.ts`):

```typescript
describe('GET /api/notifications', () => {
  test('returns user notifications', async () => {
    // Setup: Create test notifications
    // Action: GET request with auth
    // Assert: Correct data, pagination
  });

  test('filters by unread status', async () => {
    // Test unread=true parameter
  });

  test('respects pagination limits', async () => {
    // Test limit, offset, has_more
  });

  test('returns 401 without auth', async () => {
    // Test unauthorized access
  });

  test('does not return other users notifications', async () => {
    // Security test: IDOR prevention
  });
});

describe('POST /api/notifications/:id/read', () => {
  test('marks notification as read', async () => {
    // Test happy path
  });

  test('is idempotent', async () => {
    // Test calling twice
  });

  test('returns 404 for other user notification', async () => {
    // Security test
  });
});
```

**Frontend** (`src/components/__tests__/NotificationBell.test.tsx`):

```typescript
describe('NotificationBell', () => {
  test('displays unread count', () => {
    // Test badge with count
  });

  test('opens dropdown on click', () => {
    // Test interaction
  });

  test('marks as read on click', () => {
    // Test marking read
  });

  test('is keyboard accessible', () => {
    // Test Tab, Enter, Escape
  });
});
```

### 5.2 Integration Tests

**Full Flow Test**:
1. Create notification in DB
2. GET /api/notifications → should appear
3. Click notification → mark as read
4. GET /api/notifications?unread=true → should not appear

### 5.3 Manual Testing Checklist

- [ ] Notification appears in real-time (without refresh)
- [ ] Badge count updates after marking as read
- [ ] Works in Chrome, Firefox, Safari
- [ ] Keyboard navigation works
- [ ] Screen reader announces notifications

---

## 6. ACCEPTANCE CRITERIA (Definition of Done)

Implementation is complete when ALL are true:

### Functional
- [ ] All "Must Have" features implemented and tested
- [ ] All API endpoints return correct responses
- [ ] Database migration runs successfully
- [ ] RLS policies prevent unauthorized access

### Quality
- [ ] All unit tests passing (coverage > 80%)
- [ ] Integration tests passing
- [ ] No TypeScript errors
- [ ] No ESLint warnings
- [ ] Code follows project patterns (verified by comparing to reference files)

### Documentation
- [ ] All decisions documented in `handoff.md`
- [ ] API endpoints documented in code comments
- [ ] Complex logic has explanatory comments
- [ ] README updated (if public API changes)

### Security
- [ ] Security checklist (section 4.2) completed
- [ ] No secrets in code
- [ ] Input validation on all endpoints
- [ ] XSS prevention tested

---

## 7. IMPLEMENTATION GUIDANCE FOR CLAUDE CODE

### 7.1 Decision Framework

**If you encounter ambiguity NOT covered in this spec:**

1. **Check reference files first** (section 3.5)
   - Follow existing patterns exactly

2. **Choose conservative approach**
   - Simpler > Complex
   - Explicit > Implicit
   - Standard library > New dependency

3. **Document your decision in handoff.md**
   ```markdown
   DECISION: [what you chose]
   RATIONALE: [why]
   ALTERNATIVES: [what else you considered]
   SPEC GAP: [what was missing from spec]
   ```

### 7.2 If You Get Blocked

**DO NOT stop the entire task.**

Instead:
1. Try 3 different approaches (document each)
2. If still blocked: implement minimal version that compiles
3. Document blocker in handoff.md:
   ```markdown
   BLOCKER: [description]
   ATTEMPTED: [what you tried]
   WORKAROUND: [what you did instead]
   NEEDS: [what's needed to unblock]
   ```
4. Continue with next subtask

### 7.3 Time Budget

**Total**: 240 minutes (4 hours)

- Database migration: 20 min
- API endpoints: 90 min (45 min each)
- Frontend components: 80 min
- Tests: 40 min
- Integration & polish: 10 min

**Progress Checkpoints**:
- 60 min (25%): Database + 1 endpoint done
- 120 min (50%): Both endpoints + basic UI done
- 180 min (75%): All features done, starting tests
- 240 min (100%): Tests done, ready for review

**If running behind at 50% mark**: Focus only on "Must Have", defer "Should Have"

---

## 8. KNOWN RISKS & MITIGATIONS

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Push notifications require VAPID keys setup | High | Medium | Defer to Phase 2, implement email first |
| Real-time updates complex in Safari | Medium | High | Use polling fallback for Safari |
| Email rate limits hit during testing | Low | Medium | Mock email service in tests |
| Notification spam (user gets too many) | Medium | Low | Add rate limiting from start |

---

## 9. SUCCESS METRICS

**After implementation, measure**:

- Implementation time: Target < 5 hours
- Test coverage: Target > 80%
- API response times: p95 < 200ms
- Zero critical security issues in review
- Autonomous completion: No questions asked during implementation

---

## 10. APPENDIX

### 10.1 Example Notification Objects

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": "123e4567-e89b-12d3-a456-426614174000",
  "type": "email",
  "title": "Welcome to the platform!",
  "body": "Thanks for signing up. Get started by...",
  "data": {
    "action_url": "/onboarding",
    "action_label": "Get Started"
  },
  "read_at": null,
  "created_at": "2026-01-26T10:30:00Z"
}
```

### 10.2 Database Test Data

```sql
-- Use this for testing
INSERT INTO notifications (user_id, type, title, body) VALUES
  ('123e4567-e89b-12d3-a456-426614174000', 'in_app', 'Test notification 1', 'Body 1'),
  ('123e4567-e89b-12d3-a456-426614174000', 'email', 'Test notification 2', 'Body 2');
```

---

**This specification is complete and unambiguous. Claude Code should have ZERO questions during implementation.**
```

---

## Integration into orchestrator.json

```json
{
  "runners": {
    "gpt52-pro": {
      "type": "gpt52-pro-reasoning",
      "command": "gpt52-cli",
      "mode": "interactive",
      "note": "Used for architecture and review phases"
    },
    "claude-code": {
      "type": "claude-code",
      "command": "claude-code",
      "autonomous_mode": {
        "enabled": true,
        "protocol_file": "claude-code/01-autonomous-mode-protocol.md"
      }
    }
  },

  "workflows": {
    "gpt52-claude-pipeline": {
      "description": "GPT-5.2 Pro (architect) → Claude Code (executor)",
      "phases": [
        {
          "name": "formal-spec",
          "agent": "gpt52-pro",
          "mode": "interactive",
          "output": "framework/docs/formal-spec.md"
        },
        {
          "name": "implementation",
          "agent": "claude-code",
          "mode": "autonomous",
          "input": "framework/docs/formal-spec.md",
          "depends_on": ["formal-spec"]
        },
        {
          "name": "review",
          "agent": "gpt52-pro",
          "mode": "analytical",
          "input": [
            "framework/docs/formal-spec.md",
            "git diff main...feature-branch",
            "framework/docs/handoff.md"
          ],
          "output": "framework/review/review-report.md",
          "depends_on": ["implementation"]
        },
        {
          "name": "fixes",
          "agent": "claude-code",
          "mode": "autonomous",
          "input": "framework/review/review-report.md",
          "condition": "if critical issues found",
          "depends_on": ["review"]
        }
      ]
    }
  },

  "tasks": [
    {
      "id": "notifications-feature",
      "workflow": "gpt52-claude-pipeline",
      "phases": [
        {
          "phase": "formal-spec",
          "file": "prompts/notifications-initial-request.md",
          "time_budget": 90
        },
        {
          "phase": "implementation",
          "file": "framework/docs/formal-spec.md",
          "time_budget": 240,
          "watchdog": {
            "enabled": true,
            "check_interval_seconds": 120,
            "stuck_threshold_seconds": 600
          }
        },
        {
          "phase": "review",
          "time_budget": 60
        },
        {
          "phase": "fixes",
          "time_budget": 60,
          "optional": true
        }
      ]
    }
  ]
}
```

---

## Full workflow example

### Step 1: The user gives the task to GPT-5.2 Pro

**Input**: `prompts/notifications-initial-request.md`

```markdown
We need to implement a notification system for a SaaS application.

Requirements:
- In-app notifications (a bell in the header)
- Email notifications
- Push notifications (optional)
- The user can mark notifications as read
- Notification history

Stack: Node.js, React, PostgreSQL
```

### Step 2: GPT-5.2 Pro asks questions

```
GPT-5.2: "I will clarify a few points so the specification is complete:

1. Email notifications:
   - Use the existing email provider, or do we need a new one?
   - What triggers email? (immediately, a once-a-day digest, or configurable?)

2. In-app notifications:
   - Real-time (WebSocket) or polling?
   - Do similar notifications need to be grouped?

3. Push notifications:
   - Web Push (Service Workers), or native apps as well?
   - Defer to Phase 2, or implement it now?

4. Architecture:
   - Notifications as a separate microservice, or part of the monolith?
   - Do we need a queue (Redis/RabbitMQ), or is synchronous enough?

5. Privacy & Security:
   - Can notifications contain sensitive data?
   - How long should we keep them (retention policy)?
```

### Step 3: The user answers

```
User: "
1. Email — use the existing SendGrid, trigger immediately
2. In-app — polling is simpler; defer real-time to Phase 2
3. Push — defer it entirely to Phase 2
4. Architecture — part of the monolith, synchronous
5. Privacy — no sensitive data, keep for 90 days
"
```

### Step 4: GPT-5.2 Pro creates formal-spec.md

(See the template above — a full ~20KB document that spells out every aspect)

### Step 5: Claude Code implements it autonomously

**Launch**:
```bash
python orchestrator.py --phase implementation --task notifications-feature
```

**What happens**:
1. Claude Code reads `formal-spec.md`
2. Sees that every decision is already made (email = SendGrid, polling, monolith, and so on)
3. Reads patterns from the reference files
4. Implements:
   - Database migration (20 min)
   - API endpoints (90 min)
   - React components (80 min)
   - Tests (40 min)
5. Documents decisions in `handoff.md`
6. **Zero questions to the user** (everything was in the spec)

### Step 6: GPT-5.2 Pro reviews the code

**Input**:
- `formal-spec.md` (the original specification)
- `git diff main...notifications-branch` (code from Claude)
- `handoff.md` (Claude's decisions)

**Process**:
```
GPT-5.2 Pro analyzes:

✓ Conformance to the specification
✓ Invariants hold (read_at monotonic, user_id always valid)
✓ Security: RLS policies work
✓ Edge cases are handled
⚠ Found: race condition in markAsRead (two parallel requests)
⚠ Found: missing index on notifications.created_at
✓ Accessibility: ARIA labels are present
```

**Output**: `review-report.md`

```markdown
# Code Review Report: Notifications Feature

## Summary
Implementation matches specification 95%.
Found 2 issues: 1 critical, 1 warning.

## Critical Issues (block the merge)

### Issue 1: Race Condition in markAsRead
**File**: `src/api/notifications/markRead.ts:23`

**Problem**:
Two parallel requests can both see read_at=null and both try to update.
Not transactionally safe.

**Current Code**:
```typescript
const notification = await db.query('SELECT * FROM notifications WHERE id = $1', [id]);
if (notification.read_at !== null) {
  throw new Error('Already read');
}
await db.query('UPDATE notifications SET read_at = NOW() WHERE id = $1', [id]);
```

**Fix**:
Use atomic UPDATE with WHERE condition:
```typescript
const result = await db.query(
  'UPDATE notifications SET read_at = NOW() WHERE id = $1 AND read_at IS NULL RETURNING *',
  [id]
);
if (result.rows.length === 0) {
  // Already read or not found
}
```

**Severity**: Critical (data race)
**Must fix**: Yes

---

## Warnings (should be fixed)

### Issue 2: Missing Index
**File**: `framework/migration/007_create_notifications.sql`

**Problem**:
Query `SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC`
will be slow without index on created_at.

**Fix**:
Add composite index:
```sql
CREATE INDEX idx_notifications_user_created ON notifications(user_id, created_at DESC);
```

**Severity**: Warning (performance issue at scale)
**Must fix**: No (but recommended)

---

## Suggestions (optional improvements)

1. Consider adding `updated_at` trigger for audit
2. Notification `data` JSONB could use GIN index for filtering
3. Add Prometheus metrics for notification send rate

---

## Approval Status

❌ NOT APPROVED - Fix critical issue #1 first
```

### Step 7: Claude Code fixes the critical issues

**Input**: `review-report.md` (Critical Issues section)

**Process**:
```
Claude Code:
1. Reads Issue #1
2. Applies the proposed fix
3. Updates the tests (adds a test for the race condition)
4. Commits: "fix: atomic update in markAsRead to prevent race condition"
5. Documents it in handoff.md:
   "FIXED: Race condition in markAsRead (review issue #1)
    Changed to atomic UPDATE with WHERE clause"
```

**Duration**: 15 minutes

### Step 8: Final check

GPT-5.2 Pro checks that the fix was applied:

```markdown
# Re-review: Critical Issues

## Issue #1: Race Condition
✅ FIXED - Atomic UPDATE implemented correctly
✅ Test added for concurrent requests
✅ Code matches recommended fix

## Approval Status
✅ APPROVED - Ready to merge
```

---

## Effectiveness metrics

### Comparison of approaches

| Metric | Claude Only | GPT-5.2 Pro Only | **Pipeline** |
|---------|-------------|------------------|--------------|
| **Specification time** | 30 min (incomplete) | 90 min (complete) | **90 min** |
| **Questions during implementation** | 15-20 | 0 | **0** ✅ |
| **Implementation time** | 6-8 hours | 8-10 hours | **4 hours** ✅ |
| **Bugs in review** | 3-5 | 1-2 | **2** |
| **Critical issues** | 2-3 | 0-1 | **1** |
| **Code quality** | 8/10 | 7/10 | **9/10** ✅ |
| **Security audit quality** | 6/10 | 10/10 | **10/10** ✅ |
| **Total time** | 7-9 hours | 9-11 hours | **6 hours** ✅ |
| **User tie-up** | High | Medium | **Low** ✅ |

### Breakdown by phase

```
GPT-5.2 + Claude Pipeline:
├─ Phase 1 (Spec): 90 min [GPT-5.2 Pro, interactive]
├─ Phase 2 (Code): 240 min [Claude Code, AUTONOMOUS] ← No questions!
├─ Phase 3 (Review): 60 min [GPT-5.2 Pro, analytical]
└─ Phase 4 (Fixes): 30 min [Claude Code, autonomous]
─────────────────────────────────────────────────────
Total: 420 min (7 hours)

Of that, user interaction:
- Phase 1: 90 min (answers GPT-5.2 Pro's questions)
- Phase 2: 0 min (Claude works autonomously) ✅
- Phase 3: 10 min (reads the review report)
- Phase 4: 0 min (autonomous fixes)
─────────────────────────────────────────────────────
Total user time: ~100 min (1.7 hours)

Autonomy index: 76% (5.3 of 7 hours autonomous)
```

### ROI analysis

**Cost**:
- ChatGPT Pro: $200/mo
- Claude Code: included in the Anthropic API (~$50/mo)
- **Total**: ~$250/mo

**Time saved** (per feature):
- Without the pipeline: 9 hours
- With the pipeline: 7 hours
- **Saved**: 2 hours of actual work

**Time freed from the keyboard**:
- Without the pipeline: 7 hours tied to the computer
- With the pipeline: 1.7 hours tied to the computer
- **Freedom**: 5.3 hours you can spend on other work

**Break-even** (at $100/hour of developer time):
- Savings: 2 hours × $100 = $200 per feature
- Cost: $250/mo
- Break-even: **1.25 features per month**

---

## Practical recommendations

### When to use this pipeline

✅ **Use it when:**
- The feature is complex (> 4 hours of implementation)
- Reliability matters (finance, security, data)
- You need autonomy (you do not want to stay tied to the machine)
- You have budget for ChatGPT Pro
- The project is long-term

❌ **Do not use it when:**
- Simple CRUD (< 2 hours of implementation)
- Prototypes and experiments
- There is no budget for Pro
- The task is exploratory (the architecture is unclear)

### Optimizing the pipeline

**Speed up Phase 1 (Spec)**:
- Prepare a question template for GPT-5.2 Pro
- Give links to the docs up front
- Name the reference files in the initial request

**Speed up Phase 2 (Code)**:
- Make sure formal-spec.md is actually complete
- Add more code examples to the spec
- State explicitly what to defer

**Improve Phase 3 (Review)**:
- Give GPT-5.2 Pro access to the test results
- Include a security checklist in the spec
- Ask for a ranked list of issues (critical → warning → suggestion)

---

## Alternative configurations

### Option 1: Budget (without GPT-5.2 Pro)

```
Claude Code (spec, interactive)
       ↓
Codex (implementation, autonomous)
       ↓
Claude Code (review, interactive)
```

**Pros**: Cheaper (~$50/mo instead of $250)
**Cons**: Claude will ask questions in Phase 1, and the review is less strict

---

### Option 2: Maximum quality

```
GPT-5.2 Pro (spec, interactive)
       ↓
Claude Code (architecture, interactive) ← Extra step
       ↓
Codex (implementation, autonomous)
       ↓
GPT-5.2 Pro (review, analytical)
       ↓
Claude Code (polish, autonomous)
```

**Pros**: Maximum quality; the code follows the patterns
**Cons**: Longer (~8-9 hours instead of 7)

---

### Option 3: Ultra-autonomous

```
GPT-5.2 Pro (spec, interactive) ← The only step with the user
       ↓
Codex (implementation, autonomous)
       ↓
GPT-5.2 Pro (review, autonomous) ← Autonomous too!
       ↓
Codex (fixes, autonomous)
```

**Pros**: Maximum autonomy (the user is involved only at the start)
**Cons**: You need an autonomous version of the GPT-5.2 Pro review

---

## Troubleshooting

### Problem: Claude still asks questions

**Cause**: formal-spec.md is not detailed enough

**Solution**:
1. Check that the spec contains EVERY section from the template
2. Add more code examples
3. Name the reference files explicitly
4. Next time, give GPT-5.2 Pro more time for the spec

---

### Problem: GPT-5.2 Pro takes too long on the spec

**Cause**: Overthinking; it specifies too much detail

**Solution**:
1. Set a time limit: "You have 60 minutes for the spec"
2. Ask for a "production-ready spec, not an academic paper"
3. Say to defer non-critical details
4. Give a template and say "fill in this template"

---

### Problem: Claude cannot find the reference files

**Cause**: Paths in the spec are inaccurate, or the files do not exist

**Solution**:
1. Check that the reference files actually exist
2. Use paths relative to the project root
3. Give Claude a list of all files: `find src -name "*.ts" > files.txt`
4. Include `ls -la` output in the spec

---

### Problem: Review finds too many issues

**Cause**: GPT-5.2 Pro is too strict, or Claude drifted from the spec

**Solution**:
1. Check that Claude read formal-spec.md (handoff should contain references)
2. If the issues are legitimate: improve the spec for next time
3. If GPT-5.2 Pro is nitpicky: ask it to focus on critical/high severity only
4. Calibrate: give examples of "what counts as critical vs warning"

---

## Next steps

1. ✅ Read this document
2. → Decide: do you have access to GPT-5.2 Pro? (ChatGPT Pro subscription)
3. → Try it on one feature:
   - Have GPT-5.2 Pro create formal-spec.md
   - Claude Code implements from the spec (check: how many questions?)
   - GPT-5.2 Pro does the review
4. → Collect metrics (time, questions, quality)
5. → Decide: is the Pro subscription worth the cost?
6. → If yes: integrate it into orchestrator.json
7. → If no: use the budget option (Claude-only)

---

**Status**: ✅ Ready to use
**Requires**: a ChatGPT Pro subscription ($200/mo) for GPT-5.2 Pro reasoning
**ROI**: Break-even at 1.25+ features per month
**Autonomy**: 76% of the time with no user involvement
**Key benefit**: Claude Code works autonomously because of the detailed spec from GPT-5.2 Pro

🚀 **This is the final piece of your autonomous architecture!**
