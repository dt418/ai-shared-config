---
name: a11y-audit
description: Audit and improve web accessibility for any web app, static site, or URL. Use when asked to improve Accessibility/PageSpeed score, run an a11y audit, check WCAG compliance, fix keyboard/screen-reader/color-contrast issues, or review Astro/React/HTML/CSS UI for accessibility regressions.
---

# A11y Audit

## Workflow

1. Identify target: URL, route, component, or changed files.
2. Load project rules first: `AGENTS.md`, framework notes, existing i18n and design-system conventions.
3. Run automated checks when possible:
   - Lighthouse: `npx lighthouse <url> --only-categories=accessibility`
   - axe: `npx @axe-core/cli <url>`
   - Project checks: lint, typecheck, tests.
4. Inspect source for issues automated tools miss.
5. Patch smallest safe change.
6. Verify with the same audit/check commands.
7. Report: changed files, audit findings, commands, pass/fail, remaining risks.

## Audit Priority

Fix in this order:

1. Critical blockers: missing names/labels, invalid ARIA, keyboard traps, missing alt text, hidden focus.
2. Page semantics: `html[lang]`, landmarks, skip link, heading order, `aria-current`.
3. Components: icon buttons, form labels/errors, menus/dialogs, live regions.
4. Visual access: contrast, focus visibility, target size, reduced motion.
5. Content: descriptive links, localized accessible labels, non-color-only cues.

## Source Inspection Checklist

- Every interactive element has native semantics or correct role/state.
- Icon-only controls have accessible names and decorative SVGs use `aria-hidden="true" focusable="false"`.
- Links/buttons have useful text; repeated ambiguous links get `aria-label`.
- Current nav/breadcrumb item uses `aria-current="page"`.
- Breadcrumbs and language switchers have localized `aria-label`.
- Page has skip link to `main` and `main` has stable `id`.
- Images have width/height and appropriate alt.
- Forms use labels, `aria-describedby`, `aria-invalid`, and announced errors.
- Keyboard focus order follows layout; focused targets are not obscured.
- Focus styles meet contrast and are not removed.

## Repo Discipline

- Never hardcode user-facing accessibility text when project has i18n.
- Prefer native HTML over ARIA.
- Avoid broad rewrites unless audit proves systemic issue.
- If automated tool fails, inspect generated HTML or browser DOM and document failure.
- Use references only when needed: `references/wcag-quick-check.md`.
