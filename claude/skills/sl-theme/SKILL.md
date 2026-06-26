---
name: sl-theme
description: Solution Lab brand boundary only — logo assets, broad official color anchors, and minimal brand text. Use /sop-frontend for UI/UX design, layout, components, tokens, accessibility, and polish.
---

# Solution Lab Brand Boundary

This skill is intentionally narrow. It provides only the Solution Lab brand boundary: logo assets, broad official color anchors, and minimal brand text.

For UI/UX design quality — layout, components, spacing, typography, tables, forms, dashboards, interaction states, responsive behavior, accessibility, tokens, and polish — use `/sop-frontend` plus the target project’s own design source of truth.

## What this skill is

- A brand reference for **logo and broad colors**.
- A guardrail so Solution Lab work does not drift off-brand.
- A handoff point to `/sop-frontend` for all real interface decisions.

## What this skill is not

- Not a design system.
- Not a Tailwind/shadcn/OKLCH token recipe.
- Not a component library.
- Not a layout, table, form, dashboard, sidebar, button, chart, spacing, typography, or animation prescription.
- Not permission to hard-code orange/copper into every UI element.

## Logo

- Primary asset: `solution-lab-logo.png` in this skill directory.
- Supporting/cover asset when needed: `solutionlabcover.png`.
- Copy the needed asset into the target app’s normal static/public asset location when Solution Lab branding is required.
- Alt text: `Solution Lab`.
- Keep the logo recognizable and undistorted.
- Do not stretch, crop, skew, recolor casually, apply blind CSS filters, or place it on noisy backgrounds.
- For favicons/touch icons, derive from a readable mark rather than shrinking an unreadable full lockup.

## Broad color anchors

Use these as broad brand anchors only. They are not a complete palette and must not be pasted blindly into components.

| Anchor | Hex | Meaning |
|---|---:|---|
| Orange/copper | `#D4652C` | Main Solution Lab brand anchor |
| Dark charcoal | `#333333` | Logo/text anchor |
| Lighter orange | `#E88B5A` | Optional secondary accent |
| Warm off-white | `#F8F4F0` | Optional warm light surface anchor |
| Deep warm dark | `#1A1410` | Optional dark surface anchor |

Rules:

- Use the colors to keep the work recognizably Solution Lab, not to decide UI structure.
- Accessibility and product readability win over literal color copying.
- Supporting semantic colors for success/warning/error/info should stay semantic and accessible.
- If a project needs tokens, create them in that project with `/sop-frontend` and verify contrast there.

## Minimal brand text

- Tagline when needed: `Solution Lab - Innovation & Technology`.
- Browser title pattern when useful: `<Page Title> | Solution Lab`.

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

- [ ] Correct logo asset used: `solution-lab-logo.png` or `solutionlabcover.png` where appropriate.
- [ ] Logo is visible, readable, and not distorted.
- [ ] Broad color anchors are preserved without over-prescribing the UI.
- [ ] No layout/component/token/design prescription was copied from this skill.
- [ ] `/sop-frontend` was used for design and implementation quality.
