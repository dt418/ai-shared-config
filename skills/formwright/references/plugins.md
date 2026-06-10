# Plugin Authoring Reference

## Plugin kinds

| Kind | Purpose |
|---|---|
| `field` | Custom field types: normalization, default values, validation, serialization |
| `layout` | Custom layout node types |
| `operator` | New condition operators for rule `when` expressions |
| `effect` | New rule effects |
| `validator` | Custom validation rules |
| `datasource` | Custom option loaders |

All plugin interfaces live in `formwright/core`.

## Built-in plugins

```ts
import { registerBasicPlugins, registerAsyncPlugins } from "formwright/plugins";

const runtime = createFormRuntime({
  form,
  plugins: [
    ...registerBasicPlugins(),                      // operators + effects
    ...registerAsyncPlugins({ baseUrl: "/api" }),   // static + remote datasource
  ],
});
```

## Writing an operator plugin

Adds a new operator for rule `when` expressions.

```ts
import type { OperatorPlugin } from "formwright/core";

const startsWithOperator: OperatorPlugin = {
  kind: "operator",
  identity: { name: "startsWith", version: "1" },
  operatorType: "startsWith",

  evaluate({ expression, values, context }) {
    const [ref, prefix] = expression.startsWith as [{ var: string }, string];
    const value = values[ref.var];
    return typeof value === "string" && value.startsWith(prefix);
  },
};
```

Use in rules with raw AST:

```ts
import type { RuleExpression } from "formwright/schema";

rule.when({ startsWith: [{ var: "email" }, "admin@"] } as RuleExpression).show(adminPanel)
```

## Writing an effect plugin

Adds a new rule effect.

```ts
import type { EffectPlugin } from "formwright/core";

const setReadonlyEffect: EffectPlugin = {
  kind: "effect",
  identity: { name: "setReadonly", version: "1" },
  effectType: "setReadonly",

  apply({ effect, fieldState }) {
    const target = (effect as { target: string }).target;
    if (fieldState[target]) {
      fieldState[target].readonly = true;
    }
  },
};
```

## Writing a datasource plugin

Loads async options for `field.select` fields with a `dataSource` reference.

```ts
import type { DatasourcePlugin } from "formwright/core";

const myDatasource: DatasourcePlugin = {
  kind: "datasource",
  identity: { name: "mySource", version: "1" },
  datasourceType: "my-source",

  async load({ definition, values, context }) {
    const response = await fetch(`/api/options?q=${values.query ?? ""}`);
    const data = await response.json();
    return data.map((item: any) => ({ value: item.id, label: item.name }));
  },
};
```

Helper for remote sources:

```ts
import { createRemoteDataSourcePlugin } from "formwright/plugins";

const statesPlugin = createRemoteDataSourcePlugin({
  datasourceType: "states",
  requestBuilder({ definition, values }) {
    return {
      url: `/api/states?country=${values.country}`,
      method: "GET",
    };
  },
  responseMapper(data) {
    return data.map((s: any) => ({ value: s.code, label: s.name }));
  },
});
```

## Writing a field plugin

Defines a completely custom field type.

```ts
import type { FieldPlugin } from "formwright/core";

const colorPickerPlugin: FieldPlugin = {
  kind: "field",
  identity: { name: "color-picker", version: "1" },
  fieldType: "color-picker",

  normalize({ field }) {
    return {
      fieldType: "color-picker",
      label: field.ui.label,
      ui: field.ui,
      data: field.data,
    };
  },

  getDefaultValue() {
    return "#000000";
  },

  getValidationPlan({ field }) {
    return [];  // return ValidatorRef[] if field has validation rules
  },

  serialize({ value }) {
    return value;
  },

  deserialize({ value }) {
    return typeof value === "string" ? value : "#000000";
  },
};
```

## Writing a validator plugin

Custom validation rule that runs on field submission.

```ts
import type { ValidatorPlugin } from "formwright/core";

const uniqueEmailValidator: ValidatorPlugin = {
  kind: "validator",
  identity: { name: "uniqueEmail", version: "1" },
  validatorType: "unique-email",

  async validate({ value, definition }) {
    const res = await fetch(`/api/check-email?email=${value}`);
    const { taken } = await res.json();
    if (taken) return { valid: false, message: "Email already in use" };
    return { valid: true };
  },
};
```

## Registering plugins

Pass all plugins in the `plugins` array to `createFormRuntime`:

```ts
const runtime = createFormRuntime({
  form,
  plugins: [
    ...registerBasicPlugins(),
    ...registerAsyncPlugins(),
    startsWithOperator,
    setReadonlyEffect,
    colorPickerPlugin,
    statesPlugin,
    uniqueEmailValidator,
  ],
});
```
