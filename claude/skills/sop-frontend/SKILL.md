---
name: sop-frontend
description: 'UX/UI rules — responsive, a11y, tables, forms, dashboards — plus an Impeccable-inspired design-refinement toolkit (context, detector, shape/craft, audit/critique, bolder/quieter, layout/typeset, harden/polish). Use for any frontend/UI work.'
---
# /sop-frontend — UX/UI Design Rules

MANDATORY for any frontend work across all projects.

**Baseline**: Desktop-first 1920x1080. Responsive target: tablet landscape (1024-1280px). Touch targets >=44x44px.

- **Tables**: 50 rows/page default, sorting + filter + search + "X of Y" count. Sticky header. Skeleton loading. Empty state with action.
- **Forms**: <6 opts=radio, 6-15=Select, >15=Combobox. Inline validation on blur. Visible labels, `*` for required. Disable submit on click, spinner inside.
- **Dashboard**: F-pattern. KPI cards top (max 7), charts mid, tables bottom. Left sidebar nav. Full 1920px width.
- **Color**: Semantic only (green/yellow/red/blue/gray). Badges = color + label text.
- **Interaction**: Skeleton for loads, inline spinners for actions. Toasts: success=3s, error=persist. `<AlertDialog>` not `window.confirm()`.
- **A11y**: alt on img, aria-label on icon buttons, linked labels, 4.5:1 contrast, logical focus order, skip link.
- **NEVER**: Ship without empty/loading/error states. Hardcode colors. Tables without search+sort. Placeholder-as-label. Elements <44x44px.

## Project Theming

Before writing any UI code, load the correct brand/theme skill:
- NWFTH projects -> `/nwf-theme`
- Solution Lab projects -> `/sl-theme`
- Clinic / healthcare (YD Wellness) projects -> `/doctor-theme`
- No brand skill for the project? Gather brand context first (personality, palette, logo, audience) — never invent a brand silently.

**Brand/theme skill boundary:** `/nwf-theme` and `/sl-theme` should stay broad — logo assets, official color anchors, and minimal brand text/conventions only. Do **not** push layout, component, token, typography, table/form/dashboard, animation, or "impeccable" design prescriptions into those theme skills. All UI/UX decisions and implementation quality belong here in `/sop-frontend` plus the target project's own design source of truth.

## Impeccable-Inspired Operating Model

Source learned: <https://impeccable.style/docs/> and `pbakaus/impeccable` npm package/README. Use this as our local `/sop-frontend` vocabulary; do **not** require installing Impeccable unless the repo already uses it or Wind asks.

1. **Context first** — before design changes, inspect the repo for tokens/components/theme and read `PRODUCT.md`, `DESIGN.md`, brand skills, or existing UI patterns. New work must inherit the system, not invent a model-default style.
2. **Register matters** — product UI, dashboards, admin tools, landing pages, healthcare, ERP, and mobile/tablet operations need different defaults. Decide the register explicitly before applying "bolder" or "delight".
3. **Detector mindset** — block visible AI tells and measurable UI defects before shipping. If Node 24+ and network/install are available, run `npx impeccable detect src/` or `npx impeccable detect --json src/` as an extra signal; exit code `2` means findings, not tool failure. For live pages, `npx impeccable detect https://...` may need Puppeteer.
4. **Two-lane review** — **Audit** = technical/measurable (a11y, performance, responsive, theming, anti-patterns). **Critique** = design judgment (Nielsen heuristics, persona fit, cognitive load, emotional journey, slop verdict). Use both when quality matters.
5. **Useful pairs** — `shape → craft`, `audit → harden`, `critique → polish`, `bolder ↔ quieter`. Start with the diagnostic pair, then apply the minimum refinement moves needed.
6. **Live iteration** — for visual polish on an existing element, prefer browser-visible iteration: run the app, screenshot/inspect the real page, generate 2-3 variants, accept only with reviewed diffs. Impeccable Live Mode does this directly where installed; otherwise imitate the workflow manually.

## Design Refinement Toolkit

This toolkit absorbs Impeccable's command vocabulary into one place. Reach for it when a UI is functionally done but not *good* — too boring, too loud, cluttered, slow, off-brand, fragile, or unaudited. Each subsection is a self-contained move: when to use it + the concrete checklist. Don't run them all — diagnose first (use **Audit** / **Critique** / **UI-Review**), then apply the 2-3 moves that match the finding, run **Harden** for production edge cases, and finish with **Polish**.

**Universal guardrails for every move**:
- Avoid AI-slop tells: cyan/purple gradients, gradient text on metrics/headings, glassmorphism, neon-on-dark glows, thick side-tab accent borders, nested cards, identical icon-tile+heading+text grids, hero eyebrow pill clichés, oversized italic serif hero clichés, 01/02/03 section markers by reflex, cream/beige "tasteful" default surfaces, generic fonts by reflex (Inter/Roboto/Open Sans/Geist/Space Grotesk/Plus Jakarta Sans), decorative hero-metric layouts with fake numbers, marketing buzzwords (`streamline`, `empower`, `supercharge`, `world-class`, `cutting-edge`).
- Never break WCAG AA (4.5:1 body text, 3:1 large/non-text/UI), never remove focus indicators, always respect `prefers-reduced-motion`.
- Tinted neutrals over pure gray/black/white. Never gray text on colored backgrounds — use a darker shade of that color, white/near-white, or transparency with verified contrast.
- Gather context first: brand personality, audience, purpose, product register, design tokens, component variants, anti-references. If unclear and it changes the design, ask.

### Quick Reference — intent → moves

| You see / want | Reach for |
|---|---|
| Boring, flat, safe, underwhelming | **Bolder** + **Colorize** (+ **Typeset**) |
| Too monochrome / gray / cold | **Colorize** |
| Loud, aggressive, overstimulating | **Quieter** |
| Cluttered, too many elements, overload | **Distill** (+ **Quieter**) |
| Weak hierarchy, bad spacing/rhythm, card-grid monotony | **Layout** (formerly Arrange) |
| Generic / muddy text, weak font hierarchy | **Typeset** |
| Needs motion, feedback, life | **Animate** |
| Wants joy / personality / surprise | **Delight** |
| Technically ambitious "wow" (shaders, physics, 60fps) | **Overdrive** |
| Drifted from design system | **Normalize** |
| Reusable patterns scattered | **Extract** |
| Slow / janky / heavy | **Optimize** |
| Doesn't fit a device/context | **Adapt** |
| Confusing copy / labels / errors | **Clarify** |
| Confusing first-run / empty states | **Onboard** |
| Production fragility: edge cases, overflow, i18n, permissions, bad networks | **Harden** |
| Planning a feature before code | **Shape** |
| Quality check / second opinion | **Audit** (technical) + **Critique** (design) + **UI-Review** (principal) |
| Final pass before shipping | **Polish** |

---

### Amplify cluster — make it bolder, colorful, delightful

#### Bolder
Use when a design is too safe/generic — system fonts, medium-everything scale, flat hierarchy, no focal point. Moves: pick ONE hero moment and amplify only it; increase *contrast* (big things 3-5x bigger, small things smaller), pair weight 900 with 200; swap generic fonts for distinctive ones; let one bold color own ~60%; break the grid / go asymmetric / full-bleed for the hero; dramatic soft shadows, intentional textures (grain/noise/duotone — never glassmorphism). The test: if someone says "AI made this bolder" and you'd believe them, you failed — bold = distinctive, not "more effects." Keep body text readable, keep WCAG.

#### Colorize
Use when monochrome/gray/cold or color carries no meaning. Pick 2-4 colors beyond neutrals; assign 60/30/10 (dominant/secondary/accent). Apply with purpose: semantic states (green=success, red=error, amber=warning, blue=info), primary CTAs, links, status badges, accent borders, colored focus rings, data viz. Replace pure `#f5f5f5` gray with tinted neutrals (warm/cool, ~0.01 chroma); use OKLCH for harmonious scales. Never rainbow-vomit, never color-as-only-indicator, never gray-on-color, never purple-blue gradient.

#### Delight
Use to add joy/personality where it fits the brand (banks warm, not wacky). Target natural moments only: success/empty/loading states, milestones, hovers, softening errors, easter eggs. Rules: delight is <1s, skippable, never blocks core function, varies on repeat, matches the emotional moment. Moves: satisfying button press/hover micro-motion, drawn checkmarks/confetti for real milestones, product-specific (not generic-AI) loading copy, custom empty-state illustrations, tasteful seasonal/time-of-day touches, console/alt-text easter eggs. Respect reduced motion; don't make *every* interaction special.

---

### Calm cluster — tone down, distill, normalize

#### Quieter
Use when a design is overstimulating — oversaturated, too much high-contrast, too many bold elements competing, animation excess. Moves: drop saturation to ~70-85%; let neutrals dominate, color as 10% accent; reduce font weights (900→600, 700→500); add whitespace, thin/remove borders, kill decorative gradients/glows/multi-shadows; shorten animation distances (10-20px) and soften easing or remove non-functional motion; even out spacing, realign to grid. Quiet = refined/luxury, NOT grayscale or boring — keep hierarchy and character.

#### Distill
Use when cluttered, overloaded, feature-creeping. Find the ONE primary goal; keep the 20% that delivers 80%. Moves: one primary action + few secondary, rest tertiary/hidden via progressive disclosure; remove redundant copy/info; cut palette to 1-2 colors + neutrals; one font family, 3-4 sizes; strip borders/shadows/backgrounds that don't serve hierarchy; un-card basic layouts (spacing+alignment instead), never nest cards; collapse steps and merge similar actions; halve the copy, then halve again; delete dead CSS/components. Simplicity removes obstacles, not features — keep accessibility and necessary functionality.

#### Normalize
Use when a feature has drifted from the design system. Discover the system first (tokens, components, patterns, personas) — ask if unclear, don't guess. Then realign every dimension: typography → system fonts/sizes/weights, color → tokens (kill one-offs), spacing → spacing scale/grid, components → swap custom for system equivalents with matching props/variants, motion → match timing/easing, responsive → system breakpoints, a11y → system contrast/focus/ARIA, progressive disclosure → established hierarchy. Clean up: consolidate new shared components, delete orphaned code, lint/type-check/test for regressions.

---

### Structure cluster — typography, layout, spacing, devices

#### Typeset
Use when text feels generic/muddy/inconsistent. Audit: invisible default fonts? too many families (>2-3)? sizes too close (14/15/16 = muddy)? weak weight contrast? body <16px? line length outside 45-75ch? Moves: pick fonts matching brand, pair with real contrast (serif+sans) or one family in multiple weights; build a modular scale (1.25/1.333/1.5 ratio), 5 sizes (caption→heading); combine size+weight+color+space for hierarchy; `rem` scales for app UIs, fluid `clamp()` headings only for marketing/content; `max-width: 65ch`, line-height 1.1-1.2 headings / 1.5-1.7 body; `tabular-nums` for data; semantic token names; never `px` for font-size, never disable zoom. Highest-leverage UI fix.

#### Layout
Use when layout feels monotonous, crowded, or structurally weak. Squint test: can you still see primary/secondary/groupings? Moves: consistent spacing scale (no arbitrary values), `gap` not margins; tight grouping (8-12px) for related, generous separation (48-96px) between sections, varied rhythm not uniform; Flexbox for 1D, Grid for 2D — don't default to Grid; `repeat(auto-fit, minmax(280px,1fr))` for responsive grids; break card-grid monotony (vary sizes, span, mix non-card content, never nest cards); hierarchy via space+weight first, color/size only if needed; left-aligned/asymmetric reads more designed than everything-centered; semantic z-index scale (no 9999) and subtle shadow scale. Space is a design material.

#### Adapt
Use when a design must work across a new context (mobile, tablet, desktop, print, email). Adaptation = rethinking, not scaling. Moves: mobile → single column, bottom nav, 44px targets, no hover-dependence, progressive disclosure, 16px+ text; tablet → two-column/master-detail, support touch+pointer; desktop → multi-column, persistent side nav, hover/shortcuts/right-click, max-width caps (don't stretch to 4K); print → page breaks, strip nav/interactive, expand truncated content; email → 600px single column, inline CSS, table layouts, button CTAs. Techniques: Grid/Flexbox reflow, container queries, `clamp()`, content-driven breakpoints, `srcset`/`picture`. Never hide core functionality on mobile; test on real devices.

---

### Motion & ambition cluster

#### Animate
Use to add purposeful motion — feedback, smoothing jarring state changes, guidance, delight. Plan layers: one hero animation, then feedback / transition / delight layers (one orchestrated experience beats scattered motion). Durations: 100-150ms feedback, 200-300ms state changes, 300-500ms layout, 500-800ms entrances; exits ~75% of entrance. Easing: `ease-out-quart/quint/expo` (cubic-beziers below) — **never bounce/elastic** (dated). Animate `transform`+`opacity` only (GPU), never layout props. Add staggered entrances, button/form/toggle micro-interactions, expand/collapse, page/tab transitions, scroll reveals via IntersectionObserver. **Always** ship the `prefers-reduced-motion` block. Verify 60fps, non-blocking, purposeful.
```css
--ease-out-quart: cubic-bezier(0.25, 1, 0.5, 1);
--ease-out-quint: cubic-bezier(0.22, 1, 0.36, 1);
--ease-out-expo:  cubic-bezier(0.16, 1, 0.3, 1);
@media (prefers-reduced-motion: reduce){*{animation-duration:.01ms!important;transition-duration:.01ms!important;animation-iteration-count:1!important;}}
```

#### Overdrive
Use only when the context genuinely warrants a technically ambitious "wow" (creative/marketing surface, or a functional UI that should *feel* extraordinary). **Propose 2-3 directions and get user pick before building** — highest misfire risk. Then iterate with browser automation; the last 20% (easing, stagger timing, secondary motion) makes it feel inevitable. Toolkit by goal: cinematic transitions → View Transitions API, `@starting-style`, spring physics; scroll-tied → `animation-timeline: scroll()` (with static fallback); beyond-CSS → WebGL/WebGPU, Canvas/OffscreenCanvas, SVG filters; live data → virtual scrolling (TanStack Virtual), GPU charts; complex props → `@property`, Web Animations API; performance → Web Workers, WASM. Progressive enhancement is non-negotiable (`@supports`, feature detection, good CSS fallback). 60fps, respect reduced motion, lazy-init heavy resources, one wow moment not several. Don't use ambition to mask weak fundamentals — fix those first.

---

### UX-flow cluster — shape, onboard, clarify

#### Shape
Use BEFORE writing code for a feature. Design planning only — produces a brief, no code. Phase 1 discovery interview (natural dialogue, ask via AskUserQuestion): purpose/who/success/user-state; content & data with realistic ranges + edge cases; design goals (the ONE key action, desired feel, existing patterns); constraints (tech/content/responsive/a11y); anti-goals (what it must NOT be, biggest risk). Phase 2 brief: feature summary, primary user action, design direction, layout strategy, key states (default/empty/loading/error/success/edge), interaction model, content/copy requirements, recommended references, open questions. Confirm the brief with the user before finishing, then hand off to implementation.

#### Onboard
Use to design/improve onboarding, empty states, first-run. Goal: reach the "aha moment" fast, not teach everything. Principles: show don't tell (real functionality, progressive disclosure), make it skippable, teach the 20% that delivers 80%, context over ceremony, respect user intelligence. Empty states must give: what will be here + why it matters + clear CTA (+ template/example) + light visual + optional help — never a blank page. Empty-state types: first-use, user-cleared, no-results, no-permissions, error. Tours: 3-7 steps, interactive, spotlight, skippable, replayable; track "seen" in localStorage and never repeat. Never block product behind long onboarding or patronize.

#### Harden
Use after `Audit` or before shipping production UI. Make the interface resilient to real data, real devices, and real failures. Checklist: every async region has loading/error/empty/success states; long text wraps/truncates intentionally with title/details access; table cells handle nulls, long IDs, mixed languages, and 0/1/many counts; forms handle server validation, duplicate submit, offline/timeout, permission denial, and stale sessions; i18n/date/number/currency formats are explicit (Wind default date = DD/MM/YYYY); destructive actions use named confirmation with consequence; images have dimensions/fallbacks; popovers/menus are not clipped by overflow containers; keyboard and screen-reader flows work; no horizontal page scroll except deliberate data-table scroll with affordance; reduced motion, color-blind safety, and high contrast survive all states. Production hardening is not visual polish — it prevents embarrassed users and support tickets.

#### Clarify
Use to fix unclear UX copy — errors, labels, microcopy, instructions. Per-piece: one primary message, the action needed, right tone, within constraints. Patterns: errors explain what+how-to-fix in plain language, no blame, with examples ("Email addresses need an @ symbol. Try name@example.com"); labels specific not generic, format via example, instructions before the field; buttons = verb+noun ("Save changes" not "OK"); help text adds value beyond the label; empty/success/loading set expectations; confirmations state the specific action + consequence ("Delete 'Project Alpha'? This can't be undone"). Rules: specific, concise, active voice, human, helpful, consistent terminology (pick one term, stick to it). Never placeholders-as-only-labels.

---

### Performance & system cluster

#### Optimize
Use when slow/janky/heavy. **Measure first** (Core Web Vitals, bundle, frame rate, network) — fix the biggest bottleneck, not micro-optimizations. Loading: modern image formats (WebP/AVIF), correct sizing, `loading="lazy"` (never above-fold), `srcset`; JS code-splitting/tree-shaking/dynamic imports; critical CSS inline; fonts `font-display: swap` + subset + preload. Rendering: batch reads-then-writes (no layout thrash), `content-visibility:auto` / virtual scrolling for long lists, CSS `contain`. Animation: `transform`+`opacity` only, 60fps, throttle scroll, `will-change` sparingly. CWV targets: LCP <2.5s, INP <200ms, CLS <0.1 (set image dims / `aspect-ratio`). React: `memo`/`useMemo`/`useCallback`, virtualize, avoid inline fns. Measure before/after on real mid-range devices and throttled network.

#### Extract
Use when reusable patterns are scattered. Find the design system first; if none exists, ask before creating one. Identify: components repeated 3+ times, hard-coded values that should be tokens, multiple implementations of one concept, reusable layout/interaction patterns. Don't extract one-offs or over-generic shells. Build enriched versions: clear props API + sensible defaults, proper variants, built-in a11y, TS types, docs/examples; tokens with semantic (not value) names. Then migrate every instance to the shared version, test for parity, delete old implementations, update the component catalog. Grow incrementally — extract what's clearly reusable now.

---

### Review cluster — diagnose before you fix

#### Audit
Use for a **technical** quality scan (code-level, measurable) — documents issues, doesn't fix them. Score 5 dimensions 0-4: Accessibility (contrast, ARIA, keyboard, semantic HTML, alt, forms), Performance (layout thrash, animated layout props, lazy loading, bundle, re-renders), Theming (hard-coded colors, dark mode, token consistency), Responsive (fixed widths, <44px targets, overflow, breakpoints), Anti-Patterns (AI-slop tells — be brutal). Output: health table (??/20 + rating band), AI-slop verdict, exec summary, findings tagged P0 (blocking) / P1 (major/WCAG-AA) / P2 (minor) / P3 (polish) with location+impact+fix, systemic patterns, positive findings, then a prioritized list of which toolkit moves to run (end with **Polish**).

#### Critique
Use for a **design** review (taste + heuristics), ideally via two independent assessments to avoid bias: (A) LLM design review — AI-slop verdict, visual hierarchy, IA, emotional resonance, cognitive-load checklist (>4 visible options = flag), peak-end/anxiety-spike check, score Nielsen's 10 heuristics 0-4; (B) automated detection (`npx impeccable detect --json [target]` for markup/source; browser overlay or URL scan for pages). Synthesize (don't concatenate): heuristics table (??/40), anti-patterns verdict, what's working, 3-5 priority issues (P0-P3, what/why/fix/suggested-move), persona red-flags (e.g. power-user vs first-timer), provocative questions. Then ask the user 2-4 finding-specific questions to set priority/scope before recommending moves; end with **Polish**.

#### UI-Review
Use for a principal-level audit of a page/screen/screenshot/HTML/description — objective, technical, no marketing words ("seamless/elevate/vibrant"). Use strongest available evidence; mark estimated values and evidence gaps. Four pillars with measured values: (1) Typography — body ≥16px, line-height 1.45-1.65 (1.35-1.5 dense tables), 45-75ch, no viewport-width font scaling; (2) Color/contrast — text ≥4.5:1 (large ≥3:1), non-text ≥3:1, semantic correctness, color-blind safe; (3) Interaction/affordance — looks clickable, ≥44x44pt/48x48dp targets, distinct hover/focus-visible/active/disabled/loading, named icon buttons; (4) Motion — purposeful, <100ms hover / 120-200ms state / 200-300ms transitions, ease-out entrances, reduced-motion. Severity Critical/High/Medium/Low. Output a compact table: Element | Severity | Flaw | Best-Practice Ref (WCAG 2.2 SC / NN/g / HIG / Material 3) | Exact Technical Fix (with CSS values) + priority fix order + evidence gaps.

---

### Polish — the final pass

#### Polish
Use as the LAST step, only when functionally complete (it ships great vs good). Work methodically: pixel/optical alignment to grid at all breakpoints; spacing all on the scale (no rogue 13px); typography hierarchy consistent, 45-75ch, line-height right, no widows/FOUT; contrast meets AA, tokens only, tinted neutrals, no gray-on-color, visible focus; **every interactive element has all states** (default/hover/focus/active/disabled/loading/error/success); transitions 150-300ms ease-out, transform/opacity only, reduced-motion; consistent terminology/capitalization, no typos; consistent icon family + optical alignment + alt text; forms labeled/validated/tab-ordered; all edge cases (empty/error/long-content/offline); 44px touch targets, ≥14px mobile text, no horizontal scroll; no CLS; remove console.logs / dead code / unused imports, no TS `any`. Triage if shipping in 30 min; keep a consistent quality level across the whole surface, don't perfect one corner. Then use it yourself, test on real devices, get fresh eyes.
