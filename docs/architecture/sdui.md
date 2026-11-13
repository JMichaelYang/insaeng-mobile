# Server-driven UI contract

Every screen in the app is server-driven. The backend sends a **screen**: a tree of typed **nodes**, the screen's starting local **state**, and lists of **actions** attached to node events. The app draws the tree with its registered design items and runs the actions. This doc is the contract between the app and the backend. The app's own layering is described in [overview.md](overview.md).

Contract version: **1**.

## Transport

The app fetches a screen with:

```
GET /sdui/screens/{screenId}?{params}
```

- `params` are the query parameters from the `navigate` action that opened the screen, or from a deep link. They are sent as plain strings.
- A `2xx` response body is a [screen](#screen). Any other response makes the app show its error state, with a retry button.
- Every request, both screen fetches and [`request`](#request) actions, carries these headers:

| Header | Example | Meaning |
| --- | --- | --- |
| `Accept-Language` | `ko-KR` | The device locale. All text in a response must already be localized. |
| `X-SDUI-Version` | `1` | The contract version the app speaks. |
| `X-SDUI-Nodes` | `column,text,button` | The node `type`s this app build can render. |

## Screen

```json
{
  "id": "home",
  "title": "Counter",
  "state": { "count": 0 },
  "onLoad": [],
  "root": { "type": "column", "children": [] }
}
```

| Field | Type | Required | Meaning |
| --- | --- | --- | --- |
| `id` | string | yes | The screen id. It matches `{screenId}` in the URL. |
| `title` | string | no | The app bar title. With no title, the app bar has no text. |
| `state` | object | no | The starting local state, `{}` by default. See [State and paths](#state-and-paths). |
| `onLoad` | action list | no | Actions run once, right after the screen first loads. |
| `root` | node | yes | The root of the layout tree. |

## State and paths

Each open screen keeps its own local state: a JSON object seeded from `state`. It lives until the screen is closed. Nothing is shared between screens.

A **path** points into that state with dot-separated keys. A numeric segment indexes into a list.

| Path | With state | Resolves to |
| --- | --- | --- |
| `count` | `{"count": 3}` | `3` |
| `form.email` | `{"form": {"email": "a@b.c"}}` | `"a@b.c"` |
| `todos.0.title` | `{"todos": [{"title": "Milk"}]}` | `"Milk"` |

Keys must not contain `.`. A path that doesn't exist resolves to nothing.

## Bindings

Any node or action property listed as **bindable** below takes either a literal value or a binding:

```json
{ "type": "text", "text": "Hello" }
{ "type": "text", "text": { "$bind": "user.name", "fallback": "Guest" } }
```

- `$bind` is a path into the screen's state. The property re-renders whenever that path changes.
- `fallback` is used when the path resolves to nothing or to a value of the wrong type. Without a `fallback`, the property uses its default from the tables below.
- Bound values are converted only in the obvious cases: a number or boolean bound to a string property is shown as text. Every other mismatch counts as the wrong type.
- Bindings can't compute values. Put derived values, such as "the button is enabled when the form is valid", into state, either in the starting `state` or by returning an `updateState` action from a `request`.

## Design tokens

Visual properties take token names, never raw colors, sizes, or fonts. The app maps each token to its theme.

| Token kind | Values |
| --- | --- |
| Text style | Material 3 type scale: `displayLarge`, `displayMedium`, `displaySmall`, `headlineLarge`, `headlineMedium`, `headlineSmall`, `titleLarge`, `titleMedium`, `titleSmall`, `bodyLarge`, `bodyMedium`, `bodySmall`, `labelLarge`, `labelMedium`, `labelSmall` |
| Spacing | `none`, `xs`, `sm`, `md`, `lg`, `xl` |
| Alignment | `start`, `center`, `end`, `stretch` |

The app falls back to its default for an unknown token.

## Nodes

Every node is a JSON object with a `type`. These fields are common to all nodes:

| Field | Type | Meaning |
| --- | --- | --- |
| `type` | string | Selects the node. Required. |
| `id` | string | An optional stable id, used for tests and analytics. |
| `fallback` | node | Rendered in place of this node when the app doesn't know its `type`. Without it, nothing is rendered. |

The app ignores properties it doesn't know. Each property below is optional unless marked required. **B** marks a bindable property.

### Layout

| Type | Properties |
| --- | --- |
| `column` | `children`: node list. `spacing`: spacing token between children, default `none`. `alignment`: cross-axis alignment, default `stretch`. |
| `row` | `children`: node list. `spacing`: spacing token, default `none`. `alignment`: cross-axis alignment, default `center`. |
| `container` | `child`: node. `padding`: spacing token on every side, default `none`. `alignment`: alignment of the child, default `start`. |
| `scroll` | `child`: node. Scrolls vertically. |
| `spacer` | `size`: spacing token, default `md`. Empty space along the parent's main axis. |
| `divider` | None. A horizontal rule. |

### Content

| Type | Properties |
| --- | --- |
| `text` | `text` (required, B): string. `style`: text style token, default `bodyMedium`. |
| `button` | `label` (required, B): string. `variant`: `primary`, `secondary`, or `text`, default `primary`. `enabled` (B): bool, default `true`. `loading` (B): bool, default `false`. While loading, the button shows a spinner and ignores taps. `onTap`: action list. |
| `textField` | `bind` (required): the state path the field reads and writes. Every keystroke writes the text to that path. `label` (B): string. `hint` (B): string. `obscure`: bool, default `false`, for passwords. `keyboard`: `text`, `email`, `number`, or `phone`, default `text`. `onChanged`: action list, run after each write. `onSubmit`: action list, run when the user presses the keyboard's done key. |

An app build may not support every node type yet. It lists the types it does support in `X-SDUI-Nodes`. The backend should send only those types, or give a newer node a `fallback` built from supported types.

## Actions

An event property such as `onTap`, `onChanged`, `onSubmit`, or `onLoad` holds a **list** of actions:

```json
"onTap": [
  { "type": "updateState", "path": "count", "op": "increment" },
  { "type": "showMessage", "text": "Added" }
]
```

- The actions in a list run in order, and each one finishes before the next starts.
- If an action **fails**, the rest of the list is skipped. Each action below says when it fails.
- The app skips an action whose `type` it doesn't know, without failing.
- Bindable action properties are resolved when the action runs, so they see the state left by the actions before them.

### `updateState`

Changes the screen's local state.

| Field | Meaning |
| --- | --- |
| `path` | Required. The state path to change. Missing parents are created as objects. |
| `op` | One of the ops below. Default `set`. |
| `value` | B. The operand. Its meaning depends on `op`. |

| `op` | Effect | When `path` is missing |
| --- | --- | --- |
| `set` | Replaces the value with `value`. | Creates it. |
| `toggle` | Flips a bool. `value` is ignored. | Sets it to `true`. |
| `increment` | Adds `value` to a number, default `1`. Use a negative number to decrement. | Treats it as `0`. |
| `append` | Adds `value` to the end of a list. | Creates `[value]`. |
| `removeAt` | Removes the item at index `value` from a list. | Fails. |
| `merge` | Shallow-merges the object `value` into an object. | Creates it as `value`. |

It fails when the existing value has the wrong type for the op, or when a `removeAt` index is out of range.

### `navigate`

Opens another screen.

| Field | Meaning |
| --- | --- |
| `screenId` | Required. The screen to open. |
| `params` | An object of B string values, sent as the new screen's query params. |
| `replace` | Bool, default `false`. When `true`, the new screen replaces the current one instead of being pushed on top. |

It never fails, because the new screen loads on its own.

### `back`

Closes the current screen. It has no fields and never fails.

### `reload`

Fetches the current screen again with the same params and swaps in the new layout. The local state is kept unless the new payload includes `state`, in which case it replaces the local state. It has no fields, and it fails when the fetch fails.

### `showMessage`

Shows a short message in a snackbar. `text` (required, B) is the message. It never fails.

### `request`

Calls a backend endpoint and runs the actions it returns.

| Field | Meaning |
| --- | --- |
| `method` | `GET`, `POST`, `PUT`, `PATCH`, or `DELETE`. Default `POST`. |
| `path` | Required. The endpoint path, relative to the API base URL, such as `/auth/login`. |
| `body` | A JSON object whose values may be bindings at any depth. It is resolved and sent as the JSON body. `GET` and `DELETE` send no body. |
| `loadingPath` | A state path that is set to `true` while the request is in flight and to `false` when it ends, whether it succeeds or fails. Bind a button's `loading` to it. |

A `2xx` response body must be:

```json
{ "actions": [ ... ] }
```

The returned actions run immediately, as if they were inserted in place of the `request`. Then the rest of the original list continues. A response with an empty list counts as success with no effect.

Report expected outcomes, such as a wrong password, as a `2xx` response whose actions describe what to show. A non-`2xx` response or a network error makes the request fail. The app then shows a generic, localized error message and skips the rest of the list.

## Versioning and compatibility

- **Additive changes keep the version:** a new node type, a new action type, a new optional property, or a new token value. Older apps skip unknown actions, ignore unknown properties, and render an unknown node's `fallback` (or nothing).
- **Breaking changes bump `X-SDUI-Version`:** removing or renaming a field, or changing what a field means. The backend keeps serving the old shape to apps that send the old version.
- The backend reads `X-SDUI-Nodes` to decide whether a newer node is safe to send or needs a `fallback`.

## Examples

### Counter

```json
{
  "id": "home",
  "title": "Counter",
  "state": { "count": 0 },
  "root": {
    "type": "container",
    "padding": "md",
    "alignment": "center",
    "child": {
      "type": "column",
      "spacing": "md",
      "alignment": "center",
      "children": [
        { "type": "text", "text": { "$bind": "count" }, "style": "displayMedium" },
        {
          "type": "button",
          "label": "Add",
          "onTap": [{ "type": "updateState", "path": "count", "op": "increment" }]
        }
      ]
    }
  }
}
```

### Login form

```json
{
  "id": "login",
  "title": "Log in",
  "state": { "form": { "email": "", "password": "" }, "submitting": false },
  "root": {
    "type": "scroll",
    "child": {
      "type": "container",
      "padding": "lg",
      "child": {
        "type": "column",
        "spacing": "md",
        "children": [
          { "type": "text", "text": "Welcome back", "style": "headlineSmall" },
          { "type": "textField", "bind": "form.email", "label": "Email", "keyboard": "email" },
          { "type": "textField", "bind": "form.password", "label": "Password", "obscure": true },
          {
            "type": "button",
            "label": "Log in",
            "loading": { "$bind": "submitting" },
            "onTap": [
              {
                "type": "request",
                "method": "POST",
                "path": "/auth/login",
                "loadingPath": "submitting",
                "body": {
                  "email": { "$bind": "form.email" },
                  "password": { "$bind": "form.password" }
                }
              }
            ]
          },
          {
            "type": "button",
            "label": "Create an account",
            "variant": "text",
            "onTap": [{ "type": "navigate", "screenId": "signup" }]
          }
        ]
      }
    }
  }
}
```

`POST /auth/login` might answer a success with:

```json
{ "actions": [{ "type": "navigate", "screenId": "home", "replace": true }] }
```

And a wrong password with:

```json
{
  "actions": [
    { "type": "updateState", "path": "form.password", "value": "" },
    { "type": "showMessage", "text": "Wrong email or password" }
  ]
}
```

## In the app

- The contract models live in `lib/domain/models/sdui/` as dart_mappable classes. Nodes and actions are sealed families decoded by `type`, and `UnknownNode` and `UnknownAction` are the `useAsDefault` subclasses.
- `GenericCubit` in `lib/ui/generic/view_models/` holds the screen and its local state and runs actions. `navigate`, `back`, and `showMessage` go out on its `effects` stream, and `GenericScreen` turns them into routing and snackbars.
- `NodeView` in `lib/ui/generic/items/` is the item registry: an exhaustive `switch` over the sealed `LayoutNode` that builds each node from `design_system/` atoms.
- **To add a node:** add its model to the `LayoutNode` family, build any atom it needs in `design_system/`, add its item widget and its `NodeView` case, add it to `X-SDUI-Nodes`, and document it here.
- **To add an action:** add its model to the `LayoutAction` family, handle it in `GenericCubit`, and document it here.
- Every fixture in `assets/sdui/` must decode with no unknown nodes or actions. A test enforces this.
