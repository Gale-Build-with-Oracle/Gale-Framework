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
