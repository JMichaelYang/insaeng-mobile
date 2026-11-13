# Generic UI contract (v1)

Every page is server-driven. The backend sends a **page**: a tree of typed **nodes**, starting local **state**, and **action** lists on node events. The app renders the nodes with design-system items and runs the actions.

## Request headers

Every request the app makes, including `request` actions, sends:

- `Accept-Language`, such as `ko-KR`. All text in a response must already be localized.
- `X-Generic-UI-Version`, such as `1`. See [Versioning](#versioning).

## Page

```json
{ "id": "home", "state": { "count": 0 }, "onLoad": [], "root": { "type": "column", "id": "root" } }
```

- `id` and `root` are required. `root` is the top node of the layout tree, and everything on screen is drawn from it, including the app bar.
- `state` seeds the local state and defaults to `{}`.
- `onLoad` actions run once, after the first load.

## State, paths, and bindings

- Each page holds its own JSON state from open to close. Nothing is shared between pages.
- A path is a set of dot-separated keys, and a numeric segment indexes into a list, as in `todos.0.title`. Keys can't contain `.`. A missing path resolves to nothing.
- Every value field on a node or an action takes a literal or a binding, such as `{ "$bind": "user.name", "fallback": "Guest" }`.
  - A bound node field updates whenever its path changes.
  - A bound action field is resolved when its action runs, so it sees the state left by the earlier actions.
- Structural fields are never bindable:
  - `type` and `id`;
  - node slots: `child`, `children`, and `fallback`;
  - action lists: `on<Event>`;
  - state paths: `bind`, `path`, and `loadingPath`.
- The `fallback` applies when the path is missing or holds the wrong type. Without a `fallback`, the property's default applies. The only conversion is a number or bool bound to a string property, which is shown as text.
- Bindings don't compute anything. Derived values, such as "the form is valid", go into state, through `state` or an `updateState` returned by a `request`.

## Design tokens

Visual properties take token names, never raw colors, sizes, or fonts. An unknown token falls back to the default.

- **Text style:** the Material 3 type scale, `displayLarge` through `labelSmall`.
- **Spacing:** `none`, `xs`, `sm`, `md`, `lg`, `xl`.
- **Alignment:** `start`, `center`, `end`, `stretch`.

## Nodes

- Every node has a required `type` and a required `id`. Its other properties depend on the type.
- Each `id` must be unique within the page and stay the same across responses.
  - The app uses it as the widget key, so the node keeps its scroll position, focus, and input across a `reload`.
  - It is also a stable handle for tests and analytics.
  - A page with a duplicate or missing id fails to load.
- A node may carry a `fallback` node, which renders in its place if the app doesn't know its `type`. With no `fallback`, an unknown node renders nothing.
- The app ignores properties it doesn't know.
- Property conventions:
  - Visual properties take tokens.
  - Child slots are `child` for one node and `children` for a list.
  - Events are `on<Event>` action lists.
  - Inputs write to state through a `bind` path.
- A typical page's `root` is a `column` whose first child is an `appBar` and whose second is a `scroll`, so the bar stays pinned.

This doc does not list the node catalogue, which grows with every release. The models in `lib/domain/models/generic_ui/nodes/` are the source of truth: each model's `type` and fields are its JSON.

## Actions

Event properties (`onTap`, `onChanged`, `onSubmit`, `onLoad`) hold action lists.

- Actions run one at a time, in order.
- A failed action skips the rest of the list.
- An unknown action `type` is skipped, without failing.

| Type | Fields | Fails when |
| --- | --- | --- |
| `updateState` | `path` required; `op` (`set`); `value` | the existing value has the wrong type, or an index is out of range |
| `navigate` | `screenId` required; `params` object of string values; `replace` (`false`) | never |
| `back` | none | never |
| `reload` | none. It re-fetches with the same params and keeps local state unless the new payload has `state`. | the fetch fails |
| `showMessage` | `text` required, shown in a snackbar | never |
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
- `endpoint` is required. It is relative to the API base URL, as in `/auth/login`.
- `body` is a JSON object with bindings at any depth. `GET` and `DELETE` send no body.
- `loadingPath` is a state path that is `true` while the request is in flight and `false` once it ends.
- A `2xx` response body is `{ "actions": [...] }`. Those actions run in place of the `request`, and then the rest of the list continues.
- Report expected outcomes, such as a wrong password, as a `2xx` response whose actions say what to show.
- On a non-`2xx` response or a network error, the app shows a generic localized error and the list stops.

## Versioning

- `X-Generic-UI-Version` is a capability level. It goes up by one with every contract change, including a new node, action, property, or token. A build supports everything up to its version.
- The backend gates features on `version >=`. When an older app needs a newer node, the backend sends that node with a `fallback`.
- Older apps skip unknown actions and properties and render an unknown node's `fallback`, so a missed check degrades instead of crashing.
- For a breaking change, such as a removed or renamed field or a field whose meaning changes, the backend keeps serving the old shape below the new version.
- The current version is `GenericUiVersion.current` in `lib/domain/models/generic_ui/`. The PR that bumps it says what the new version adds, so its git history is the changelog.

## Examples

```json
{
  "id": "home",
  "state": { "count": 0 },
  "root": {
    "type": "column", "id": "root",
    "children": [
      { "type": "appBar", "id": "appBar", "title": "Counter" },
      {
        "type": "container", "id": "content", "padding": "md", "alignment": "center",
        "child": {
          "type": "column", "id": "counter", "spacing": "md", "alignment": "center",
          "children": [
            { "type": "text", "id": "count", "text": { "$bind": "count" }, "style": "displayMedium" },
            {
              "type": "button", "id": "add", "label": "Add",
              "onTap": [{ "type": "updateState", "path": "count", "op": "increment" }]
            }
          ]
        }
      }
    ]
  }
}
```

```json
{
  "id": "login",
  "state": { "form": { "email": "", "password": "" }, "submitting": false },
  "root": {
    "type": "column", "id": "root",
    "children": [
      { "type": "appBar", "id": "appBar", "title": "Log in", "leading": "close" },
      {
        "type": "scroll", "id": "scroll",
        "child": {
          "type": "container", "id": "content", "padding": "lg",
          "child": {
            "type": "column", "id": "form", "spacing": "md",
            "children": [
              { "type": "textField", "id": "email", "bind": "form.email", "label": "Email", "keyboard": "email" },
              { "type": "textField", "id": "password", "bind": "form.password", "label": "Password", "obscure": true },
              {
                "type": "button", "id": "submit", "label": "Log in", "loading": { "$bind": "submitting" },
                "onTap": [{
                  "type": "request", "endpoint": "/auth/login", "loadingPath": "submitting",
                  "body": { "email": { "$bind": "form.email" }, "password": { "$bind": "form.password" } }
                }]
              }
            ]
          }
        }
      }
    ]
  }
}
```

`POST /auth/login` returns `{ "actions": [{ "type": "navigate", "screenId": "home", "replace": true }] }` on success. For a wrong password, it returns an `updateState` that clears `form.password`, followed by a `showMessage`.

## In the app

- The models live in `lib/domain/models/generic_ui/`. `GenericNode` and `GenericAction` are sealed dart_mappable families keyed by `type`, and `UnknownNode` and `UnknownAction` are their `useAsDefault` subclasses.
- `GenericCubit` holds the page and its state and runs the actions. `navigate`, `back`, and `showMessage` go out on its `effects` stream, and `GenericScreen` handles them.
- `NodeView` in `lib/ui/generic/items/` is the item registry: an exhaustive `switch` over `GenericNode` that builds `design_system/` atoms.
- **To add a node:** add the model, any atom it needs, and the item widget with its `NodeView` case.
  - Each node model is its own `part` file of `nodes/generic_node.dart`, so the sealed family stays one library. Put it in `atoms/`, `molecules/`, or `organisms/` to match the design-system level of the component it renders, or in `layout/` if it arranges child nodes, as `column` and `row` do.
  - Token enums live in `nodes/node_tokens.dart`, and its tests mirror these folders under `test/`.
- **To add an action:** add the model and handle it in `GenericCubit`.
- Every contract change bumps `GenericUiVersion.current`. Change this doc only when a rule changes, never for a new node or action.
