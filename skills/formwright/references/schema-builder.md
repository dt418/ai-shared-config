# Schema Builder Reference

## defineForm + buildForm

`defineForm` creates the form metadata object. Pass it as `form` in `buildForm`.

```ts
import { defineForm, buildForm, field, layout, rule, fieldRef, contextRef, datasource } from "formwright/schema";

const myForm = defineForm({ id: "my-form", version: "1.0", meta: { title: "My Form" } });

const form = buildForm({
  form:       myForm,   // or inline: { formId: "my-form", version: "1" }
  fields:     [...],          // BuiltField[]
  layout:     layout.stack(…), // root LayoutNode
  rules?:     [...],          // BuiltRule[]
  datasources?: [...],        // BuiltDatasource[]
  computed?:  [...],          // ComputedField[]
  lifecycle?: { onLoad?, onSubmit? },
});
```

## field.*

All helpers return `BuiltField` — pass to `layout.field()` and rule targets.

### Text / string
```ts
field.text("path",     { label, required, default, minLength, maxLength, pattern })
field.textarea("path", { label, required, default, minLength, maxLength })
field.email("path",    { label, required })
field.url("path",      { label, required })
field.phone("path",    { label, required })
```

### Numeric
```ts
field.number("path",  { label, required, default, minimum, maximum })
field.integer("path", { label, required, default, minimum, maximum })
```

### Boolean
```ts
field.checkbox("path", { label, required, default })
```

### Select
```ts
// Inline options — label/value pairs
field.select("type", {
  label: "Account type",
  options: [
    { value: "personal", label: "Personal" },
    { value: "business", label: "Business" },
  ],
})

// Datasource (async options loaded at runtime)
field.select("country", { label: "Country", dataSource: "countries" })
```

### Date / time
```ts
field.date("birthday",     { label: "Date of birth", required })
field.datetime("startedAt", { label: "Start time" })
```

### Array fields
```ts
// Object array (rows with multiple columns)
field.objectArray("lineItems", {
  label: "Line items",
  item: {
    name:  field.textItem({ label: "Item name", placeholder: "Widget" }),
    qty:   { valueType: "integer", label: "Qty" },
    price: { valueType: "number",  label: "Price" },
  },
  itemLayout: ["name", "qty", "price"], // column order
  minItems: 1,
  maxItems: 20,
})

// Primitive array (list of strings/numbers)
field.array("tags", { label: "Tags", item: field.stringItem() })
field.array("scores", { label: "Scores", item: field.numberItem(0) })
```

### Common field options (all helpers)
```ts
{
  label?: string
  description?: string      // shown below label
  helpText?: string         // shown as tooltip/help icon
  placeholder?: string
  renderer?: string         // custom renderer key
  componentProps?: Record<string, unknown>
  styleTokens?: Record<string, string | number | boolean>
}
```

## layout.*

Layout nodes describe visual structure. Pass as `layout` in `buildForm`.

```ts
layout.stack("id", children, options?)   // vertical stack
layout.section("id", children, options?) // titled section card
layout.grid("id", { columns: 2 }, children)  // CSS grid
layout.tabs("id", tabs, options?)        // tabbed panels
layout.stepper("id", steps, options?)    // multi-step wizard
layout.divider("id?", options?)          // horizontal rule

// Reference a field node (leaf):
layout.field(builtField)          // or layout.field("path")
layout.field(builtField, { span: 2 }) // span in grid
```

### Grid example
```ts
layout.grid("contact-grid", { columns: 2 }, [
  layout.field(firstName),
  layout.field(lastName),
  layout.field(email, { span: 2 }),
])
```

### Tabs example
```ts
layout.tabs("main-tabs", [
  { id: "personal",  label: "Personal",  content: layout.stack("p", [layout.field(name)]) },
  { id: "billing",   label: "Billing",   content: layout.stack("b", [layout.field(card)]) },
])
```

### Stepper example
```ts
layout.stepper("checkout", [
  { id: "step1", label: "Contact",  content: layout.stack("s1", [...]) },
  { id: "step2", label: "Shipping", content: layout.stack("s2", [...]) },
  { id: "step3", label: "Review",   content: layout.stack("s3", [...]) },
])
```

### Layout node base options
```ts
{
  title?: string
  description?: string
  visibleWhen?: RuleExpression  // hide the entire section conditionally
  componentProps?: Record<string, unknown>
}
```

## rule.* and fieldRef / contextRef

Rules are condition → effect pairs evaluated synchronously on every value change.

```ts
import { rule, fieldRef, contextRef } from "formwright/schema";
```

### Basic usage
```ts
rule.when(fieldRef("type").eq("business")).show(companyName)
rule.when(fieldRef("status").eq("locked")).disable("editableField")
rule.when(fieldRef("hasShipping").eq(true)).require("shippingAddress")
rule.when(fieldRef("country").eq("us")).setValue("currency", "USD")
rule.when(fieldRef("promoCode").exists()).clearValue("discount")
rule.when(fieldRef("role").neq("admin")).hide(adminPanel)
```

### Comparison operators
| Method | Meaning |
|---|---|
| `.eq(v)` | equals |
| `.neq(v)` | not equals |
| `.gt(v)` / `.gte(v)` | greater / greater-or-equal |
| `.lt(v)` / `.lte(v)` | less / less-or-equal |
| `.in([...])` | value in list |
| `.exists()` | truthy / non-empty |

### Compound conditions
```ts
import type { RuleExpression } from "formwright/schema";

// and / or — use raw AST objects
const expr: RuleExpression = {
  and: [
    fieldRef("plan").eq("pro"),
    fieldRef("seats").gt(5),
  ],
};
rule.when(expr).show(enterpriseFeatures)

// or
rule.when({ or: [fieldRef("country").eq("us"), fieldRef("country").eq("ca")] }).show(naShipping)
```

### contextRef — reference external context values
```ts
const runtime = createFormRuntime({
  form, plugins,
  context: { mode: "view", userRole: "admin" },
});

rule.when(contextRef("mode").eq("view")).disableAll()
rule.when(contextRef("userRole").neq("admin")).hide(adminPanel)
```

### Effect methods
| Effect | Signature |
|---|---|
| `.show(target)` | Make field/layout visible |
| `.hide(target)` | Hide field/layout |
| `.enable(target)` | Enable (un-disable) field |
| `.disable(target)` | Disable field |
| `.require(target, bool?)` | Set required on/off |
| `.setValue(target, value)` | Set a field's value |
| `.clearValue(target)` | Reset field to default |
| `.disableAll()` | Disable everything (use with `mode: "view"`) |

## datasource

Used for async select options.

```ts
import { datasource } from "formwright/schema";

buildForm({
  // ...
  datasources: [
    datasource.static("statuses", [
      { value: "active",   label: "Active" },
      { value: "inactive", label: "Inactive" },
    ]),
    datasource.remote("countries", {
      endpoint: "/api/countries",
    }),
    datasource.remote("states", {
      endpoint: "/api/states",
      method: "GET",                        // "GET" | "POST", default GET
      queryMap: { country: "{country}" },   // appended as query string params
      dependsOn: ["country"],               // re-fetch when country changes
    }),
  ],
})
```

## computed fields

Derive a field value from other fields synchronously.

```ts
buildForm({
  // ...
  computed: [
    {
      target: "fullName",
      expression: { concat: [{ var: "firstName" }, " ", { var: "lastName" }] },
    },
    {
      target: "total",
      expression: { multiply: [{ var: "quantity" }, { var: "unitPrice" }] },
    },
  ],
})
```
