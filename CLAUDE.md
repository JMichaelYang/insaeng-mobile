# CLAUDE.md

## Architecture

Read [docs/architecture/overview.md](docs/architecture/overview.md) before changing code under `lib/` or `test/`. It links the per-layer docs (domain, data, ui, composition root, testing), and `ui/home/` is the reference feature.

## Rules

- No code comments. Do not add `//`, `///`, or `#` comments to hand-written code or config. Generated code is exempt.
- Never hand-write generated code. Edit the sources and run the generators (`fvm flutter pub get`, `fvm dart run build_runner build --delete-conflicting-outputs`).
