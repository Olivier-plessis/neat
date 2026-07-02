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

### 2. AGENTS.md / AI-rules — **contract-aware** — ✅ **done**
- ✅ Generated **from the `NeatContract`** (`.neat.json`), not a generic file:
  `AgentsMdTemplate.generate(NeatContract c)` branches on the exact stack — architecture
  (feature/layer-first), `httpClient` (chopper/dio/supabase/firebase), storage strategy
  (remote / offline read / offline + sync Outbox), theme approach — and documents where
  to add a feature, the layer boundaries, the `// neat:` anchors, and the codegen commands
  for *that* project. Written at generation time (see `System Output` → "Writing AGENTS.md").
- The differentiator holds: the rules are specific to the generated stack, nobody else
  does this, and it reuses the contract + templates we already own.

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

### 3b. UX & Shell foundation — ✅ (not a feature, but the app's spine)
The wizard grew a proper shell. None of this was on the original roadmap; it's the
foundation everything else is configured through.
- ✅ **Hub landing**: Create / Open entry, **Recent Projects** (`.neat.json`-backed,
  capped at 10), AppMode (Hub / Wizard / Workshop full-screen modes).
- ✅ **Add-feature CTA**: after a successful generation, jump straight into the Workshop
  on the just-created project (no app restart) or back Home.
- ✅ **Open in IDE**: from the success panel, open the generated project in **VS Code /
  Android Studio / Antigravity** (`open -a`, graceful snackbar if not installed).
- ✅ **Infrastructure / Dependencies split**: backend selector (REST / Supabase / Firebase)
  + per-env config + preset packages live on **Infrastructure**; pub.dev search lives on
  **Dependencies**. Fixed the overflow + single-job-per-screen clarity.
- ✅ **Sequential wizard nav**: every step is mandatory — the side-nav can't skip ahead
  (`FurthestStep` only advances via Next, which gates on the current step's validity).
- ✅ Internal cleanup: removed the dead dio cluster from NEAT itself (generation
  templates untouched); `core/theme` gap/padding helpers.

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
- ✅ **Environments & flavors** — two **decoupled** concepts (a key refactor):
  - **Per-env entry points** (`main_<env>.dart` + `.env.<env>` + `.vscode/launch.json`
    + `docs/FLAVORS.md`): driven purely by having **≥2 environments** → work on **every
    platform** (web/desktop included; they're just Dart entry points selected with `-t`).
  - **Native flavors** (Android `productFlavors` + `--flavor`, `@string/app_name`,
    `buildFeatures { resValues = true }` for AGP 8, iOS schemes documented): **opt-in
    toggle AND mobile-only** (web/desktop have no flavor concept; the toggle greys out
    with an explanatory note off-mobile or with <2 envs).
  - **Single env by default** (one `prod`): collapses to a plain `.env` + single `Env`
    class + one `main.dart` (zero flavor machinery, plain `flutter run`). The user
    **adds** environments on demand (1–4) via +/− controls.
  - **Explicit production base** (`baseEnvIndex`, a clickable BASE chip) — no longer
    positional, so adding an env never moves the base. The base drives: no appId suffix,
    the logger's release-quietening, release build targets.
  - Renamable environments, each with a **per-env API URL** (REST) / **Supabase URL+key**
    pre-filled into its `.env`. Backend-keyed field identity fixes a state-reuse leak
    (REST URL bleeding into the Supabase fields on backend switch).
- Driven by **envied** (kept, not dart-define).
- Harness-proven (integration: single-env collapse + multi-env-without-native-flavors
  on macOS + flavors+productFlavors+fastlane on android/ios with explicit base, analyze 0/0).
- ⏭️ **iOS native flavors**: even in native mode only **Android** is patched
  (`_patchAndroidFlavors`); iOS needs Xcode schemes + `.xcconfig` per flavor, currently
  only **documented** in `FLAVORS.md` (can't be scripted reliably from Dart). Revisit if
  iOS side-by-side installs are requested.
- ⏭️ From the same analysis, still on the table: extract core packages
  (`architecture`/`network`/`theme`) for a lib-agnostic core; golden tests in the UI
  package; `BootstrapErrorApp`; `app_platform` bricks (permissions/share); CI
  enrichment (dependabot/codeql). Per-feature packages → the "Modular Monorepo"
  variant of #6.

### 5c. Layered DI graph — ✅ (dependency-rule fix, wesioo-aligned)
- **The defect**: the generated `<feature>_providers.dart` (repository-level
  wiring: ApiSource, LocalSource, Repository, Sync) lived under
  `presentation/providers/`, importing concrete Data classes (ApiSource, Model,
  RepositoryImpl) directly from a file physically inside the presentation tree.
  Not a runtime bug (the actual notifier/widget only ever touched the usecase),
  but a real import-graph smell — and something AGENTS.md was actively
  documenting as the pattern to reproduce.
- **The fix**, validated against a real production reference (**wesioo**):
  split into `data/repositories/<feature>_repository_providers.dart` (ApiSource
  + LocalSource + Repository + Sync — all Data-layer wiring) and
  `presentation/providers/<feature>_usecase_providers.dart` (usecase providers
  only, built from the repository provider — the **one** file presentation ever
  imports from `data/`, and only for that abstract-typed provider). Same split
  applied to `auth_repository_providers.dart` (was `auth_providers.dart`).
  AGENTS.md now documents the two-file split and the rule explicitly.
- **wesioo is the architecture reference going forward** for NEAT's generated
  code — when a design question comes up, check what wesioo does before
  inventing a convention.
- Harness-proven (chopper+offline-sync, offline+sync, Workshop add-feature,
  Workshop Drift injection, Supabase auth — all re-verified after the split;
  analyze 0/0).

### 5d. Centralised error handling — ✅ (wesioo-aligned)
- **The defect**: every repository method (`getAll`/`getById`/`create`/`update`/
  `delete`, across dio/chopper/supabase/firebase, offline-first or not) had its
  own `try/catch { return Result.failure(e.toString()) }` — duplicated N times,
  never structured (no status code, no error code, just a raw string). NEAT also
  shipped a full `Failure` sealed-class hierarchy
  (`NetworkFailure`/`ServerFailure`/`CacheFailure`/`UnknownFailure`) that **nothing
  ever constructed or referenced** — dead code in every generated project.
  Chopper additionally force-unwrapped `.body!` on non-2xx responses, producing
  an opaque "Null check operator used on a null value" instead of a status code.
- **The fix**, matching wesioo's `UseCase.call()` pattern exactly:
  - `Failure` is now one concrete class (`message` + `statusCode` + `code` +
    `originalError`), and `Result<T>.failure` carries it (not a `String`).
  - Repositories **throw** — no try/catch, no fallback logic to justify one —
    for remote-only, local-only, and offline-first *write* paths. Chopper
    responses are unwrapped via `unwrapChopperResponse` (throws
    `ChopperApiException(statusCode, body)` on non-2xx, instead of a blind
    `.body!`).
  - `UseCase.call()` is the **one** place exceptions are caught: it wraps
    `execute()` and converts whatever was thrown into a `Failure` via a new
    per-httpClient `NetworkErrorHandler` (dio/retrofit → `DioException`;
    chopper → `ChopperApiException`; supabase → `AuthException`/
    `PostgrestException`; firebase → `FirebaseException`; always a generic
    fallback branch). Presentation invokes usecases via the **callable
    shorthand** (`usecase(params)`) — never `.execute()` directly, which has no
    error handling of its own.
  - **Deliberate exception**: offline-first `getAll`/`getById` keep their own
    try/catch — a network→cache fallback is a resilience *strategy*, not
    boilerplate error handling, so it doesn't fit the generic catch-and-wrap
    model. They return `Result<T>` directly from the repository; their usecase
    unwraps via `result.getOrThrow()` (which throws the `Failure` object itself,
    not a re-wrapped one) so `UseCase.call()` still uniformly re-wraps it —
    every usecase in a generated project is invoked the same way, no exceptions
    to the calling convention.
- `NoParamsUseCase<T>` is now `UseCase<Unit, T>` (wesioo's shape) — `execute`
  takes an (ignored) `Unit` param so the whole hierarchy stays one generic base.
- Harness-proven across **every** httpClient × storage-strategy combination (the
  full 20-test integration suite, not a subset — this refactor's blast radius is
  every single generated feature). Also fixed two bugs found along the way: a
  latent import bug in the Supabase-realtime `StreamNotifier` (introduced by the
  §5c split, watching a provider from the wrong file) and Auth's repository/
  screens not yet updated to the `Failure`-typed `Result`.

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
overlap — pick deliberately. → Phased:
- ✅ **Phase 1 — Entity from a Response JSON** (keep CRUD) — **done**. Paste a
  response JSON → `JsonEntityInferencer` infers a **flat** `List<FieldSpec>`
  (scalars: String/int/double/bool/DateTime; `snake_case`→`camelCase` + `@JsonKey`;
  reserved-word escaping; nested objects/arrays dropped with warnings; a **String
  `id` is always guaranteed** — coerced or synthesised — because CRUD is id-centric).
  The fields flow through the **single** `FeatureScaffolder` path into the
  entity/model (freezed + plain)/mapper/repository/**Drift table** (typed columns)/
  list tile (inferred title field) + skeleton placeholder. Editable preview
  (`EntityFieldsEditor`) wired in **both** the wizard (Architecture step) and the
  **Workshop** add-feature. Harness-proven (FakeStore-ish product JSON → build_runner
  + analyze 0/0). Unit-tested inference + codegen helpers (26 fast tests).
- ✅ **Phase 1.5 — nested objects/lists** — **done**. `FieldSpec` is recursive
  (`kind`: scalar/object/list); the inferencer emits nested objects + lists
  (scalars & objects) at arbitrary depth. Codegen emits a generated sub-class per
  nested object in **both** the entity and model files (freezed: json_serializable
  wires nested fromJson/toJson automatically; plain: hand-written), with deep
  `toEntity()` / `Model.fromEntity()` mappers. Complex fields serialise to a JSON
  `TextColumn` in the Drift cache (encode on write / decode on read), keeping the
  offline round-trip whole. Harness-proven (product JSON with a `rating` object +
  `tags` list → build_runner + analyze 0/0).
- ✅ **Per-feature API path override** — **done**. The REST path was hardcoded as
  `/${featureName}s` (naive plural) in every dio/chopper/retrofit template — broke on
  irregular plurals and coupled the Dart feature name to the resource name/host. Now
  an optional free-text **API path** field (Architecture step + Workshop, same
  symmetry as the JSON-paste field) drives list/create (`$path`) and
  get/update/delete (`$path/$id`); empty → unchanged default. Accepts a relative path
  (prepended to the project's API Base URL) or an **absolute URL**, which overrides
  the host entirely for free — confirmed from the actual chopper/Dio source
  (`Request.buildUri`: "if url starts with http(s), baseUrl is ignored"; chopper's
  `_mergeUri` does plain string concatenation, not RFC-3986 path replacement) — no
  second HTTP client needed. Also fixed a latent bug found while verifying against
  fakestoreapi.com: the create route had a hardcoded `/add` suffix
  (`/${featureName}s/add`) that no real REST API (including FakeStore's actual
  `POST /products`) expects — dropped project-wide.
- ✅ **Example feature (onboarding)** — **done**, later simplified to an
  **opt-in toggle**. The Architecture step no longer offers a 3-way preset
  picker or any entity/JSON-paste editing (that duplicated the Workshop's own,
  more appropriate UI, and cluttered project-creation-time decisions) — just
  one toggle, **"Generate example feature"** (`ArchitectureState.
  generateFirstFeature`, default on, mirrors `flutter create`'s counter app):
  on → FakeStore Products (`FieldSpec.fakeStoreProduct`, exercising the
  Phase-1.5 nested `rating` object) at the **absolute**
  `https://fakestoreapi.com/products` path, so it keeps working no matter
  what the user sets as their own API Base URL; off → the app ships with
  **zero features**, just a placeholder `WelcomePage` owning `/`. Entity/JSON
  editing lives only in the Workshop now. A simple CRUD UI (tap-for-detail +
  delete, an "add" sheet) stays **deliberately scoped to the example feature
  only** (`includeCrudUi`) — general create-edit-delete UI generation for
  arbitrary features is a separate, not-yet-scoped effort.
  - **The "off" fallback**: go_router needs a valid route to boot, so a
    generated `WelcomePage` + `AppRoutePath.welcome` route stand in for the
    first feature — wired through the exact same anchor system
    (`// neat:route-imports` / `// neat:route-entries` / `// neat:routes`)
    the Workshop already uses to add a real first feature later, so nothing
    about that flow changes. A bottom-nav shell needs a first branch, so it's
    disabled (greyed out, with a note) whenever the toggle is off. An
    offline-first project with the toggle off still gets its Drift package/
    database scaffolded, just with zero tables (`@DriftDatabase(tables: [])`)
    — the Workshop's existing table-injection anchor adds the first one once
    a real feature exists. (Along the way: turned off drift_dev's
    `generate_manager` option globally — NEAT never used the fluent
    `db.managers.*` API, and with zero tables its generated `$XxxManager`
    class left an analyzer-breaking unused field.)
  - Harness-proven: dedicated integration tests cover the example-feature
    path (a `ChopperClient` pointed at an unrelated base URL still reaches
    fakestoreapi.com for real, proving the absolute-URL override) and the
    zero-feature path for both plain go_router and go_router_builder routing
    shapes, plus the zero-table Drift case — all build_runner + analyze 0/0.
- **Phase 2 — Typed endpoints**: per-route `method + path + request/response JSON`
  → typed chopper methods + request models. The full vision (N arbitrary routes per
  feature); reshapes the "feature" model + Workshop UI. Reuses the Phase 1 inference
  engine. *Effort L.*
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
