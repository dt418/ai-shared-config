# React Integration Reference

## Setup

```tsx
import { createFormRuntime } from "formwright/core";
import { registerBasicPlugins, registerAsyncPlugins } from "formwright/plugins";
import {
  FormRuntimeProvider,
  FormRuntimeRoot,
  FormField,
  FormArray,
  FieldComposer,
  ArrayComposer,
  useCreateFormRuntime,
  useFormRuntime,
  useFormLifecycle,
  useFormField,
  useFormArray,
  useFormLayout,
  useDatasourceOptions,
  useRemoteFormDefinition,
} from "formwright/react";
import { useForm } from "react-hook-form";
```

## FormRuntimeProvider

Wraps a react-hook-form `FormProvider`. Must be the outermost context.

```tsx
function MyForm() {
  const rhf = useForm({ defaultValues: { name: "", email: "" } });
  const runtime = useMemo(
    () => createFormRuntime({ form, plugins: registerBasicPlugins() }),
    [],
  );

  return (
    <FormRuntimeProvider
      runtime={runtime}
      rhf={rhf}
      hiddenFieldPolicy="clear"   // "keep" (default) | "clear"
      context={{ mode: "edit", userRole: "admin" }}
    >
      <form onSubmit={rhf.handleSubmit(onSubmit)}>
        <FormRuntimeRoot />
        <button type="submit">Submit</button>
      </form>
    </FormRuntimeProvider>
  );
}
```

`hiddenFieldPolicy="clear"` resets hidden field values to their defaults on hide.

## FormRuntimeRoot

Renders the full form from the root layout node. Drop it inside `FormRuntimeProvider`.

```tsx
// Basic
<FormRuntimeRoot />

// With custom renderers
<FormRuntimeRoot
  fieldRendererMap={{ select: MySelectRenderer, date: MyDatePicker }}
  arrayFieldRendererMap={{ array: MyArrayRenderer }}
  layoutRendererMap={{ section: MySectionCard }}
  fieldSlots={{
    Shell: MyFieldShell,
    Label: MyLabel,
    Error: MyErrorMessage,
  }}
/>
```

### Extension points

| Prop | Type | Purpose |
|---|---|---|
| `fieldRendererMap` | `Record<string, FieldRendererComponent>` | Replace full field rendering by renderer key |
| `arrayFieldRendererMap` | `Record<string, ArrayFieldRendererComponent>` | Replace array field rendering |
| `layoutRendererMap` | `Record<string, LayoutRendererComponent>` | Replace layout node rendering by type |
| `fieldSlots` | `FieldRendererSlots` | Replace shell parts: `Shell`, `Label`, `Description`, `Control`, `Error`, `Help` |

### Custom field renderer

```tsx
import type { FieldRendererComponent } from "formwright/react";

const MySelectRenderer: FieldRendererComponent = ({ path, field, state, controller }) => {
  return (
    <div>
      <label>{field.ui.label}</label>
      <MySelectComponent
        value={controller.field.value}
        onChange={controller.field.onChange}
        options={field.ui.options}
        disabled={state.disabled}
      />
      {state.error && <span>{state.error}</span>}
    </div>
  );
};
```

## Hooks

### useCreateFormRuntime(input)

React hook that wraps `createFormRuntime` with stable memoization. Prefer this over calling `createFormRuntime` + `useMemo` manually.

```tsx
const runtime = useCreateFormRuntime({
  form,
  plugins: registerBasicPlugins(),
  context: { mode: "edit" },
});
```

Re-creates runtime only when `form`, `context`, or `plugins` reference changes.

### useFormRuntime()

Access the `FormRuntime` instance from inside `FormRuntimeProvider`.

```tsx
const runtime = useFormRuntime();
const { fieldState } = runtime.evaluate(values);
```

### useFormLifecycle()

Run lifecycle hooks defined in the form schema.

```tsx
const { runOnLoad, runOnSubmit, runLifecycle } = useFormLifecycle();

useEffect(() => { runOnLoad(); }, []);

const onSubmit = async (values) => {
  await runOnSubmit();
  await saveToApi(values);
};
```

### useFormField(path)

Wire a custom field component to the runtime.

```tsx
import { useFormField } from "formwright/react";

function MyField({ path }: { path: string }) {
  const { field, state, controller } = useFormField(path);

  // field  → normalized field definition (label, options, ui props, …)
  // state  → { visible, disabled, required, error }
  // controller → RHF controller (field.value, field.onChange, fieldState)

  if (!state.visible) return null;

  return (
    <input
      {...controller.field}
      disabled={state.disabled}
      required={state.required}
      placeholder={field.ui.placeholder}
    />
  );
}
```

### useFormArray(path)

Manage dynamic lists.

```tsx
import { useFormArray } from "formwright/react";

function TagList({ path }: { path: string }) {
  const { fields, state, append, remove, move } = useFormArray(path);

  return (
    <div>
      {fields.map((item, index) => (
        <div key={item.id}>
          <input name={`${path}.${index}`} defaultValue={item.value} />
          <button onClick={() => remove(index)}>Remove</button>
        </div>
      ))}
      <button onClick={() => append("")} disabled={state.atMax}>Add</button>
    </div>
  );
}
```

### useFormLayout(id)

Read layout node + derived layout state (visibility, props).

```tsx
const { layout, state } = useFormLayout("personal-section");
if (!state.visible) return null;
```

### useDatasourceOptions(fieldPath)

Load async select options for a field.

```tsx
import { useDatasourceOptions } from "formwright/react";

function CountrySelect({ path }: { path: string }) {
  const { options, loading, error } = useDatasourceOptions(path);

  if (loading) return <span>Loading…</span>;
  if (error) return <span>Error loading options</span>;

  return (
    <select>
      {options.map((o) => (
        <option key={o.value} value={o.value}>{o.label}</option>
      ))}
    </select>
  );
}
```

## Remote form definitions

Load schema from an API endpoint.

```tsx
import { useRemoteFormDefinition, FormRuntimeProvider, FormRuntimeRoot } from "formwright/react";

function RemoteForm({ formId }: { formId: string }) {
  const { form, loading, error } = useRemoteFormDefinition({
    url: `/api/forms/${formId}`,
  });

  if (loading) return <Spinner />;
  if (error || !form) return <ErrorMessage />;

  const runtime = createFormRuntime({ form, plugins: registerBasicPlugins() });
  const rhf = useForm();

  return (
    <FormRuntimeProvider runtime={runtime} rhf={rhf}>
      <form onSubmit={rhf.handleSubmit(onSubmit)}>
        <FormRuntimeRoot />
      </form>
    </FormRuntimeProvider>
  );
}
```

## FormField compound component

Alternative to `useFormField` — a compound component for building custom field shells without a full renderer replacement.

```tsx
import { FormField } from "formwright/react";

// FormField.Root provides context; children access field/state via sub-components
function MyCustomField({ path }: { path: string }) {
  return (
    <FormField.Root path={path}>
      <FormField.Label />
      <FormField.Description />
      <FormField.Control render={(props) => (
        <input
          value={props.value as string}
          onChange={(e) => props.onChange(e.target.value)}
          disabled={props.state.disabled}
        />
      )} />
      <FormField.Error />
    </FormField.Root>
  );
}
```

## FieldComposer

Renders Shell → Label → Description → Control → Help → Error with slot overrides. Use inside a custom renderer to get the standard field chrome without reimplementing it.

```tsx
import { FieldComposer } from "formwright/react";

const MySelectRenderer: FieldRendererComponent = ({ field, state, value, onChange, error, options }) => (
  <FieldComposer
    field={field}
    state={state}
    label={field.uiField?.label}
    error={error}
    slots={{ Error: MyCustomError }}
  >
    <MySelect value={value} onChange={onChange} options={options} disabled={state.disabled} />
  </FieldComposer>
);
```

## createDefaultRendererMaps

Get the built-in renderer maps to extend, rather than replacing everything from scratch.

```tsx
import { createDefaultRendererMaps } from "formwright/react";

const defaults = createDefaultRendererMaps();

<FormRuntimeRoot
  fieldRendererMap={{
    ...defaults.fieldRendererMap,
    date: MyDatePicker,          // override just date
    color: MyColorPicker,        // add new type
  }}
  layoutRendererMap={{
    ...defaults.layoutRendererMap,
    section: MyCardSection,      // override just section
  }}
/>
```

## Reading form values

Use standard RHF methods from `useFormContext()` or pass `rhf` methods directly.

```tsx
// Inside FormRuntimeProvider children:
import { useFormContext } from "react-hook-form";

const { getValues, watch, setValue } = useFormContext();
const values = getValues();             // all current values
const name = watch("name");             // reactive single field
```

## View / edit mode

Pattern for toggling read-only:

```tsx
const runtime = createFormRuntime({
  form,
  plugins: registerBasicPlugins(),
  context: { mode: viewMode ? "view" : "edit" },
});

// In schema rules:
// rule.when(contextRef("mode").eq("view")).disableAll()
```

Re-create runtime when context changes, or pass updated context to provider.
