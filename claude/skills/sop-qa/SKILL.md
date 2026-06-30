---
name: sop-qa
description: 'QA & Compliance audit — run AFTER building, BEFORE maw pr. Covers OWASP 2025, WCAG 2.2, NIST CSF 2.0, CWE Top 25, ISO 25010, CMMI v3, AI/LLM security, code quality, performance, accessibility, and doc-code alignment.'
---

# /sop-qa — QA & Compliance Audit

**You built it, you QA it.** Run this after building, before `maw pr`. No handoff. No waiting.

## Usage

```
/sop-qa                    # Full audit (all domains)
/sop-qa --security         # Security-focused (OWASP + CWE + NIST)
/sop-qa --accessibility    # WCAG 2.2 AA focused
/sop-qa --data             # PII & data exposure checks
/sop-qa --performance      # Performance + Core Web Vitals
/sop-qa --code-quality     # Code quality metrics only
/sop-qa --quick            # Smoke test + critical checks only
```

---

## Phase 0: Pre-Flight (MANDATORY)

### 0.1 Open Project Context (MANDATORY)

```bash
maw workon <project>
# This opens a dedicated tmux window with correct repo context.
# When done: maw done <window>
```

**Why**: `maw workon` ensures project CLAUDE.md is loaded, Playwright runs in correct dir, and all files are accessible. Subagents from one window lose project context.

**Worktree context**: If you're already in a worktree from `maw workon`, skip `maw workon` again — you're already there. Run the audit from within your working context.

### 0.2 Gather Context

```bash
# 1. Read Task Brief (if exists)
cat ~/ghq/github.com/deachawatss/<PROJECT>/TASK-*.md 2>/dev/null

# 2. Check past audit findings for this project
arra_search("<project-name> audit")

# 3. Detect tech stack + applicable phases
STACK=""
[ -f "next.config.ts" ] || [ -f "next.config.js" ] || [ -f "next.config.mjs" ] && STACK="$STACK nextjs"
[ -f "package.json" ] && STACK="$STACK node"
[ -f "go.mod" ] && STACK="$STACK go"
[ -f "Cargo.toml" ] && STACK="$STACK rust"
[ -f "requirements.txt" ] || [ -f "pyproject.toml" ] && STACK="$STACK python"
[ -d "frontend" ] && STACK="$STACK frontend"
[ -d "backend" ] && STACK="$STACK backend"
echo "Detected: $STACK"
```

**Stack-specific phase applicability:**

| Stack | Phase 1 (Live) | Phase 1.5 (UX) | Phase 3 (A11y) | Phase 5.3 (Types) | Phase 6 (Perf) | Phase 6.5 (Launch) | Phase 7 (DB) |
|---|---|---|---|---|---|---|---|
| Next.js / Frontend | Yes | Yes | Yes | Yes (TS) | Yes (Lighthouse) | If deploying | If DB present |
| Go backend | API only | Skip | Skip | Skip | API timing only | If deploying | If DB present |
| Rust backend | API only | Skip | Skip | Skip | API timing only | If deploying | If DB present |
| Python | API only | Skip | Skip | mypy instead | API timing only | If deploying | If DB present |
| Full-stack | Yes | Yes | Yes | Yes | Yes | If deploying | Yes |

**Output**: Tech stack identified, applicable phases noted, past findings loaded.

---

## Phase 1: Live Testing Gate

**MANDATORY. Code review alone is NOT testing.**

### 1.1 Service Health

```bash
# Health check
curl -s -o /dev/null -w "%{http_code}" http://localhost:<port>/api/health
# MUST return 200. If not → BLOCKED.

# Frontend loads
curl -s -o /dev/null -w "%{http_code}" http://localhost:<frontend-port>/
```

### 1.2 Authentication

```bash
# Export creds locally first (never commit literals): export NWFTH_TEST_USER=... NWFTH_TEST_PASSWORD=...
TOKEN=$(curl -s -X POST http://localhost:<port>/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$NWFTH_TEST_USER\",\"password\":\"$NWFTH_TEST_PASSWORD\"}" | jq -r '.token // .access_token // empty')
echo "TOKEN: ${TOKEN:0:20}..."
# MUST get a token. No token → CRITICAL FAIL.
```

### 1.3 Core Functionality

```bash
# Test main endpoint with auth
curl -s http://localhost:<port>/api/<main-endpoint> \
  -H "Authorization: Bearer $TOKEN" \
  -w "\nHTTP: %{http_code}"
```

### 1.4 Verdict Gate

| Result | Action |
|--------|--------|
| All 200, login works, data loads | PASS → proceed to Phase 1.5 |
| ANY 401/403/500 | FAIL → send back to dev with exact error |
| App not running | BLOCKED → report to Gale |

---

## Phase 1.5: UX/UI Quality Gate

Use Playwright (`/playwright-cli`) for visual checks:

| Check | Method | Severity |
|-------|--------|----------|
| Professional appearance | Screenshot + visual inspection | Critical |
| Responsive (375/768/1440px) | Playwright viewport resize | Critical |
| Loading states (skeleton/spinner) | Navigate with throttled network | Major |
| Empty states | Clear data, check messaging | Minor |
| Error states | Trigger errors, check user-facing messages | Major |
| Data tables: sort + filter + search + pagination | Interact with each | Major |
| Forms: validation + error messages + required fields | Submit invalid data | Major |
| Touch targets ≥44x44px | Inspect interactive elements | Minor |

## Phase 1.6: Integration Test Mandate

Critical user journeys MUST have end-to-end tests. Not unit tests — full flow from UI/API to database and back.

**Required flows** (test at least the golden path + 1 error case):

| Flow type | Test |
|---|---|
| Authentication | Login → access protected route → logout → verify redirect |
| Core CRUD | Create → read → update → delete → verify gone |
| Data submission | Fill form → submit → verify DB state → verify UI confirmation |
| Error recovery | Submit invalid data → verify error message → fix → submit successfully |

```bash
# Verify integration tests exist
find test/ tests/ e2e/ -name "*.test.*" -o -name "*.spec.*" 2>/dev/null | wc -l
# If 0 → P2 (warn: no integration tests found)

# Run existing integration tests
npx playwright test 2>/dev/null || bun test 2>/dev/null || go test ./... 2>/dev/null
```

If the project has no integration tests at all → **P2** (not blocking, but flag for next sprint).

---

## Phase 2: Security Audit (OWASP 2025 + CWE Top 25 + NIST)

### 2.1 OWASP Top 10:2025 — Full Checklist

#### A01: Broken Access Control
- [ ] IDOR test: modify object IDs in URLs, verify 403 for unauthorized
- [ ] Privilege escalation: login as regular user, access admin routes → must get 403
- [ ] URL/param tampering: manipulate query params for unauthorized data
- [ ] JWT manipulation: modify JWT payload, verify rejection
- [ ] CORS: verify `Access-Control-Allow-Origin` is not `*` on sensitive endpoints
- [ ] Force browsing: access `/admin`, `/debug`, `/api/internal` without auth → must get 401/403
- [ ] Directory traversal: `../../../etc/passwd` in file parameters → must be blocked

#### A02: Security Misconfiguration
- [ ] Security headers present:
  ```typescript
  // Playwright check
  const response = await page.goto(url);
  const h = response.headers();
  expect(h['x-frame-options']).toBeTruthy();           // DENY or SAMEORIGIN
  expect(h['x-content-type-options']).toBe('nosniff');
  expect(h['strict-transport-security']).toBeTruthy();  // max-age >= 31536000
  expect(h['content-security-policy']).toBeTruthy();
  expect(h['referrer-policy']).toBeTruthy();
  ```
- [ ] Error pages don't leak stack traces (test `/nonexistent-path`, malformed requests)
- [ ] No directory listing enabled
- [ ] HTTP methods restricted (OPTIONS should not expose unnecessary methods)
- [ ] Default credentials removed
- [ ] Debug mode disabled in production

#### A03: Software Supply Chain Failures
- [ ] `npm audit` / `cargo audit` — 0 critical/high vulnerabilities
- [ ] Lockfile integrity verified (`git diff main -- package-lock.json` — no unexpected changes)
- [ ] No known CVEs in dependencies
- [ ] SRI hashes on CDN scripts: `<script integrity="sha384-...">`
- [ ] Package sources are trusted registries only
- [ ] Transitive dependency scan: `npm ls --all --json | jq '.dependencies | length'` — review deep deps
- [ ] Abandoned packages: `npm outdated --json` — flag deps with last publish > 2 years
- [ ] No wildcard versions: `grep -E '"[*~^]' package.json` — pin exact versions for production
- [ ] Dependency drift: compare `npm audit --json` against baseline to flag NEW CVEs since last audit

#### A04: Cryptographic Failures
- [ ] All pages load over HTTPS (HTTP → HTTPS redirect)
- [ ] TLS ≥ 1.2 (verify with `curl --tlsv1.2`)
- [ ] No sensitive data in URLs (tokens, passwords, PII)
- [ ] Password fields use `type="password"`
- [ ] Cookies have `Secure` and `HttpOnly` flags
- [ ] Passwords hashed with bcrypt/argon2 (NOT MD5/SHA1)
- [ ] No plaintext secrets in config files

#### A05: Injection
- [ ] XSS: submit `<script>alert(1)</script>` in ALL input fields → verify not rendered
- [ ] SQL injection: `' OR 1=1--` in search/filter fields → verify parameterized
- [ ] OS command injection: `; ls` or `| cat /etc/passwd` in any input → verify blocked
- [ ] Path traversal: `../../../etc/passwd` in file parameters
- [ ] NoSQL injection: `{"$gt":""}` in JSON fields
- [ ] Template injection: `{{7*7}}` in user inputs
- [ ] Code grep: search for string concatenation in SQL queries
  ```bash
  grep -rn "format!.*SELECT\|format!.*INSERT\|format!.*UPDATE\|format!.*DELETE" src/
  grep -rn "query.*\+.*req\.\|query.*\$\{" src/
  grep -rn "execute.*f'" src/     # Python f-string SQL
  ```

#### A06: Insecure Design
- [ ] Rate limiting on login endpoint (5+ rapid requests → 429)
- [ ] Rate limiting on registration
- [ ] Business logic: submit negative quantities, zero-price orders, skip workflow steps
- [ ] Replay attack: re-submit same transaction → verify idempotency or rejection
- [ ] Missing CAPTCHA on sensitive forms (registration, password reset)

#### A07: Authentication Failures
- [ ] Account lockout after N failed attempts (test 5-10 wrong passwords)
- [ ] Session timeout after inactivity (verify redirect to login)
- [ ] Session invalidation on logout:
  ```typescript
  await login(page);
  const cookies = await page.context().cookies();
  await page.click('[data-testid=logout]');
  await page.context().addCookies(cookies); // reuse old session
  await page.goto('/dashboard');
  await expect(page).toHaveURL(/login/); // must redirect
  ```
- [ ] Password complexity enforced (min 8 chars, mixed case, numbers)
- [ ] No credentials in logs
- [ ] Generic error messages ("Invalid credentials" not "User not found")

#### A08: Software/Data Integrity Failures
- [ ] SRI attributes on external scripts
- [ ] CSP headers prevent inline script execution
- [ ] Tampered request bodies rejected (modify hidden form fields)
- [ ] No insecure deserialization of user input

#### A09: Security Logging & Alerting Failures
- [ ] Failed login attempts logged (check application logs)
- [ ] Admin/sensitive actions logged
- [ ] Logs do NOT contain: passwords, tokens, credit card numbers, PII
- [ ] Audit trail exists for data modifications
- [ ] Log injection: submit `\n` or log format strings in inputs → verify logs aren't corrupted
- [ ] Log injection code scan:
  ```bash
  grep -rn 'logger\.\w\+(.*req\.\|.*user\.' src/ | grep -v 'sanitize\|escape'
  # Each match must sanitize user input before logging (strip newlines, encode)
  ```

#### A10: Mishandling Exceptional Conditions
- [ ] Malformed requests → graceful error (JSON with error message, NOT stack trace)
- [ ] Empty body POST → handled gracefully
- [ ] Wrong Content-Type → 415 or graceful error
- [ ] Oversized payload → 413 or rejection
- [ ] Boundary conditions: empty strings, null, MAX_INT, special characters
- [ ] Fail-closed: if auth check fails, deny access (don't default to allow)

### 2.2 CWE Top 25 — Code-Level Checks

| CWE | Weakness | How to Check |
|-----|----------|-------------|
| CWE-79 | XSS | Input all fields with `<script>`, verify encoding. Check CSP headers. |
| CWE-89 | SQL Injection | Verify ALL queries use parameterized/prepared statements. Grep for string concat. |
| CWE-78 | OS Command Injection | Grep for `exec`, `spawn`, `system`, `popen` with user input. Verify `shell: true` not used with user data. |
| CWE-22 | Path Traversal | Test `../` in file params. Grep for `path.join` with user input without validation. |
| CWE-352 | CSRF | Verify anti-CSRF tokens on all state-changing forms/endpoints. |
| CWE-434 | Unrestricted Upload | Upload `.php`, `.exe`, polyglot files. Verify server-side MIME validation. |
| CWE-862 | Missing Authorization | Test every endpoint without auth token → must get 401. |
| CWE-798 | Hardcoded Credentials | Extended secrets scan (see 2.6 below). |
| CWE-918 | SSRF | Test: `127.0.0.1`, `::1`, `0.0.0.0`, `169.254.169.254` (AWS), `metadata.google.internal` (GCP), `169.254.169.254/metadata` (Azure). Also test DNS rebinding and `http://[::1]` IPv6. Grep: `grep -rn 'fetch\|http\.get\|urllib\|axios' src/ \| grep 'req\.\|params\.\|query\.'` |
| CWE-601 | Open Redirect | Test `?redirect=https://evil.com`, `//evil.com`, `javascript:alert(1)` → verify restricted to same domain. |
| CWE-94 | Code Injection | Grep for `eval()`, `Function()`, `new Function`, `vm.runInNewContext` with user input. |
| CWE-502 | Deserialization | Grep for `pickle.loads`, `unserialize`, `JSON.parse(req.body)` without schema validation. |
| CWE-770 | Resource Exhaustion | Test oversized payloads (10MB JSON), rapid requests to all endpoints, regex DoS patterns. |
| CWE-639 | Authz Bypass via User Key | Modify object IDs in multi-tenant context (user A accessing user B's resources via sequential IDs). |
| CWE-306 | Missing Auth on Critical Fn | Map all admin/sensitive endpoints, verify each requires auth + appropriate role. |
| CWE-1333 | ReDoS (Regex DoS) | Grep for nested quantifiers: `grep -rn '(.*+)+\|(.*\*)+' src/` — exponential backtracking risk. |
| CWE-1321 | Prototype Pollution | Grep for `Object.assign(.*req\.\|__proto__\|constructor.prototype` in Node.js code. |

### 2.3 NIST CSF 2.0 — Application-Level Controls

| Function | QA Check |
|----------|----------|
| **GV (Govern)** | RBAC configs documented, pipeline permissions reviewed |
| **ID (Identify)** | SBOM exists, dependency scan clean, asset inventory |
| **PR (Protect)** | Input validation, encryption at rest/transit, auth controls, CSP |
| **DE (Detect)** | Audit logs for auth failures, log completeness |
| **RS (Respond)** | Error handling doesn't leak data, generic error pages |
| **RC (Recover)** | Health check endpoint works, graceful degradation |

### 2.4 Security Headers — Quick Validation Script

```typescript
// Playwright: security-headers.spec.ts
test('security headers', async ({ page }) => {
  const response = await page.goto('/');
  const headers = response.headers();

  // Required headers (9 checks)
  expect(headers['x-frame-options']).toMatch(/DENY|SAMEORIGIN/);
  expect(headers['x-content-type-options']).toBe('nosniff');
  expect(headers['strict-transport-security']).toMatch(/max-age=\d+/);
  expect(headers['content-security-policy']).toBeTruthy();
  expect(headers['referrer-policy']).toBeTruthy();
  expect(headers['permissions-policy']).toBeTruthy();
  expect(headers['cross-origin-embedder-policy']).toBeTruthy();
  expect(headers['cross-origin-opener-policy']).toBeTruthy();
  expect(headers['cross-origin-resource-policy']).toBeTruthy();

  // Should NOT have
  expect(headers['server']).toBeUndefined(); // Don't expose server info
  expect(headers['x-powered-by']).toBeUndefined(); // Don't expose framework
});
```

### 2.5 Cookie Security Check

```typescript
test('cookie security flags', async ({ page }) => {
  await page.goto('/');
  const cookies = await page.context().cookies();
  for (const cookie of cookies) {
    if (cookie.name.match(/session|token|auth/i)) {
      expect(cookie.httpOnly).toBe(true);
      expect(cookie.secure).toBe(true);
      expect(cookie.sameSite).toMatch(/Strict|Lax/);
    }
  }
});
```

### 2.6 Hardcoded Secrets — Extended Scan

```bash
# CRITICAL: API keys and tokens
grep -rn 'sk_live_\|pk_live_\|sk_test_' src/
grep -rn 'AKIA[0-9A-Z]\{16\}' src/                    # AWS access key
grep -rn 'BEGIN RSA PRIVATE KEY\|BEGIN OPENSSH' src/    # Private keys
grep -rn 'postgres://.*:.*@\|mysql://.*:.*@' src/      # DB URLs with creds
grep -rn 'GITHUB_TOKEN\|SLACK_TOKEN\|GOOGLE_CLIENT_SECRET' src/

# HIGH: Generic secret patterns
grep -rn 'password\s*=\s*["'"'"'][^"'"'"']\+["'"'"']' src/
grep -rn 'api[_.-]*key\s*=\s*["'"'"']' src/
grep -rn 'secret[_.-]*key\s*=\s*["'"'"']' src/
grep -rn 'authorization.*Bearer.*[A-Za-z0-9_-]\{20,\}' src/

# MEDIUM: Long token heuristic (40+ chars = likely a key)
grep -rn '["'"'"'][A-Za-z0-9_-]\{40,\}["'"'"']' src/ | head -10
```

Any match in non-test, non-example files → **Critical (zero tolerance)**.

### 2.7 AI/LLM Security (if project uses AI APIs)

```bash
# Detect AI API usage
grep -rn 'openai\|anthropic\|@google/generative-ai\|claude\|gpt-' src/ --include="*.ts" --include="*.py" --include="*.js"
```

If AI APIs found, check:
- [ ] User input is sanitized before inclusion in prompts (no raw `req.body` in prompt strings)
- [ ] System prompts are not exposed to end users
- [ ] AI responses are treated as untrusted (HTML-escaped before rendering)
- [ ] Token/cost limits enforced per user/session
- [ ] No model name or API key in client-side code

```bash
# Grep for unsanitized prompt construction
grep -rn 'prompt.*req\.\|messages.*push.*req\.\|content.*req\.body' src/
# Each match must have sanitization before the AI call
```

### 2.8 JWT Validation Depth

- [ ] Algorithm explicitly restricted (not accepting `alg: none` or downgrade from RS256 to HS256)
- [ ] `exp` claim validated (reject expired tokens)
- [ ] `iss` claim validated (reject wrong issuer)
- [ ] `aud` claim validated (reject wrong audience)
- [ ] Key rotation: old keys rejected after rotation period

```bash
# Check JWT verification has algorithm restriction
grep -rn 'jwt\.verify\|jwt\.decode\|jsonwebtoken' src/ | grep -v 'algorithms:'
# Any verify() without algorithms option → P1
```

---

## Phase 3: Accessibility Audit (WCAG 2.2 AA)

### 3.1 Automated Scan (axe-core via Playwright)

```typescript
import AxeBuilder from '@axe-core/playwright';

test('WCAG 2.2 AA automated scan', async ({ page }) => {
  await page.goto('/');
  const results = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa', 'wcag22aa'])
    .analyze();
  expect(results.violations).toEqual([]);
});
```

Run on EVERY page of the application. axe-core catches ~57% of WCAG issues automatically.

### 3.2 Manual Checks (the other ~43%)

#### Perceivable (Principle 1)
- [ ] **1.1.1 Non-text Content**: Every `<img>` has meaningful `alt`. Decorative images use `alt=""`.
- [ ] **1.3.1 Info & Relationships**: Tables have `<th>`, forms have `<label>`, lists use proper `<ul>/<ol>`.
- [ ] **1.3.2 Meaningful Sequence**: Reading order (DOM order) matches visual order.
- [ ] **1.3.4 Orientation**: Content not restricted to portrait/landscape.
- [ ] **1.3.5 Identify Input Purpose**: Form fields use `autocomplete` attributes (email, name, tel, etc.).
- [ ] **1.4.1 Use of Color**: Information NOT conveyed by color alone (e.g., error = red + icon + text).
- [ ] **1.4.3 Contrast Minimum**: Text 4.5:1, large text (18px+ or 14px+ bold) 3:1.
- [ ] **1.4.4 Resize Text**: Content readable at 200% zoom without horizontal scroll.
- [ ] **1.4.10 Reflow**: At 320px width, no horizontal scrollbar.
- [ ] **1.4.11 Non-text Contrast**: UI components and graphics 3:1 against adjacent colours.
- [ ] **1.4.12 Text Spacing**: Content works with increased line-height (1.5x), letter-spacing (0.12em), word-spacing (0.16em).
- [ ] **1.4.13 Content on Hover/Focus**: Hover content is dismissible (Escape), persistent (doesn't vanish), hoverable.

#### Operable (Principle 2)
- [ ] **2.1.1 Keyboard**: ALL functionality accessible via keyboard (Tab, Enter, Space, Arrows, Escape).
- [ ] **2.1.2 No Keyboard Trap**: Can always Tab away from any element. Escape closes modals.
- [ ] **2.2.2 Pause, Stop, Hide**: Auto-playing animations/carousels have pause controls. Respects `prefers-reduced-motion`.
- [ ] **2.4.1 Skip Link**: "Skip to main content" as first focusable element.
- [ ] **2.4.2 Page Titled**: Every page has a descriptive `<title>` (not just the app name).
- [ ] **2.4.3 Focus Order**: Tab order is logical (top-to-bottom, left-to-right).
- [ ] **2.4.4 Link Purpose**: Link text describes destination (no "Click here" or bare URLs).
- [ ] **2.4.7 Focus Visible**: Every focusable element has visible focus indicator.
- [ ] **2.4.11 Focus Not Obscured (WCAG 2.2)**: Focused element not hidden by sticky headers/footers.
- [ ] **2.5.7 Dragging Movements (WCAG 2.2)**: Drag-and-drop has single-pointer alternative (button/keyboard).
- [ ] **2.5.8 Target Size Minimum (WCAG 2.2)**: Interactive targets ≥ 24x24px (44x44px recommended).

#### Understandable (Principle 3)
- [ ] **3.1.1 Language**: `<html lang="th">` or appropriate language set.
- [ ] **3.2.1 On Focus**: No unexpected context changes when an element receives focus.
- [ ] **3.2.6 Consistent Help (WCAG 2.2)**: Help/support in same relative location across pages.
- [ ] **3.3.1 Error Identification**: Form errors clearly identified with text (not colour alone).
- [ ] **3.3.2 Labels**: All form inputs have visible labels (not placeholder-only).
- [ ] **3.3.3 Error Suggestion**: Form errors provide correction guidance, not just "invalid".
- [ ] **3.3.7 Redundant Entry (WCAG 2.2)**: Don't re-ask info already provided in same flow.
- [ ] **3.3.8 Accessible Authentication (WCAG 2.2)**: No cognitive tests (CAPTCHA has alternatives).

#### Robust (Principle 4)
- [ ] **4.1.2 Name, Role, Value**: All custom UI components have ARIA roles/labels.
- [ ] **4.1.3 Status Messages**: Dynamic content announced via `aria-live` regions.

### 3.3 Heading Hierarchy Check

```bash
# Extract heading structure via Playwright
await page.evaluate(() => {
  const headings = document.querySelectorAll('h1,h2,h3,h4,h5,h6');
  headings.forEach(h => console.log(`${h.tagName}: ${h.textContent.trim()}`));
});
# Verify: one H1, no skipped levels (H1→H3 without H2 = violation)
```

### 3.4 Keyboard Navigation Test Script

```typescript
test('full keyboard navigation', async ({ page }) => {
  await page.goto('/');

  // Skip link exists and works
  await page.keyboard.press('Tab');
  const skipLink = page.locator(':focus');
  await expect(skipLink).toHaveText(/skip/i);

  // Tab through all interactive elements
  let tabCount = 0;
  while (tabCount < 100) {
    await page.keyboard.press('Tab');
    const focused = await page.evaluate(() => document.activeElement?.tagName);
    if (focused === 'BODY') break; // looped back
    tabCount++;

    // Every focused element must have visible focus indicator
    const outline = await page.evaluate(() => {
      const el = document.activeElement;
      const style = window.getComputedStyle(el);
      return style.outlineStyle !== 'none' || style.boxShadow !== 'none';
    });
    expect(outline).toBe(true);
  }
});
```

---

## Phase 4: PII & Data Exposure

### 4.1 PII Detection in Code & Logs

```bash
# PII in log statements
grep -rn 'console\.log\|println!\|log::\|logger\.' src/ | grep -i 'password\|token\|secret\|email\|phone\|id_card\|birth'

# Email addresses hardcoded in source
grep -rn '[a-zA-Z0-9._%+-]\+@[a-zA-Z0-9.-]\+\.[a-zA-Z]\{2,\}' src/ | grep -v '\.test\.\|\.spec\.\|example\.com'

# PII in API responses (test at runtime)
# curl -s http://localhost:<port>/api/users/1 -H "Authorization: Bearer $TOKEN" | grep -iE 'password|secret|id_card'
# Any PII in response that wasn't explicitly requested → P1
```

### 4.2 Data Minimization

- [ ] API responses don't include internal fields (`_id`, `password_hash`, `internal_flags`)
- [ ] Registration forms don't require unnecessary personal data
- [ ] No real user data in test/dev environments (use synthetic data)

---

## Phase 5: Code Quality Audit

### 5.1 Static Analysis

```bash
# Dependency audit
npm audit 2>/dev/null || cargo audit 2>/dev/null || pip-audit 2>/dev/null

# Check for TODO/FIXME/HACK in code
grep -rn 'TODO\|FIXME\|HACK\|XXX\|TEMP' src/ --include="*.ts" --include="*.rs" --include="*.js" --include="*.go"

# Check for console.log in production code
grep -rn 'console\.log\|console\.debug\|dbg!' src/ --include="*.ts" --include="*.rs" --include="*.js"

# Check for eval/Function (code injection risk)
grep -rn 'eval(\|new Function(\|vm\.runIn' src/ --include="*.ts" --include="*.js"

# Hardcoded secrets → see Phase 2.6 for extended scan
```

**Stack-specific linters** (run whichever applies):
```bash
# TypeScript/JavaScript
npx eslint . --format=json 2>/dev/null | head -50
npx tsc --noEmit 2>&1 | tail -20

# Go
golangci-lint run ./... 2>/dev/null

# Rust
cargo clippy --all-targets -- -D warnings 2>/dev/null

# Python
pylint src/ --disable=all --enable=E,F,W 2>/dev/null
mypy src/ --strict 2>/dev/null
```

### 5.2 Code Quality Metrics

| Metric | Target | Reject | How to Measure |
|--------|--------|--------|----------------|
| Cyclomatic complexity | ≤10 per function | >20 | JS: `npx complexity-checker src/` / Go: `gocyclo -over 10 ./...` |
| Code coverage (unit) | ≥80% | <60% | JS: `npx c8 report` / Go: `go test -cover ./...` / Rust: `cargo tarpaulin` |
| Code coverage (critical paths) | ≥90% | <70% | Same tools, filter to critical dirs |
| Code duplication | <3% | >5% | `npx jscpd src/` |
| Max function length | ≤50 lines | >100 lines | grep + line count |
| Max file length | ≤500 lines | >1000 lines | `wc -l src/**/*.ts \| sort -rn \| head` |

### 5.3 Type Safety (TypeScript projects)

```bash
# Count `any` usage (target: 0 in non-test files)
grep -rn '\bany\b' src/ --include="*.ts" --include="*.tsx" | grep -v '\.test\.\|\.spec\.' | wc -l

# Count `as any` casts (each must have a justification comment)
grep -rn ' as any' src/ --include="*.ts" --include="*.tsx" | grep -v '\.test\.'

# Verify tsconfig strict mode
grep '"strict"' tsconfig.json  # must be true
```

### 5.4 Test Coverage for Changed Code

```bash
# What source files changed?
CHANGED=$(git diff main --name-only -- 'src/' 'app/' 'components/' 'backend/' 'frontend/src/')

# Verify changed files have tests
for f in $CHANGED; do
  test_file=$(echo "$f" | sed 's/\.ts$/.test.ts/; s/\.tsx$/.test.tsx/')
  if [ ! -f "$test_file" ]; then
    echo "P2: $f changed but no test file at $test_file"
  fi
done

# Forbid skipped tests
grep -rn 'describe\.skip\|it\.skip\|xit\|xdescribe\|test\.skip' test/ src/ 2>/dev/null
# Any match → P2 (must unskip or remove)
```

### 5.5 Dead Code & Circular Dependencies

```bash
# Circular dependency detection (JS/TS)
npx madge --circular --extensions ts,tsx src/ 2>/dev/null
# Any circular → P2

# Unused exports (JS/TS)
npx unimported 2>/dev/null | head -20
```

### 5.6 Error Handling Consistency

```bash
# Empty catch blocks (silent error suppression) → P1
grep -rn 'catch\s*(.*)\s*{\s*}' src/ --include="*.ts" --include="*.js"

# Catch-and-log-only (no rethrow or handling) → P2
grep -rn 'catch.*{' src/ -A2 | grep -B1 'console\.\(log\|warn\)' | grep -v 'throw\|return\|reject'

# Inconsistent error response shapes → P2
grep -rn 'res\.status\|res\.json.*error\|res\.json.*message' src/ | head -20
# All error responses should use the same shape: { error: string, code: string }
```

### 5.7 API Quality

- [ ] All endpoints return consistent error format `{ error: string, code: string }`
- [ ] HTTP status codes used correctly (200, 201, 400, 401, 403, 404, 500)
- [ ] API versioning in place (or documented as intentionally unversioned)
- [ ] Request validation on all POST/PUT/PATCH endpoints
- [ ] Response doesn't include internal fields (`_id`, `password_hash`, internal flags)
- [ ] Rate limiting headers present on protected endpoints (`X-RateLimit-Remaining`, `Retry-After`)

---

## Phase 6: Performance Audit

### 6.1 Core Web Vitals (Lighthouse via Playwright)

```bash
# Run Lighthouse via Playwright
npx playwright test --project=lighthouse
```

| Metric | Good | Needs Improvement | Poor |
|--------|------|-------------------|------|
| LCP (Largest Contentful Paint) | ≤2.5s | ≤4.0s | >4.0s |
| INP (Interaction to Next Paint) | ≤200ms | ≤500ms | >500ms |
| CLS (Cumulative Layout Shift) | ≤0.1 | ≤0.25 | >0.25 |
| FCP (First Contentful Paint) | ≤1.8s | ≤3.0s | >3.0s |
| TTFB (Time to First Byte) | ≤200ms | ≤600ms | >600ms |
| TBT (Total Blocking Time) | ≤200ms | ≤600ms | >600ms |

Target: Lighthouse Performance score ≥90.

### 6.2 Bundle & Load

- [ ] No unnecessary large dependencies in client bundle
- [ ] Images optimized (WebP/AVIF preferred, lazy-loaded below fold)
- [ ] Fonts loaded efficiently (font-display: swap)
- [ ] Initial JS bundle <200KB (gzipped)
- [ ] API responses <500ms (p95)
- [ ] Cache-Control headers set on static assets
- [ ] Compression enabled (gzip/brotli on responses)

### 6.3 Memory & Runtime (frontend)

- [ ] No detached DOM nodes (navigate away and back — heap should not grow indefinitely)
- [ ] No event listener leaks: `addEventListener` paired with `removeEventListener` in cleanup/unmount
- [ ] No memory leaks from intervals/timeouts: `setInterval`/`setTimeout` cleared on component unmount
  ```bash
  grep -rn 'setInterval\|setTimeout' src/ --include="*.tsx" --include="*.ts" | grep -v 'clearInterval\|clearTimeout\|useEffect'
  # Matches without cleanup pairing → P2
  ```

---

## Phase 6.5: Pre-Launch & Observability Gate

**Applies to:** All production deployments. Run BEFORE `maw pr` for release-facing changes.

### 6.5.1 Observability Verification (AUTOMATED)

For any feature that adds endpoints, background jobs, or external integrations. Run these grep checks against changed files:

```bash
# Detect new endpoints/handlers in the diff
CHANGED=$(git diff --name-only HEAD~1 | grep -iE '\.(ts|js|py|go|rs|rb)$')

# 1. Structured logging — must use object/structured form, not string interpolation
echo "--- Structured logging check ---"
for f in $CHANGED; do
  # Flag: console.log with template literals or string concat in route/handler files
  grep -nE 'console\.(log|info|warn|error)\s*\(' "$f" 2>/dev/null | grep -E '`\$\{|" \+|'"'"' \+' && echo "P2: $f — use structured logger, not console.log with interpolation"
done

# 2. Secrets in logs — scan for accidental logging of sensitive vars
echo "--- Secrets-in-logs check ---"
for f in $CHANGED; do
  grep -nEi '(log|print|console)\b.*\b(password|secret|token|api_key|apikey|credentials|auth_token)\b' "$f" 2>/dev/null && echo "P1: $f — potential secret in log output"
done

# 3. console.log debugging — no bare console.log in production code
echo "--- Debug console.log check ---"
for f in $CHANGED; do
  grep -nE '^\s*console\.log\(' "$f" 2>/dev/null && echo "P2: $f — remove debug console.log before shipping"
done

# 4. TODO/FIXME in shipped code
echo "--- TODO/FIXME check ---"
for f in $CHANGED; do
  grep -nEi '\b(TODO|FIXME|HACK|XXX)\b' "$f" 2>/dev/null && echo "P2: $f — resolve or remove before shipping"
done
```

Checklist (verify after automated scan):
- [ ] **Structured logging present:** JSON with stable event names, not string interpolation
- [ ] **Correlation IDs:** Request ID generated/accepted at boundary and attached to every log line
- [ ] **RED metrics** for new endpoints: Rate, Errors, Duration (p50/p95/p99)
- [ ] **No secrets in logs:** Automated scan clean + manual spot-check
- [ ] **Alerting rules** for user-facing symptoms (error rate, p99 latency), not causes (CPU, memory)

**Severity:** P1 if secrets-in-logs found. P2 for other failures. Skip for frontend-only changes.

### 6.5.2 Pre-Launch Checklist

For release-facing deployments (not every PR — only when preparing to ship):

**Code Quality:**
- [ ] All tests pass (unit, integration, e2e)
- [ ] Build succeeds with no warnings
- [ ] Lint and type checking pass
- [ ] No TODO comments that should be resolved before launch
- [ ] No `console.log` debugging in production code

**Infrastructure:**
- [ ] Environment variables set in production
- [ ] Database migrations applied (or ready)
- [ ] Health check endpoint exists and responds
- [ ] Logging and error reporting configured

**Rollback Strategy:**
- [ ] Feature flag configured (if applicable) — kill switch ready
- [ ] Rollback plan documented (trigger conditions + steps)
- [ ] Time-to-rollback estimated: feature flag <1 min, redeploy <5 min, DB rollback <15 min

### 6.5.3 Rollout Decision Thresholds

After deployment, monitor and use these thresholds to decide next action:

| Metric | Advance (green) | Hold (yellow) | Roll back (red) |
|--------|-----------------|---------------|-----------------|
| Error rate | Within 10% of baseline | 10-100% above baseline | >2x baseline |
| P95 latency | Within 20% of baseline | 20-50% above baseline | >50% above baseline |
| Client JS errors | No new error types | New errors at <0.1% sessions | New errors at >0.1% sessions |
| Business metrics | Neutral or positive | Decline <5% | Decline >5% |

**Roll back immediately if:** error rate >2x baseline, p95 latency >50% above, user-reported issue spike, data integrity issues, or security vulnerability discovered.

> **Quality backbone reference:** See `addy/shipping-and-launch` for full staged rollout sequence and `addy/observability-and-instrumentation` for RED/USE metrics, structured logging, and alerting rules.

---

## Phase 7: Database & Data Integrity (ALCOA+)

### 7.1 Schema Checks (via bme-mssql MCP)

```sql
-- Audit trail columns exist
SELECT TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME IN ('created_by', 'modified_by', 'created_at', 'modified_at', 'deleted_at')
ORDER BY TABLE_NAME;

-- FK constraints enforced
SELECT fk.name, OBJECT_NAME(fk.parent_object_id) AS child, OBJECT_NAME(fk.referenced_object_id) AS parent
FROM sys.foreign_keys fk;

-- NOT NULL on critical fields
SELECT TABLE_NAME, COLUMN_NAME, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE IS_NULLABLE = 'YES' AND COLUMN_NAME IN ('created_by', 'status', 'amount', 'quantity');
```

### 7.2 ALCOA+ Checklist

- [ ] **Attributable**: `created_by`, `modified_by` on all transactional tables
- [ ] **Legible**: Data readable, no encoding issues, correct character set
- [ ] **Contemporaneous**: Timestamps server-generated (`GETDATE()` / `NOW()`), not client-supplied
- [ ] **Original**: Modifications create audit trail (trigger or application-level logging)
- [ ] **Accurate**: Input validation enforced (type, range, required constraints)
- [ ] **Complete**: No orphaned records, FK constraints enforced, `NOT NULL` on critical fields
- [ ] **Consistent**: Same data format across related tables
- [ ] **Enduring**: Records retrievable for required retention period
- [ ] **Available**: Data accessible to authorized users when needed

### 7.3 Migration Safety (if schema changes in this PR)

```bash
# Check if migrations exist in the diff
MIGRATIONS=$(git diff main --name-only -- 'migrations/' 'supabase/migrations/' 'migration/' 'db/migrate/')
if [ -n "$MIGRATIONS" ]; then
  echo "Schema migrations detected — running safety checks"
fi
```

If migrations found, verify:
- [ ] **Forward migration works**: apply migration to clean DB → no errors
- [ ] **Rollback exists**: down migration or revert script present
- [ ] **Idempotent**: running migration twice doesn't error (use `IF NOT EXISTS`, `CREATE OR ALTER`)
- [ ] **Data-safe**: if altering columns, existing data is preserved or migrated (no silent truncation)
- [ ] **No destructive DDL without backup**: `DROP TABLE`, `DROP COLUMN` must have data backup step documented

---

## Phase 7.5: Doc-Sync Alignment (CMMI L3)

*(Tailoring 2026-06-05: docs sync in batch at stabilization via `/doc-sync`, NOT per-PR. The per-PR obligation is one `REQ:` line in the PR description. See `/sop-cmmi` §2–3.)*

### 7.5.1 Per-PR check — the REQ line (every feature PR)

```bash
# The PR description MUST carry exactly one REQ line:
#   REQ: REQ-<PROJECT>-NNN[, REQ-<PROJECT>-MMM]   — requirement(s) this PR touches
#   REQ: none                                      — refactor/cosmetic/no-contract change
gh pr view --json body --jq .body | grep -E '^REQ: (REQ-[A-Z]+-[0-9]+(, *REQ-[A-Z]+-[0-9]+)*|none)$' \
  || echo "P2: PR description missing its REQ: line — traceability thread broken"

# Feature PRs MUST NOT edit docs/ — doc edits belong to /doc-sync PRs only
CODE_CHANGED=$(git diff main --name-only -- 'src/' 'app/' 'api/' 'components/' 'backend/' 'frontend/src/' | head -20)
DOCS_CHANGED=$(git diff main --name-only -- 'docs/' | head -20)
[ -n "$CODE_CHANGED" ] && [ -n "$DOCS_CHANGED" ] \
  && echo "P2: feature PR edits docs/ — move doc changes to the next /doc-sync batch"

# Check if docs/ directory even exists
[ ! -d "docs" ] && echo "P2: No docs/ directory — run init-project-docs.sh to scaffold"
```

### 7.5.2 Release gate — doc-sync freshness (P1, blocks UAT/release/deploy)

When this audit gates a UAT session, release, or deploy (NOT an ordinary feature PR):

```bash
# docs/.last-doc-sync holds the SHA of the last /doc-sync run.
MARKER=$(cat docs/.last-doc-sync 2>/dev/null)
if [ -z "$MARKER" ]; then
  echo "P1: no doc-sync marker — run /doc-sync before UAT/release"
else
  UNSYNCED=$(git log "$MARKER"..main --merges --oneline | wc -l)
  [ "$UNSYNCED" -gt 0 ] \
    && echo "P1: $UNSYNCED merged PR(s) behind the doc-sync marker — run /doc-sync before UAT/release"
fi
```

### 7.5.3 Exemptions (`REQ: none` is correct for)

- Pure refactors (same behavior, different structure)
- Dependency bumps with no API change
- Test-only changes · Config/CI changes
- README-only · cosmetic rerenders (CSS/copy with no behavior change)
- Files under `ψ/`, `.claude/`, `scripts/`

### 7.5.4b Traceability validation (REQ-id) — on /doc-sync PRs and release audits

The 7-doc standard collapses RTM into the UAT REQ-id column. Verify it is actually filled — a UAT table with empty/missing REQ-id columns is doc drift in disguise:

```bash
# Every UAT.md test-case row MUST cite a REQ-id (REQ-<PROJECT>-NNN). Find rows that don't.
if [ -f docs/UAT.md ]; then
  awk -F'|' '/^\|/ && $0 !~ /REQ-[A-Z]+-[0-9]/ && $0 !~ /REQ.?id/i && $0 !~ /^\|[-: ]+\|/ {print NR": "$0}' docs/UAT.md \
    | grep -vE 'Test (Case|ID)|Description|Expected' \
    && echo "P1: UAT.md has test rows with no REQ-id — traceability broken"
fi
# Every CR.md change row should reference the REQ it touches.
if [ -f docs/CR.md ]; then
  grep -E '^\|' docs/CR.md | grep -vE 'REQ-[A-Z]+-[0-9]|REQ.?id|^\|[-: ]+\||CR-id|Date|Status' \
    && echo "P2: CR.md rows without a REQ reference — link each change to its requirement"
fi
```

A NEW REQ in SRS.md MUST appear (same id) in a UAT.md row — a REQ present in SRS but absent in UAT is **P1**. (SDD is a generated snapshot — it is NOT part of the per-REQ trace.)

### 7.5.5 G4 — PR Scope vs SRS (per-PR gate)

Validate that the files changed in this PR are consistent with the requirements cited in its `REQ:` line. A PR claiming `REQ: REQ-BME-001` (label printing) but modifying auth middleware is a scope leak — either the REQ line is wrong or the change is out of scope.

```bash
# 1. Extract REQ-ids from PR description
REQS=$(gh pr view --json body --jq .body 2>/dev/null | grep -oE 'REQ-[A-Z]+-[0-9]+' | sort -u)
[ -z "$REQS" ] && { echo "⊘ G4: no REQ-ids in PR (REQ: none or missing) — skip scope check"; }

# 2. Gather in-scope modules from SRS (convention: Module column in the REQ table)
if [ -n "$REQS" ] && [ -f docs/SRS.md ]; then
  SCOPE_PATTERNS=""
  for req in $REQS; do
    module=$(grep "$req" docs/SRS.md 2>/dev/null | awk -F'|' '{print $3}' | tr -d ' ')
    [ -n "$module" ] && SCOPE_PATTERNS="$SCOPE_PATTERNS|$module"
  done

  # 3. Check changed files against declared scope
  if [ -n "$SCOPE_PATTERNS" ]; then
    SCOPE_PATTERNS="${SCOPE_PATTERNS#|}"  # trim leading pipe
    OUT_OF_SCOPE=$(git diff main --name-only | grep -ivE "$SCOPE_PATTERNS" \
      | grep -vE '^(docs/|scripts/|\.claude/|ψ/|CLAUDE\.md|AGENTS\.md)')
    [ -n "$OUT_OF_SCOPE" ] \
      && echo "P2: files outside declared REQ scope: $OUT_OF_SCOPE"
  fi
fi
```

**Verdict**: files outside the declared REQ scope → **P2** (warn — either update the REQ line or justify the cross-module change in the PR description). Not blocking, since legitimate cross-cutting changes exist (shared types, migrations, config).

### 7.5.6 Verdict

- **Feature PR + REQ line present + no docs/ edits** → PASS
- **Feature PR missing its REQ line** → P2 (warn, add the line)
- **Feature PR editing docs/** → P2 (warn, move to /doc-sync)
- **UAT/release audit + marker current** → PASS
- **UAT/release audit + marker missing/behind** → P1 (BLOCKS — run /doc-sync)
- **No docs/ directory in project** → P2 (warn, suggest scaffold)

### 7.5.7 Remediation — `/doc-sync` on CHEAP PARALLEL agents

A P1 sync-gap never burns the main model. Run `/doc-sync`: it reads merged PRs since the marker, swarms **haiku-4.5** subagents (one per doc — SRS/UAT/CR/RISK/UXUI), lands ONE docs-only PR (low-risk → self-merge), and advances `docs/.last-doc-sync`. Deltas are append/patch only (Nothing is Deleted): each REQ stated ONCE in SRS, cited in a UAT row. Re-run 7.5.2/7.5.4b after to confirm the gap closed.

---

## Phase 8: Report Generation

### 8.1 Verdict Decision Matrix

| Findings | Verdict |
|----------|---------|
| 0 Critical, 0 Major | PASS |
| 0 Critical, Major exists | CONDITIONAL PASS (fix before deploy) |
| ANY Critical | FAIL (blocks release) |
| App not running | BLOCKED |

### 8.2 Report Template

```markdown
## QA + Compliance Audit Report

**Date**: [ISO 8601]
**Project**: [name]
**Artifact**: [PR/branch/version]
**Auditor**: [Your Oracle Name] (self-QA)
**Standards Checked**: [list all that apply]

---

### OVERALL VERDICT: [PASS / CONDITIONAL PASS / FAIL / BLOCKED]

| Standard | Verdict | Critical | Major | Minor | Observation |
|----------|---------|----------|-------|-------|-------------|
| Live Testing | [P/F] | [n] | [n] | [n] | [n] |
| Integration Tests | [P/F] | [n] | [n] | [n] | [n] |
| OWASP 2025 | [P/F] | [n] | [n] | [n] | [n] |
| CWE Top 25 | [P/F] | [n] | [n] | [n] | [n] |
| AI/LLM Security | [P/F] | [n] | [n] | [n] | [n] |
| WCAG 2.2 AA | [P/F] | [n] | [n] | [n] | [n] |
| PII & Data | [P/F] | [n] | [n] | [n] | [n] |
| Code Quality | [P/F] | [n] | [n] | [n] | [n] |
| Error Handling | [P/F] | [n] | [n] | [n] | [n] |
| Performance | [P/F] | [n] | [n] | [n] | [n] |
| ALCOA+ | [P/F] | [n] | [n] | [n] | [n] |
| Migration Safety | [P/F] | [n] | [n] | [n] | [n] |
| Doc Alignment | [P/F] | [n] | [n] | [n] | [n] |

---

### ZERO TOLERANCE VIOLATIONS
[List any zero-tolerance items or "None found"]

### VIOLATIONS

#### [STANDARD] [Severity: Critical/Major/Minor]
**Clause**: [specific reference]
**Finding**: [what was found]
**Evidence**: [file:line, screenshot, curl output]
**Required Fix**: [what must change]
**How to Fix**: [concrete guidance]
**Auto-Fix Available**: [command if applicable, e.g. `npx eslint --fix`, `npm audit fix`]

---

### RELEASE BLOCKERS
**Immediate** (must fix before merge):
- [ ] [item]

**Before Next Audit**:
- [ ] [item]

---

### HANDOFF
**To [Developer Oracle]**: [specific tasks with evidence]
**To Gale**: [summary for Wind]
```

### 8.3 Communication Templates

```bash
# PASS — post QA report on PR, then create PR
gh pr comment [PR-URL] --body "## Dev QA Report — PASS
[full report]
**Auditor**: [Your Name] (self-QA)"

# FAIL — fix in same branch, re-run /sop-qa, loop until PASS
# Do NOT create PR until /sop-qa passes.
```

---

## Parallel Agent Strategy

For full audits, spawn up to 3 agents in parallel:

```
Agent 1: Security (OWASP + CWE + headers + secrets + AI/LLM + JWT + supply chain)
Agent 2: Accessibility + UX (WCAG 2.2 AA + keyboard + contrast + ARIA + integration tests)
Agent 3: Code Quality + Data (PII scan + type safety + error handling + dead code + ALCOA+ + migration safety + doc alignment)
```

Main thread: Live testing (Phase 1) + UX/UI (Phase 1.5) + Performance (Phase 6) + Pre-Launch & Observability (Phase 6.5, if deploying) + Report assembly (Phase 8).

Merge all agent results into one unified report.

---

## Zero Tolerance List (ALWAYS Critical)

These findings ALWAYS block release:

1. Hardcoded secrets, credentials, or API keys in code
2. Missing authentication on endpoints that access user data
3. SQL injection or XSS vulnerabilities (unparameterized queries)
4. WCAG 2.2 Level A failures on public-facing interfaces
5. Undocumented breaking API changes
6. Missing error handling that silently swallows failures
7. PII exposed in application logs or API responses
8. Authentication endpoint broken (not returning 200 + token)
9. No HTTPS enforcement
10. Open redirect vulnerabilities
11. AI/LLM prompt injection (unsanitized user input in prompts)
12. Insecure deserialization of untrusted data (eval, pickle, unserialize)
13. JWT without algorithm restriction (accepts alg:none)
14. UAT/release with `docs/.last-doc-sync` missing or behind merged feature PRs (doc drift — Phase 7.5 release gate)

---

## NWFTH Legacy Exceptions (Wind-Approved)

- Hard DELETE of inventory records is ALLOWED (BME projects)
- FDA 21 CFR Part 11 does NOT apply (NWFTH = food manufacturer)
- ALCOA+ Enduring: BinTransfer audit trail is sufficient for BME projects
- Test server: localhost ONLY. NEVER remote/production.

---

> "The shell is not cruelty. It is care made rigid. What passes through the shell is worth trusting."
