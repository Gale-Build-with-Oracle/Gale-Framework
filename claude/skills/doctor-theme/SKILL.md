---
name: doctor-theme
description: 'Stack-agnostic YD Wellness Clinic ("Clinical Intelligence") brand theme — deep-navy chrome + colorful-data palette, logo, fonts; design methodology lives in /sop-frontend. Triggers: clinic, healthcare, wellness, doctor, theme.'
---

> **Brand skill — stack-agnostic.** This defines WHAT YD Wellness Clinic looks like (deep-navy chrome + colorful-data palette, logo, fonts). For HOW to build the UI — layout, tables, forms, a11y, spacing, states, components — follow `/sop-frontend`. No conflict: brand truth here, design method there. Apply these tokens within sop-frontend's rules.

# YD Wellness Clinic Brand Theme — "Clinical Intelligence"

The YD Wellness Clinic (Youngdo) visual identity — deep-navy chrome + colorful-data palette, logo, fonts — applied to any healthcare/clinic web project regardless of framework.

## Brand Signature

The YD identity is a **deep-navy chrome with colorful data on a clinical light canvas**: the **sidebar + header are Youngdo Deep Blue** (`#0f172a`, white text, YoungDo logo rendered LARGE); buttons, primary actions, and active-selected highlights use the SAME deep navy — one consistent chrome color (Wind 2026-06-04, supersedes the black-chrome iteration). Color lives in the DATA, not the chrome — status chips, numbers, and prices in **green** (`#22c55e`) / **red** (`#ef4444`), rating **stars yellow** (`#facc15`), and the **active tab** may use **blue** (`#194c9c`) text + underline (as in the mockups). Grey (`#64748b`) is a neutral for muted labels/borders on white. A light canvas (`#f7f9fb`) with white surfaces (`#ffffff`) floats content forward — keep it lively, never washed-out. **Visual authority = the project's `docs/UX/UI/*.png` mockups.** (The HOW — sidebar widths, layout, table build steps — lives in `/sop-frontend`.)

## Brand Colors

### Hex reference — "Clinical Intelligence" palette (canonical; chrome = deep navy per Wind 2026-06-04, matches the Stitch style-guide "Youngdo Deep Blue")

| Token | Hex (rgb) | Role |
|-------|-----------|------|
| `primary` | `#0f172a` (15,23,42) | **Youngdo Deep Blue (navy) — sidebar + header bg + buttons / primary actions / active-selected + brand chrome** |
| `on-primary` | `#ffffff` | White text/icons on navy (sidebar, header, buttons) |
| `tab-active` | `#194c9c` (25,76,156) | Blue — active TAB text + underline ONLY (accent, per mockups) |
| `critical` (alias `error`) | `#ef4444` (239,68,68) | Red — alerts / danger + negative price/Δ |
| `success` | `#22c55e` (34,197,94) | Green — active / stable + positive price/Δ |
| `warning` | `#f97316` (249,115,22) | Orange — high-risk / price shifts |
| `star` | `#facc15` (250,204,21) | Yellow — rating stars (NOT brown/amber) |
| `background` | `#f7f9fb` (247,249,251) | Main Background — clinical light-gray base |
| `surface` | `#ffffff` (255,255,255) | Container Surface — cards / content sections |
| `divider` (alias `outline-variant`) | `#e2e8f0` (226,232,240) | Subtle Dividers — borders, table lines |
| `on-surface` | `#1e293b` (30,41,59) | Body text / headings — dark, high contrast |
| `on-surface-variant` | `#64748b` (100,116,139) | Grey — muted labels / secondary, on WHITE/light surfaces only |

**Navy scope (MANDATORY — Wind 2026-06-04, "ทำไมมันดูดำเทาไปหมด"):** `--primary` deep navy is an ANCHOR, not a paint bucket. Navy ONLY on: sidebar, top header bar, primary action buttons, table HEADER row, active-selected nav/pill — the SAME navy everywhere for consistency. **NEVER dark fills on large content surfaces** — section bands, comparison header strips, dropdown/select fills, cards, toolbars, panels. Those are `--surface` white with `--divider` borders. Dropdowns/selects = white bg + divider border + `--on-surface` text; hover `--row-hover` blue tint; open/focused border `--tab-active`. If a screen reads mostly dark/grey, the theme is over-applied — match the `docs/UX/UI/*.png` mockups, where dark chrome is rare and content floats on white.

**Interaction states (MANDATORY):** every interactive element (button, pill, dropdown, tab trigger, card link) MUST show hover/active/focus feedback via the state tokens — navy actions hover `--action-hover` (#1e293b) + subtle shadow + `cursor: pointer`, pressed returns to `--primary`; white/secondary surfaces hover `--surface-hover` (#f1f5f9); keyboard focus = `focus-visible` ring `--focus-ring`. No flat dead buttons; no per-page hover hex.

**Table row states (MANDATORY — Wind 2026-06-04):** header row = deep navy (`--primary` + white text). Row hover = `--row-hover` (#eff6ff, light BLUE tint). Selected/clicked row = `--row-selected` (#dbeafe) + 3px left border `--tab-active`. **NEVER a grey or black fill on data rows** — a grey-selected row killed readability on Product Trend. Semantic cell colors (green/red prices, status) MUST stay visible in hover/selected states; neutral numbers use `--on-surface`, not grey.

**Contrast rule (WCAG AA):** navy sidebar/header + navy buttons use white text. Body/headings = `on-surface` (#1e293b). Grey `on-surface-variant` (#64748b) is fine on **white / #f7f9fb** (the muted-label tone in the mockups) but must NOT sit on a grey fill (drops below AA). The chrome is navy/white; color carries meaning — green/red status & price, blue active-tab, yellow stars. Keep it lively, NOT washed-out.

### Brand tokens — wire into your stack's theming

Stack-agnostic — pure CSS custom properties, no framework-specific conditions. Example mappings: Tailwind `@theme` / plain CSS `:root`. Values are the canonical YD brand truth — do not alter them.

```css
:root {
  /* ── YD "Clinical Intelligence" — deep-navy chrome + colorful data, canonical Wind 2026-06-04 ── */
  --primary: #0f172a;            /* YOUNGDO DEEP BLUE: sidebar + header bg + buttons / actions / active-selected chrome */
  --on-primary: #ffffff;         /* white text/icons on navy */
  --tab-active: #194c9c;         /* blue: active TAB text + underline ONLY (accent, per mockups) */

  --critical: #ef4444;           /* red: alerts / danger + negative price/Δ */
  --success: #22c55e;            /* green: active / stable + positive price/Δ */
  --warning: #f97316;            /* orange: high-risk / price shifts */
  --star: #facc15;               /* yellow: rating stars */

  --background: #f7f9fb;         /* clinical light-gray base */
  --surface: #ffffff;            /* container surface: cards / sections */
  --divider: #e2e8f0;            /* subtle dividers: borders / table lines */

  --on-surface: #1e293b;         /* body text / headings — dark */
  --on-surface-variant: #64748b; /* grey muted labels — on white/light surfaces only */

  /* ── Interaction states (hover/active/focus) — tokens, never per-page CSS ── */
  --action-hover: #1e293b;       /* navy buttons on hover: lighten + subtle shadow + cursor pointer */
  --surface-hover: #f1f5f9;      /* white/secondary pills on hover */
  --row-hover: #eff6ff;          /* table rows on hover: BLUE tint (Wind 2026-06-04 — never grey) */
  --row-selected: #dbeafe;       /* selected table row: blue accent bg + 3px left border --tab-active */
  --focus-ring: #194c9c;         /* focus-visible ring (a11y) — reuses tab-active blue */
}

/* Back-compat aliases — point old names at the new tokens (ONE source of truth): */
:root {
  --sidebar: var(--primary);              /* sidebar is DEEP NAVY */
  --header: var(--primary);               /* top header bar = deep navy */
  --action: var(--primary);               /* buttons / actions = deep navy */
  --on-action: var(--on-primary);
  --secondary: var(--primary);
  --secondary-container: var(--primary);  /* active nav / selected = deep navy */
  --error: var(--critical);
  --surface-container-lowest: var(--surface);
  --outline-variant: var(--divider);
}
```

## Fonts

- **Inter** — headings, UI labels, numerals (tight tracking on headlines only).
- **Noto Sans Thai** — ALL Thai text (load with Inter via Google Fonts). Never looped Thai fonts (Sarabun / IBM Plex Sans Thai Looped read informal in a clinical context).
- **Tabular numerals** (`font-variant-numeric: tabular-nums`) on all metrics/price/data columns.
- Thai: line-height **≥ 1.6** for body/table text; **letter-spacing 0** (negative tracking collides tone marks); Thai headings +100 weight vs Latin; equal visual weight for both languages.

## Logo

- **File**: `youngdo-logo.jpg` (lives in this skill directory — copy it into the app's static asset dir, e.g. `public/youngdo-logo.jpg`)
- **Sidebar (deep navy)**: `object-contain`, render **LARGE** (≥56px height — Wind wants it bigger), never cropped
- **Login page**: ≥80px height
- **NEVER** render below 48px
- Branded-initial placeholder when no logo / image fails

## Favicon / Metadata — Brand Assets

Generate these from `youngdo-logo.jpg` and place them in the app's static/public dir (e.g. Next.js `/app/`):

| File | Size | Purpose |
|------|------|---------|
| `favicon.ico` | 32x32 | Legacy browsers, bookmarks |
| `icon.svg` | Scalable | Modern browsers |
| `apple-icon.png` | 180x180 | iOS home screen |
| `opengraph-image.png` | 1200x630 | Social sharing preview |

**Theme-color** brand values: light `#f7f9fb`, dark `#0f172a`.
**Tab title format**: `Page Title | YD Wellness Clinic` — distinctive info first.
**Description**: "YD Wellness Clinic — Healthcare • Wellness • Patient Care".
