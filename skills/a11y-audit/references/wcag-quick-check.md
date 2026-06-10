# WCAG quick check

## Perceivable

- Images: meaningful `alt`; decorative images `alt=""` only when truly decorative.
- Text contrast: 4.5:1 normal text, 3:1 large text and UI graphics.
- Do not rely on color alone for state or errors.
- Media needs captions/transcripts when present.

## Operable

- All actions work with keyboard.
- Focus is visible and not hidden by sticky UI.
- Provide skip link before repeated nav.
- Targets are at least 24×24 CSS px; prefer 44×44 for touch.
- Respect `prefers-reduced-motion`.

## Understandable

- `html lang` matches page language.
- Navigation labels are consistent and localized.
- Forms have labels, help text, clear errors, and autocomplete where useful.
- Link text describes destination or action.

## Robust

- Prefer native elements.
- Use ARIA only when native HTML cannot express behavior.
- Keep ARIA roles/states valid.
- Dynamic status messages use `aria-live` only when useful.
