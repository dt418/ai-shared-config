# Common Patterns

## Gotchas

**1. Recreating runtime on every render**
```tsx
// WRONG — new runtime every render, blows away all state
function MyForm() {
  const runtime = createFormRuntime({ form, plugins: registerBasicPlugins() });

// CORRECT — memoize or use useCreateFormRuntime
function MyForm() {
  const runtime = useCreateFormRuntime({ form, plugins: registerBasicPlugins() });
  // or: const runtime = useMemo(() => createFormRuntime(...), [form]);
```

**2. `hiddenFieldPolicy` default is `"keep"` — hidden values persist**

Fields hidden by rules still submit their last value unless you opt in to clearing:
```tsx
<FormRuntimeProvider runtime={runtime} rhf={rhf} hiddenFieldPolicy="clear">
```
Use `"keep"` when hidden data should survive (toggle show/hide); use `"clear"` for wizard steps where hidden = irrelevant.

**3. `datasource.remote` without `dependsOn` won't re-fetch on parent change**

```ts
// WRONG — states never re-load when country changes
datasource.remote("states", { endpoint: "/api/states", queryMap: { country: "{country}" } })

// CORRECT
datasource.remote("states", {
  endpoint: "/api/states",
  queryMap: { country: "{country}" },
  dependsOn: ["country"],   // ← required for reactive re-fetch
})
```

**4. `rule.when(...).show(field)` — field is HIDDEN by default when any show-rule exists**

Once any `show` rule targets a field, the field is hidden unless a rule makes it visible. This is intentional — don't also add a matching `hide` rule.

**5. `contextRef` values must be passed when creating the runtime**

```tsx
// WRONG — context not passed, contextRef("mode") returns undefined
const runtime = createFormRuntime({ form, plugins });

// CORRECT
const runtime = createFormRuntime({ form, plugins, context: { mode: "view" } });
```

**6. `evaluate()` is synchronous — don't call async code inside rules**

All rule logic runs sync inside `evaluate()`. Async datasource loading is separate — use `useDatasourceOptions()` hook.

**7. Array item paths use numeric indices**

`lineItems.0.name`, `lineItems.1.price` — not `lineItems[0].name`. Use dot notation everywhere.



## Conditional fields (show/hide)

```ts
const accountType = field.select("accountType", {
  label: "Account type",
  options: [{ value: "personal", label: "Personal" }, { value: "business", label: "Business" }],
});
const companyName = field.text("companyName", { label: "Company name" });
const vatNumber   = field.text("vatNumber",   { label: "VAT number" });

buildForm({
  // ...
  rules: [
    rule.when(fieldRef(accountType).eq("business")).show(companyName),
    rule.when(fieldRef(accountType).eq("business")).show(vatNumber),
    // fields are hidden by default when a show rule exists
  ],
})
```

## Required depending on another field

```ts
rule.when(fieldRef("hasShipping").eq(true)).require("shippingAddress")
rule.when(fieldRef("hasShipping").eq(true)).require("shippingCity")
```

## Cascading selects (country → state)

```ts
const countryField = field.select("country", { label: "Country", dataSource: "countries" });
const stateField   = field.select("state",   { label: "State",   dataSource: "states" });

buildForm({
  datasources: [
    datasource.remote("countries", { endpoint: "/api/countries" }),
    datasource.remote("states", {
      endpoint: "/api/states",
      queryMap: { country: "{country}" },
      dependsOn: ["country"],
    }),
  ],
  rules: [
    // Clear state when country changes
    rule.when(fieldRef("country").exists()).clearValue(stateField),
  ],
})
```

## Multi-step form (stepper)

```ts
const step1Fields = [field.text("firstName"), field.text("lastName")];
const step2Fields = [field.email("email"), field.phone("phone")];
const step3Fields = [field.select("plan", { options: plans })];

buildForm({
  fields: [...step1Fields, ...step2Fields, ...step3Fields],
  layout: layout.stepper("wizard", [
    { id: "personal",  label: "Personal",  content: layout.stack("s1", step1Fields.map(f => layout.field(f))) },
    { id: "contact",   label: "Contact",   content: layout.stack("s2", step2Fields.map(f => layout.field(f))) },
    { id: "plan",      label: "Plan",      content: layout.stack("s3", step3Fields.map(f => layout.field(f))) },
  ]),
})
```

## View / edit mode toggle

```ts
// Schema — disable all fields in view mode
const rules = [
  rule.when(contextRef("mode").eq("view")).disableAll(),
];

// Component — pass mode as context
function ProfileCard({ user, editable }: Props) {
  const [editing, setEditing] = useState(false);
  const rhf = useForm({ defaultValues: user });
  const runtime = useMemo(
    () => createFormRuntime({
      form: profileForm,
      plugins: registerBasicPlugins(),
      context: { mode: editing ? "edit" : "view" },
    }),
    [editing],
  );

  return (
    <FormRuntimeProvider runtime={runtime} rhf={rhf}>
      <FormRuntimeRoot />
      {editable && (
        <button onClick={() => setEditing(e => !e)}>
          {editing ? "Cancel" : "Edit"}
        </button>
      )}
    </FormRuntimeProvider>
  );
}
```

## Dynamic object arrays (line items)

```ts
const lineItems = field.objectArray("lineItems", {
  label: "Line items",
  item: {
    description: field.textItem({ label: "Description" }),
    qty:   { valueType: "integer", label: "Qty",   default: 1 },
    price: { valueType: "number",  label: "Price",  default: 0 },
  },
  itemLayout: ["description", "qty", "price"],
  minItems: 1,
  maxItems: 20,
});

// Computed total
buildForm({
  computed: [
    {
      target: "subtotal",
      expression: { sum: { map: [{ var: "lineItems" }, { multiply: [{ var: "qty" }, { var: "price" }] }] } },
    },
  ],
})
```

## Computed / derived fields

```ts
buildForm({
  fields: [
    field.text("firstName", { label: "First name" }),
    field.text("lastName",  { label: "Last name"  }),
    field.text("fullName",  { label: "Full name"  }),
    field.number("qty",      { label: "Qty"   }),
    field.number("price",    { label: "Price" }),
    field.number("total",    { label: "Total" }),
  ],
  computed: [
    {
      target: "fullName",
      expression: { cat: [{ var: "firstName" }, " ", { var: "lastName" }] },
    },
    {
      target: "total",
      expression: { "*": [{ var: "qty" }, { var: "price" }] },
    },
  ],
})
```

## Custom field slot (replace just the error message)

```ts
const MyError = ({ message }: FieldErrorSlotProps) =>
  message ? <p className="text-red-500 text-xs mt-1">{message}</p> : null;

<FormRuntimeRoot fieldSlots={{ Error: MyError }} />
```

## Custom section renderer

```ts
import type { LayoutRendererComponent } from "formwright/react";

const CardSection: LayoutRendererComponent = ({ node, children }) => (
  <div className="rounded-lg border p-4 mb-4">
    {node.title && <h3 className="font-semibold mb-2">{node.title}</h3>}
    {children}
  </div>
);

<FormRuntimeRoot layoutRendererMap={{ section: CardSection }} />
```

## API-driven form (fetch schema + submit)

```tsx
function DynamicForm({ formId }: { formId: string }) {
  const [formDef, setFormDef] = useState<FormDefinition | null>(null);

  useEffect(() => {
    fetch(`/api/forms/${formId}`)
      .then(r => r.json())
      .then(setFormDef);
  }, [formId]);

  if (!formDef) return <Spinner />;

  const runtime = createFormRuntime({ form: formDef, plugins: registerBasicPlugins() });
  const rhf = useForm();

  const onSubmit = async (values: Record<string, unknown>) => {
    await fetch(`/api/submissions/${formId}`, {
      method: "POST",
      body: JSON.stringify(values),
    });
  };

  return (
    <FormRuntimeProvider runtime={runtime} rhf={rhf}>
      <form onSubmit={rhf.handleSubmit(onSubmit)}>
        <FormRuntimeRoot />
        <button type="submit">Submit</button>
      </form>
    </FormRuntimeProvider>
  );
}
```

## Validation with Zod

```ts
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";

const schema = z.object({
  email: z.string().email("Invalid email"),
  age:   z.number().min(18, "Must be 18+"),
});

const rhf = useForm({ resolver: zodResolver(schema) });
// Pass rhf to FormRuntimeProvider as normal
```

## Testing a form schema (Vitest)

```ts
import { describe, it, expect } from "vitest";
import { createFormRuntime } from "formwright/core";
import { registerBasicPlugins } from "formwright/plugins";
import { myForm } from "./my-form";

describe("myForm rules", () => {
  it("shows companyName when accountType is business", () => {
    const runtime = createFormRuntime({ form: myForm, plugins: registerBasicPlugins() });
    const { fieldState } = runtime.evaluate({ accountType: "business" });
    expect(fieldState["companyName"]?.visible).toBe(true);
  });

  it("hides companyName for personal accounts", () => {
    const runtime = createFormRuntime({ form: myForm, plugins: registerBasicPlugins() });
    const { fieldState } = runtime.evaluate({ accountType: "personal" });
    expect(fieldState["companyName"]?.visible).toBe(false);
  });
});
```
