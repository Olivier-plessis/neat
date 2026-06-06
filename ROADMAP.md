# NEAT — Roadmap

> Positioning: most Flutter generators are **broad, one-shot scaffolds**. NEAT is
> **deep, typed, and keeps working with your project over time** (the Workshop adds
> features to an *existing* project from its `.neat.json` contract). We optimise for
> **depth + correctness**, not breadth-for-marketing.

## The moat (protect this — competitors can't copy it in a weekend)
- **The Workshop**: add features to an existing project (`.neat.json` contract, scan
  features from disk, non-destructive wiring, Root/Child/Shell routing, navigation
  shell, Drift table injection, build_runner).
- **Offline-first as a system**: 3 storage strategies, Drift typed tables, NetworkInfo,
  Outbox + SyncService.
- **Typed everything**: go_router_builder, chopper, Drift typed tables.
- **Native Dart workspaces / monorepo**: `<app>_ui`, `<app>_local_storage`, Widgetbook.
- **CI/CD generation**, observability + bootstrap, shared infrastructure providers.
- **The generation test harness**: every change generates a *real* project, runs
  `build_runner` + `flutter analyze` with a **0-error / 0-warning gate**. This is why
  the output actually compiles.

## Now — v1.0.0 baseline (frozen)
Clean Architecture (feature-first) + Riverpod (annotations) + go_router/go_router_builder
+ dio/chopper + freezed/json + envied + offline-first (Drift/Outbox/Sync) + CRUD +
theming (customM3 / FlexColorScheme) + extractable UI package + Widgetbook + CI/CD.

## Roadmap (in priority order)

### 1. Open-source on GitHub  ← in progress
- License: **MIT** (max adoption, zero friction). ✅ present.
- Real README, ROADMAP, CONTRIBUTING. Public repo.
- *Why first:* distribution is the single highest-leverage move. Depth helps no one if
  no one can use it. (Desktop-only today; **web wizard is the eventual goal**.)

### 2. AGENTS.md / AI-rules — **contract-aware** (the differentiator)
- Don't ship a generic AGENTS.md. Generate it **from `.neat.json`** so the rules are
  specific to the exact generated stack (riverpod annotations + chopper + Drift offline
  + go_router_builder…), including where to add a feature and the anchor system.
- Nobody does this. Cheap to build (we already have the contract + templates).

### 3. Polish wins (self-contained, high visual impact) — **done**
- ✅ **Asset widgets**: `SvgPictureCustom` / `ImagePictureCustom` in the UI package
  (flutter_svg + package-scoped `assets/`).
- ✅ **Skeletonizer**: the generated feature is now a real list screen (provider
  fetches via the usecase, ListView + pull-to-refresh + empty/error, loading = skeleton).
- ✅ **Logo → assets**: Branding section (theme step) → copy logo + generate app
  icons + splash (`flutter_launcher_icons` + `flutter_native_splash`), run at gen time.
- ⏭️ **Next (typed assets): spider** — generate `Assets.<...>` typed constants for
  asset paths, fed into `SvgPictureCustom` / `ImagePictureCustom`. On-brand (typed).

### 4. Firebase / Supabase backends
- New `httpClient`/backend option beyond REST (dio/chopper). The feature gap that most
  broadens the target audience (indies/startups). Must cohabit with the offline layer.

### 5. Internationalisation — **decided: slang**
- **slang** (type-safe keys, codegen, typed pluralization/interpolation) over
  easy_localization. It matches NEAT's "everything typed" DNA. The "no codegen"
  argument for easy_localization is moot — it ships its own `locale_keys.g.dart` —
  so we take the compile-time-safe option. Generate the slang setup + a sample
  feature consuming `t.<feature>.…`.

### 6. Multiple architectures — later, with caution
- The harness makes **every** architecture a ~3× maintenance cost (each must be proven).
  **Clean done deeply > 3 architectures done shallowly.** If adding one, MVVM at most;
  MVC is dated in Flutter. Don't dilute the moat to match a competitor's brochure.

## State management policy
Keep **Riverpod (annotations + manual Notifier/NotifierProvider) + Bloc/Cubit** only.
GetX / Provider / MobX are considered dated and are out of scope.

## Known gated paths (visible in UI, not yet enabled)
Layer-first · manual Riverpod (needs StateNotifier→Notifier fix) · retrofit · bloc/cubit.

## Deferred refinements
Outbox exponential backoff & conflict resolution · FlexColorScheme Playground import.
