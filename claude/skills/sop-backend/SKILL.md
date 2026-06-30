---
name: sop-backend
description: 'Backend auth policy and coding standards — centralized policy, fail-closed, stack-specific standards detected from the repo (Rust shown as one example). Triggers: "auth policy", "backend rules", "rust standards".'
---
# /sop-backend — Backend Auth Policy & Coding Standards

## Auth Policy (MANDATORY for any backend with user roles or workflow actions)

Every backend that has user roles or workflow actions MUST follow these rules:

1. **One centralized policy module** — all auth checks (edit, submit, transition, sign, upload, delete) go through ONE function/package. No scattered `if role == X` checks in handlers.
2. **Fail closed** — unmapped/empty-role users get ZERO permissions. `DEFAULT_USER_ROLES` must be empty or absent. No fallback to a real role.
3. **Owner checks** — form/resource creator (created_by) is the ONLY user who can do requestor-level actions (submit, requestor signoff). Role alone is not enough.
4. **Regression tests** — every project with auth MUST have unit tests proving:
   - Empty-role user cannot: create, edit, submit, transition, sign, upload, or delete
   - Each role can ONLY do what the workflow spec allows, nothing more
   - These tests run in `go test` / `npm test` and block PR merge on failure

**Why this rule exists**: NPD Forms PR #2 failed review three times because auth checks were added incrementally — edit was hardened but submit/signoff still allowed unmapped users. Centralized policy + regression tests prevent piecemeal gaps.

## API Design Standards

### Contract First

Define the interface before implementing. The types ARE the spec.

```typescript
// Define the contract first
interface TaskAPI {
  createTask(input: CreateTaskInput): Promise<Task>;
  listTasks(params: ListTasksParams): Promise<PaginatedResult<Task>>;
  getTask(id: string): Promise<Task>;
  updateTask(id: string, input: UpdateTaskInput): Promise<Task>;
  deleteTask(id: string): Promise<void>;
}
```

### Consistent Error Semantics

Pick one error strategy and use it everywhere:

```typescript
interface APIError {
  error: {
    code: string;        // Machine-readable: "VALIDATION_ERROR"
    message: string;     // Human-readable: "Email is required"
    details?: unknown;
  };
}

// Status codes: 400 invalid, 401 unauth, 403 forbidden, 404 not found, 409 conflict, 422 validation, 500 server
```

### Validate at Boundaries Only

Trust internal code. Validate at system edges where external input enters:

- API route handlers (user input)
- Form submission handlers
- External service response parsing (third-party data — ALWAYS untrusted)
- Environment variable loading

Do NOT validate between internal functions that share type contracts.

### API Design Rules

| Pattern | Convention |
|---------|-----------|
| REST endpoints | Plural nouns, no verbs: `GET /api/tasks`, not `/api/getTask` |
| List endpoints | ALWAYS paginate — no unbounded queries |
| Updates | PATCH for partial, PUT for full replacement |
| Naming | camelCase fields, is/has/can for booleans, UPPER_SNAKE for enums |
| Versioning | Prefer addition over modification — new optional fields, never break existing |

**Hyrum's Law:** Every observable behavior becomes a de facto contract. Design implications: be intentional about what you expose, don't leak implementation details, plan for deprecation at design time.

---

## Security — STRIDE Threat Model

Before any feature touching user data, spend 5 minutes thinking like an attacker:

| Threat | Ask | Typical mitigation |
|---|---|---|
| **S**poofing | Can someone impersonate a user/service? | Authentication, signature verification |
| **T**ampering | Can data be altered in transit/at rest? | Integrity checks, parameterized queries, HTTPS |
| **R**epudiation | Can an action be denied later? | Audit logging of security events |
| **I**nfo disclosure | Can data leak? | Encryption, field allowlists, generic errors |
| **D**enial of service | Can it be overwhelmed? | Rate limiting, input size caps, timeouts |
| **E**levation of privilege | Can a user gain unauthorized rights? | Authorization checks, least privilege |

### LLM/AI Security

If the app calls an LLM — treat ALL model output as untrusted input:

- **Never** pass LLM output into `eval`, SQL, a shell, `innerHTML`, or a file path
- **Never** put secrets or cross-tenant data in prompts (the model can echo them)
- Constrain tool/agent permissions — require confirmation for destructive actions
- Bound token rate and loop/recursion depth

### SSRF Prevention

Any time the server fetches a URL the user influenced (webhooks, imports, link previews):

- Allowlist scheme + host
- Resolve ALL DNS records and reject if ANY resolved IP is private/reserved
- Forbid redirects (`{ redirect: 'error' }`)
- Use read-only sandbox for the request if possible

### Supply-Chain Hygiene

- Commit the lockfile; install with `npm ci` in CI (not `npm install`)
- Review new dependencies before adding (maintenance, downloads, postinstall scripts)
- Watch for typosquats (`cross-env` vs `crossenv`)
- Every dependency is attack surface

> **Quality backbone reference:** See `addy/api-and-interface-design` for full patterns (Hyrum's Law, branded types, discriminated unions) and `addy/security-and-hardening` for OWASP prevention with code examples.

---

## Coding Standards (stack-detected)

Detect the stack from the repo (`Cargo.toml`, `package.json`, `go.mod`, `requirements.txt`…) and apply its idiomatic conventions. Rust is shown below as one worked example; other stacks load their own (Go, Node/TS, Python). Always check the repo before assuming a language.

### Rust (activated for Rust codebases)

**Context7 Rule**: ALWAYS use `context7` MCP to retrieve latest docs before writing code for any external crate.

Borrowing over cloning | `Cow<'a, T>` | New Type Pattern | Enums for state machines | `anyhow`/`thiserror` (never `.unwrap()`) | `tokio` | `polars` lazy eval | minimal `main.rs`

## Post-Work Routing (MANDATORY)

After backend changes are committed and PR is created:
1. Run `/sop-qa --security` (self-QA with security focus)
2. Fix until PASS → `maw pr` → `gh pr comment` (QA report)
3. Report to Gale: `maw hey wind:gale "[<my-name>] DONE: PR #N. Self-QA passed."`

**Do NOT sit idle after pushing.** Full QA flow: `/sop-qa`.
