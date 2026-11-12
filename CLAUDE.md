# CLAUDE.md

## Rules

- No code comments. Do not add `//`, `///`, or `#` comments to hand-written code or config. Generated code is exempt.
- Layers: `ui/` and `data/` both depend on `domain/`, never on each other. `domain/` holds models, repository interfaces, `Result`, and errors, and imports nothing outside `domain/` (no Flutter). `data/` holds repository implementations, services, and DTOs. Only `config/dependencies.dart` wires implementations to interfaces. The `layer_boundary` lint (`tools/layer_lint`, an analyzer plugin) enforces this in `flutter analyze`.
- Never hand-write generated code. Edit the sources and run the generators (`fvm flutter pub get`, `fvm dart run build_runner build --delete-conflicting-outputs`).
