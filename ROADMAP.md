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
- ✅ **spider (typed assets)** — UI package ships `spider.yaml` + a generated `Assets`
  class (`lib/gen/assets.dart`); the logo becomes `Assets.brandingLogo`. Fed into
  `SvgPictureCustom` / `ImagePictureCustom`. Regenerate with `dart run spider build`.

### 4. Firebase / Supabase backends
- ✅ **Supabase** (V1): backend = `supabase_flutter` → SDK-backed remote source
  (reuses the REST contract), `supabase_provider`, `Supabase.initialize` in
  bootstrap, envied `SUPABASE_URL`/`SUPABASE_PUBLISHABLE_KEY`. **Opt-in Auth**:
  login/signup/forgot + `AuthController` + a `RouterNotifier` go_router guard
  (requires go_router_builder).
- ✅ **Realtime** (opt-in): the first feature's list becomes live — a
  `StreamNotifier` over `.stream(primaryKey: ['id'])`; the repository exposes
  `watchAll()`. Needs riverpod annotations.
- ✅ **Storage** (opt-in): `StorageService` (upload/download/publicUrl/remove) +
  provider + a sample avatar-upload widget (`image_picker`).
- ✅ **Firebase** (V1, full parity): backend = `cloud_firestore` → Firestore-backed
  remote source (doc id merged into the model), `firebase_provider` (firestore +
  optional auth/storage singletons), `Firebase.initializeApp` in bootstrap with
  **Firestore offline persistence** (NEAT's Drift layer is gated off). Init via an
  **uploaded config JSON** → generated `lib/firebase_options.dart` (+ `docs/FIREBASE.md`
  pointing to `flutterfire configure` for production). Opt-in **Auth** (FirebaseAuth),
  **Realtime** (`.snapshots()`), **Storage** (firebase_storage) — same toggles as Supabase.
- ✅ **OAuth** (Firebase, opt-in): Google + Apple via `FirebaseAuth.signInWithProvider`
  (zero extra deps) — buttons on the login screen, methods on `IAuthRepository`.
- ✅ **Firestore Security Rules scaffold**: `firestore.rules` (default-deny + an
  auth-aware rule for the first collection) + `firestore.indexes.json` + `firebase.json`.
- All harness-proven (Supabase ×3 + Firebase full-stack with OAuth + rules, analyze 0/0).
- ⏭️ Follow-ups: Supabase OAuth providers, native Google account picker
  (`google_sign_in`), Supabase Storage bucket-policy doc.

### 5. Internationalisation — ✅ **slang**
- ✅ Opt-in **slang** i18n: base `en` + `fr` (`lib/i18n/<locale>.i18n.json`),
  codegen via the **slang CLI** (`dart run slang` → `strings.g.dart`; not
  slang_build_runner, which throws `InvalidOutputException` next to source_gen
  builders like freezed/json), `TranslationProvider` in bootstrap, MaterialApp
  wired to the slang locale (`flutter_localizations`).
- ✅ Sample consumption: the riverpod feature page reads `context.t.<feature>.title`
  and shows a `LanguageSwitcher` (`LocaleSettings.setLocale`) in the AppBar.
- ✅ **Locale persistence**: `LocaleStore` (`core/i18n/locale_store.dart`) saves the
  chosen language in `shared_preferences`; `LocaleStore.init()` restores it on
  start-up (falls back to the device locale). The switcher persists via it.
- Harness-proven (integration test: generate → build_runner → analyze 0/0).
- Chosen over easy_localization (compile-time safety matches NEAT's typed DNA).
- ✅ **Translation file import (compact CSV)** — upload a `key,en,fr,…` CSV (made
  for handing off to non-dev translators in a spreadsheet). It becomes the slang
  source (base locale = first column), NEAT runs `dart run slang`. Wired in **both**
  places: a wizard upload field **and** the **Workshop** ("Import i18n" on an
  existing i18n project). Shared `I18nImporter` service; harness-proven (CSV →
  `strings.g.dart`, analyze 0/0). With a custom CSV the sample page is left un-woven
  (keys unknown), but the full slang setup + switcher are still generated.
- ⏭️ Follow-ups:
  - `.arb` import (standard Flutter/intl format, for migrating from `intl`).
  - Weave the `LanguageSwitcher` into bloc/cubit pages (today: riverpod pages only).

### 5b. Production hardening — ✅ flavors + fastlane (from the kido-luci analysis)
- ✅ **Fastlane in the right place**: was wrongly written to `fastlane/Fastfile` at
  the project root → now `android/fastlane/*` + `ios/fastlane/*` (Fastfile, Appfile,
  Matchfile, Gemfile, `.env.example`) + `android/key.properties.example`. Env-driven
  (no secrets committed), flavor-aware lanes, secrets git-ignored. CI calls
  `cd android/ios && bundle exec fastlane release`.
- ✅ **Build flavors (dev/staging/prod)**, driven by envied (kept, not swapped for
  dart-define): `main_dev/staging/prod.dart` entry points (each `bootstrap(<F>Env())`),
  `.vscode/launch.json` run configs, Android `productFlavors` (appId suffix +
  per-flavor `@string/app_name`), and `docs/FLAVORS.md`. iOS Xcode schemes are
  documented (can't be scripted reliably from a generated project).
- Harness-proven (integration: 3 entry points + productFlavors + fastlane layout,
  analyze 0/0).
- ⏭️ From the same analysis, still on the table: extract core packages
  (`architecture`/`network`/`theme`) for a lib-agnostic core; golden tests in the UI
  package; `BootstrapErrorApp`; `app_platform` bricks (permissions/share); CI
  enrichment (dependabot/codeql). Per-feature packages → the "Modular Monorepo"
  variant of #6.

### 6. Multiple architectures — later, with caution
- The harness makes **every** architecture a ~3× maintenance cost (each must be proven).
  **Clean done deeply > 3 architectures done shallowly.** If adding one, MVVM at most;
  MVC is dated in Flutter. Don't dilute the moat to match a competitor's brochure.

### 7. JSON-driven feature generation — big bet, high value
> Idea: drive the data layer from real API payloads instead of a fixed `id/name`
> placeholder. Paste a Response (and Request) JSON → NEAT infers the typed model
> and wires the endpoint. Strongest inside the **Workshop** ("paste a backend route
> 6 months later, the data layer is ready"). Fits the moat (Workshop + contract +
> harness guarantees it compiles).

**The crux is JSON→Dart inference** (a known problem — quicktype/json_to_dart — with
a long tail of edge cases): `int` vs `double`, `"date"` → `String`/`DateTime`,
`null`/`[]` → undecidable type, **nullability/optionality** from a single sample
(the Achilles heel), nested objects → sub-classes, lists of objects → `List<T>` + a
class, `snake_case`→`camelCase` with `@JsonKey`, reserved words, enums → `String`.
The harness guarantees the output **compiles**; semantic correctness (nullability,
int/double) stays **best-effort, dev-editable**.

**Design fork:** NEAT is **entity-centric** today (1 feature = 1 entity + CRUD);
Gemini's pitch is **endpoint-centric** (1 feature = N arbitrary routes). They don't
overlap — pick deliberately. → Phase it:
- **Phase 1 — Entity from a Response JSON** (keep CRUD): paste a response JSON →
  infer the entity/model fields (replaces `id/name`) + freezed/json + mapper.
  Best value/effort, bounded risk. *Confidence élevé on value, moyen-élevé on
  inference robustness.*
- **Phase 2 — Typed endpoints**: per-route `method + path + request/response JSON`
  → typed chopper methods + request models. The full vision; reshapes the "feature"
  model + Workshop UI. *Effort L.*
- **Phase 3 — polish**: surface the API Base URL at the Identity step (pre-fills the
  envied `.env`; the value already exists via `API_BASE_URL`).

**Notes vs the source pitch:** use chopper + a typed request model (not dio +
`Map<String,dynamic>`); `Response<XModel>` needs a chopper converter that can
deserialize — validate at implementation time.

## State management policy
Keep **Riverpod (annotations + manual Notifier/NotifierProvider) + Bloc/Cubit** only.
GetX / Provider / MobX are considered dated and are out of scope.

## Known gated paths (visible in UI, not yet enabled)
Layer-first · manual Riverpod (needs StateNotifier→Notifier fix) · retrofit · bloc/cubit.

## Deferred refinements
Outbox exponential backoff & conflict resolution · FlexColorScheme Playground import.
