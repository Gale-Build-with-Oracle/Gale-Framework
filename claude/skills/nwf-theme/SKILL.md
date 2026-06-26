---
name: nwf-theme
description: NWFTH brand boundary only — logo asset, broad official color anchors, and minimal brand conventions. Use /sop-frontend for UI/UX design, layout, components, tokens, accessibility, and polish.
---

# NWFTH Brand Boundary

This skill is intentionally narrow. It provides only the NWFTH brand boundary: logo asset, broad official color anchors, and minimal brand conventions.

For UI/UX design quality — layout, components, spacing, typography, tables, forms, dashboards, interaction states, responsive behavior, accessibility, tokens, and polish — use `/sop-frontend` plus the target project’s own design source of truth.

## What this skill is

- A brand reference for **logo and broad colors**.
- A guardrail so NWFTH work does not drift off-brand.
- A handoff point to `/sop-frontend` for all real interface decisions.

## What this skill is not

- Not a design system.
- Not a Tailwind/shadcn/OKLCH token recipe.
- Not a component library.
- Not a layout, table, form, dashboard, sidebar, button, chart, spacing, typography, or animation prescription.
- Not permission to hard-code brown/gold into every UI element.

## Logo

- Asset: `NWFLogo.png` in this skill directory.
- Copy the logo into the target app’s normal static/public asset location when NWFTH branding is required.
- Alt text: `Newly Weds Foods (Thailand)`.
- Keep the logo recognizable and undistorted.
- Do not stretch, crop, skew, recolor casually, or place it on noisy backgrounds.
- For favicons/touch icons, derive from a readable mark rather than shrinking an unreadable full lockup.

## Broad color anchors

Use these as broad brand anchors only. They are not a complete palette and must not be pasted blindly into components.

| Anchor | Hex | Meaning |
|---|---:|---|
| Primary brown | `#3A2920` | Main NWFTH brand anchor |
| Deep brown | `#2B1C14` | Dark brand variant |
| Gold accent | `#E0AA2F` | Brand accent / highlight |
| Warm cream | `#FAF8F4` | Optional warm light surface anchor |

Rules:

- Use the colors to keep the work recognizably NWFTH, not to decide UI structure.
- Accessibility and product readability win over literal color copying.
- Supporting semantic colors for success/warning/error/info should stay semantic and accessible.
- If a project needs tokens, create them in that project with `/sop-frontend` and verify contrast there.

## Minimal conventions

- Browser title pattern when useful: `<Page Title> | NWFTH`.
- Date display/input default remains `DD/MM/YYYY` unless the product owner explicitly requests another format.
- Preserve official Thai labels when digitizing controlled Thai source forms; pair with English only when it improves usability without changing meaning.

## Required handoff

After loading this skill for brand context, load and follow `/sop-frontend` for the actual UI/UX work.

Use `/sop-frontend` for:

- Layout and responsive behavior.
- Typography decisions.
- Component choices and variants.
- Tables, forms, dashboards, navigation, cards, dialogs, and empty/loading/error states.
- Accessibility, contrast, focus, touch targets, keyboard behavior, and screen-reader behavior.
- Visual critique, audit, hardening, and final polish.

## Verification checklist

- [ ] Correct logo asset used: `NWFLogo.png`.
- [ ] Logo is visible, readable, and not distorted.
- [ ] Broad color anchors are preserved without over-prescribing the UI.
- [ ] No layout/component/token/design prescription was copied from this skill.
- [ ] `/sop-frontend` was used for design and implementation quality.
