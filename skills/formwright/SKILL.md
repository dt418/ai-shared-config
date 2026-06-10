---
name: formwright
description: Build schema-driven forms with Formwright. Use this skill whenever the user mentions Formwright, wants to build a form with `buildForm`/`field`/`layout`/`rule`, needs conditional fields or show/hide logic, is wiring up FormRuntimeProvider or FormRuntimeRoot, writing plugins (field/operator/effect/datasource), or asking about datasources, computed fields, or validation rules. Trigger even if the user just says "add a form", "schema form", "dynamic form", or is working in a repo that already imports from `formwright`. Does NOT cover plain react-hook-form without Formwright, Zod standalone usage, or Next.js Server Actions.
user-invocable: false
---

# Formwright

Schema-driven form engine for React + react-hook-form. Three layers:

1. **Schema** (`formwright/schema`) — define fields, layout, rules in TypeScript
2. **Core** (`formwright/core`) — runtime evaluates rules, manages plugins
3. **React** (`formwright/react`) — renders schema via RHF; hooks for custom renderers

## Install

```bash
pnpm add formwright
# or
npm install formwright
```

## Minimal example

```tsx
import { buildForm, field, layout } from "formwright/schema";
import { createFormRuntime } from "formwright/core";
import { registerBasicPlugins } from "formwright/plugins";
import { FormRuntimeProvider, FormRuntimeRoot } from "formwright/react";
import { useForm } from "react-hook-form";

const form = buildForm({
  form: { formId: "contact", version: "1" },
  fields: [
    field.text("name",  { label: "Name",  required: true }),
    field.email("email", { label: "Email", required: true }),
    field.textarea("message", { label: "Message" }),
  ],
  layout: layout.stack("root", [
    layout.field("name"),
    layout.field("email"),
    layout.field("message"),
  ]),
});

function ContactForm() {
  const rhf = useForm();
  const runtime = createFormRuntime({ form, plugins: registerBasicPlugins() });

  return (
    <FormRuntimeProvider runtime={runtime} rhf={rhf}>
      <form onSubmit={rhf.handleSubmit(console.log)}>
        <FormRuntimeRoot />
        <button type="submit">Send</button>
      </form>
    </FormRuntimeProvider>
  );
}
```

## Key design rules

- Schema has **no React deps** — `buildForm` is pure TS, safe to share server/client
- `runtime.evaluate()` is **pure and synchronous** — no async in rules
- Async lives in `useDatasourceOptions` and datasource plugin `load()` only
- Field paths are **dot-notation strings**: `"address.city"`, `"items.0.name"`
- `hiddenFieldPolicy` defaults to `"keep"` — set to `"clear"` if hidden values should reset

## Reference files

Read only what the task needs. Skip the rest.

| Priority | File | When to read |
|---|---|---|
| **Always** | `references/schema-builder.md` | Defining fields, layout, rules, datasources |
| **Always** | `references/react-integration.md` | Provider, root, hooks, custom renderers |
| **Advanced** | `references/plugins.md` | Custom field/operator/effect/validator/datasource plugins |
| **Patterns** | `references/patterns.md` | Recipes + common gotchas |

Most tasks only need schema-builder + react-integration. Read plugins.md only when writing a plugin. Read patterns.md for common recipes or when hitting a footgun.
