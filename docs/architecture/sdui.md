# Server-driven UI contract (v1)

Every screen is server-driven. The backend sends a **screen**: a tree of typed **nodes**, starting local **state**, and **action** lists on node events. The app renders the nodes with design-system items and runs the actions.

## Transport

- The app fetches screens with `GET /sdui/screens/{screenId}?{params}`. The `params` come from the `navigate` action or deep link that opened the screen.
- Any non-`2xx` response shows the error state with a retry button.
- Every request, including `request` actions, sends these headers:
  - `Accept-Language`, such as `ko-KR`. All text in a response must already be localized.
  - `X-SDUI-Version`, such as `1`. See [Versioning](#versioning).

## Screen

```json
{ "id": "home", "title": "Counter", "state": { "count": 0 }, "onLoad": [], "root": { "type": "column" } }
```

- `id` and `root` are required.
- `title` is the app bar text.
- `state` seeds the local state and defaults to `{}`.
- `onLoad` actions run once, after the first load.

## State, paths, and bindings

- Each screen holds its own JSON state from open to close. Nothing is shared between screens.
- A path is a set of dot-separated keys, and a numeric segment indexes into a list, as in `todos.0.title`. Keys can't contain `.`. A missing path resolves to nothing.
- A property marked **B** below takes a literal or a binding: `{ "$bind": "user.name", "fallback": "Guest" }`. It updates whenever the path changes.
- The `fallback` applies when the path is missing or holds the wrong type. Without a `fallback`, the property's default applies. The only conversion is a number or bool bound to a string property, which is shown as text.
- Bindings don't compute anything. Derived values, such as "the form is valid", go into state, through `state` or an `updateState` returned by a `request`.

## Design tokens

Visual properties take token names, never raw colors, sizes, or fonts. An unknown token falls back to the default.

- **Text style:** the Material 3 type scale, `displayLarge` through `labelSmall`.
- **Spacing:** `none`, `xs`, `sm`, `md`, `lg`, `xl`.
- **Alignment:** `start`, `center`, `end`, `stretch`.

## Nodes

- Every node has a required `type` and an optional `id`, which is for tests and analytics.
- A node may carry a `fallback` node, which renders in its place if the app doesn't know its `type`. With no `fallback`, an unknown node renders nothing.
- The app ignores properties it doesn't know.

| Type | Properties (optional unless required) |
| --- | --- |
| `column` | `children`; `spacing` (`none`); `alignment` on the cross axis (`stretch`) |
| `row` | `children`; `spacing` (`none`); `alignment` on the cross axis (`center`) |
| `container` | `child`; `padding` spacing token (`none`); `alignment` (`start`) |
| `scroll` | `child`, scrolls vertically |
| `spacer` | `size` spacing token (`md`) |
| `divider` | a horizontal rule, with no properties |
| `text` | `text` **B** required; `style` (`bodyMedium`) |
| `button` | `label` **B** required; `variant` `primary`/`secondary`/`text` (`primary`); `enabled` **B** (`true`); `loading` **B** (`false`), which shows a spinner and ignores taps; `onTap` |
| `textField` | `bind` path required, written on every keystroke; `label` **B**; `hint` **B**; `obscure` (`false`); `keyboard` `text`/`email`/`number`/`phone` (`text`); `onChanged`; `onSubmit` |

## Actions

Event properties (`onTap`, `onChanged`, `onSubmit`, `onLoad`) hold action lists.

- Actions run one at a time, in order.
- A failed action skips the rest of the list.
- An unknown action `type` is skipped, without failing.
- A **B** property is resolved when its action runs, so it sees the state left by the earlier actions.

| Type | Fields | Fails when |
| --- | --- | --- |
| `updateState` | `path` required; `op` (`set`); `value` **B** | the existing value has the wrong type, or an index is out of range |
| `navigate` | `screenId` required; `params` with **B** string values; `replace` (`false`) | never |
| `back` | none | never |
| `reload` | none. It re-fetches with the same params and keeps local state unless the new payload has `state`. | the fetch fails |
| `showMessage` | `text` **B** required, shown in a snackbar | never |
| `request` | see below | the response is not `2xx`, or the network fails |

`updateState` ops:

| `op` | Effect | When the path is missing |
| --- | --- | --- |
| `set` | replaces the value with `value` | creates it, along with any missing parents |
| `toggle` | flips a bool | sets it to `true` |
| `increment` | adds `value` (default `1`, negative to decrement) | treats it as `0` |
| `append` | appends `value` to a list | creates `[value]` |
| `removeAt` | removes the item at index `value` | fails |
| `merge` | shallow-merges the object `value` | creates it as `value` |

### `request`

- `method` is `GET`, `POST`, `PUT`, `PATCH`, or `DELETE`, and defaults to `POST`.
- `path` is required. It is relative to the API base URL, as in `/auth/login`.
- `body` is a JSON object with bindings at any depth. `GET` and `DELETE` send no body.
- `loadingPath` is a state path that is `true` while the request is in flight and `false` once it ends.
- A `2xx` response body is `{ "actions": [...] }`. Those actions run in place of the `request`, and then the rest of the list continues.
- Report expected outcomes, such as a wrong password, as a `2xx` response whose actions say what to show.
- On a non-`2xx` response or a network error, the app shows a generic localized error and the list stops.

## Versioning

- `X-SDUI-Version` is a capability level. It goes up by one with every contract change, including a new node, action, property, or token. A build supports everything up to its version.
- The backend gates features on `version >=`. When an older app needs a newer node, the backend sends that node with a `fallback`.
- Older apps skip unknown actions and properties and render an unknown node's `fallback`, so a missed check degrades instead of crashing.
- For a breaking change, such as a removed or renamed field or a field whose meaning changes, the backend keeps serving the old shape below the new version.

| Version | Adds |
| --- | --- |
| 1 | Everything in this doc |

## Examples

```json
{
  "id": "home",
  "title": "Counter",
  "state": { "count": 0 },
  "root": {
    "type": "column", "spacing": "md", "alignment": "center",
    "children": [
      { "type": "text", "text": { "$bind": "count" }, "style": "displayMedium" },
      { "type": "button", "label": "Add", "onTap": [{ "type": "updateState", "path": "count", "op": "increment" }] }
    ]
  }
}
```

```json
{
  "id": "login",
  "title": "Log in",
  "state": { "form": { "email": "", "password": "" }, "submitting": false },
  "root": {
    "type": "container", "padding": "lg",
    "child": {
      "type": "column", "spacing": "md",
      "children": [
        { "type": "textField", "bind": "form.email", "label": "Email", "keyboard": "email" },
        { "type": "textField", "bind": "form.password", "label": "Password", "obscure": true },
        {
          "type": "button", "label": "Log in", "loading": { "$bind": "submitting" },
          "onTap": [{
            "type": "request", "path": "/auth/login", "loadingPath": "submitting",
            "body": { "email": { "$bind": "form.email" }, "password": { "$bind": "form.password" } }
          }]
        }
      ]
    }
  }
}
```

`POST /auth/login` returns `{ "actions": [{ "type": "navigate", "screenId": "home", "replace": true }] }` on success. For a wrong password, it returns an `updateState` that clears `form.password`, followed by a `showMessage`.

## In the app

- The models live in `lib/domain/models/sdui/`. `LayoutNode` and `LayoutAction` are sealed dart_mappable families keyed by `type`, and `UnknownNode` and `UnknownAction` are their `useAsDefault` subclasses.
- `GenericCubit` holds the screen and its state and runs the actions. `navigate`, `back`, and `showMessage` go out on its `effects` stream, and `GenericScreen` handles them.
- `NodeView` in `lib/ui/generic/items/` is the item registry: an exhaustive `switch` over `LayoutNode` that builds `design_system/` atoms.
- **To add a node:** add the model, any atom it needs, and the item widget with its `NodeView` case.
- **To add an action:** add the model and handle it in `GenericCubit`.
- Every contract change updates this doc, bumps the app's SDUI version, and adds a row to the version table.
- Every fixture in `assets/sdui/` must decode with no unknown types, and a test enforces this.
