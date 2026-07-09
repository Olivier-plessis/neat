# NEAT

**A Flutter Clean Architecture project generator that keeps working with your project.**

Most generators give you a one-shot scaffold and then leave you alone. NEAT generates a
typed, production-shaped Clean Architecture app **and** keeps adding features to it
afterwards — from a contract file checked into your repo. Every generated line is proven
to compile by a real generate → `build_runner` → `flutter analyze` (0-error / 0-warning)
test harness.

> Status: **v1.0.0 baseline**, macOS desktop app. A web wizard is the eventual goal
> (see [ROADMAP.md](ROADMAP.md)). Some paths are intentionally gated until proven.

---

## What it generates

A feature-first Clean Architecture project with a modern, **fully typed** stack:

| Concern | What you get |
|---|---|
| **State** | Riverpod (`hooks_riverpod` + `riverpod_annotation`, codegen) |
| **Routing** | go_router / **go_router_builder** (typed) — Root, **Child** (nested) & **Shell** (bottom-nav) routes |
| **Networking** | dio or **chopper** (typed), with logging interceptors + ready providers |
| **Models** | freezed + json_serializable, DTO ↔ Entity mappers |
| **Offline-first** | 3 strategies (remote-only / offline read / **offline + sync**): Drift typed tables, `NetworkInfo`, **Outbox + SyncService** |
| **CRUD** | getAll / getById / create / update / delete, repository + usecases |
| **Config** | envied with 3 flavors (`.env.dev/.staging/.prod`) |
| **Observability** | `AppLogger`, `RiverpodObserver`, `bootstrap()` with `runZonedGuarded` |
| **Theming** | custom Material 3 or FlexColorScheme, responsive via `flutter_screenutil` |
| **Monorepo** | native Dart **workspaces**: extractable `<app>_ui` package + `<app>_local_storage` + Widgetbook |
| **CI/CD** | GitHub Actions workflows |

The stack is captured in a `.neat.json` **Workspace Contract** committed to the project.

## The Workshop — add features to an *existing* project

This is what sets NEAT apart. Open a project NEAT created (via its `.neat.json`) and
generate new features that **match the existing stack automatically** and
**non-destructively**:

- Per-feature layer toggles (remote / local source, usecases, mapper).
- **Routing**: Root, Child (nested under a parent), or Shell branch (bottom-nav tab).
- Offline projects get their Drift table + DAO **injected** at code anchors.
- `build_runner` + formatting run for you.

Because the contract lives in the repo, this works across a team — not just on the
machine that created the project.

## Quality bar

A `--tags integration` harness generates **real** projects and runs `flutter analyze`
with a **0-error / 0-warning** gate, plus 200+ fast unit tests for the wiring logic.
If NEAT ships it, it compiles.

```bash
flutter test --exclude-tags integration   # fast suite
flutter test --tags integration            # full generate + analyze gate (slow)
```

## Run it

```bash
flutter run -d macos
```

1. **Wizard** → configure the stack → generate a project.
2. **Workshop** → open that project → add features over time.

## Roadmap

Shipped: contract-aware AI rules (AGENTS.md), i18n (slang), Bloc/Cubit. In progress:
open-sourcing this repo, Modular Monorepo (opt-in per-feature packages). Next:
Firebase/Supabase backends, more architectures (carefully). Details in
[ROADMAP.md](ROADMAP.md).

## License

[MIT](LICENSE) © Olivier Plessis
