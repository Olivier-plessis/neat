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
  variant of #6, scoped in §6a below.

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

### 5e. Drift schema migration — ✅ (real bug, found via a device run)
- **The defect**: `AppDatabase.schemaVersion` was hardcoded to `1` forever, with
  no `MigrationStrategy` at all. Drift only runs `onCreate` on a **brand-new**
  database file; a table added later (Workshop `_injectDriftTable`, or any
  regeneration) never reaches a device that already has the app installed with
  an older schema — `schemaVersion` never changed, so Drift's default
  migration behavior is a silent no-op. Found from a real user's device log
  (`SqliteException: no such table: product_rows`) after adding a feature via
  the Workshop to an already-running project — the Dart code compiled and the
  providers registered fine, only the on-disk SQLite schema was stale.
- **The fix**: every generated `database.dart` now ships a `MigrationStrategy`
  getter from the start (`onCreate: (m) => m.createAll()`, an `onUpgrade` with
  a `// neat:migrations` anchor) — a no-op structurally, but the hook
  subsequent additions insert into. `GenerateFeatureUsecase._injectDriftTable`
  now bumps `schemaVersion` by 1 and inserts
  `if (from < N) await m.createTable(<table>);` at the anchor every time a
  table is added, self-healing projects generated before this fix (no
  `MigrationStrategy` getter yet) by inserting the whole block after the
  `schemaVersion` getter first. Same anchor-insertion methodology as every
  other `// neat:` mechanism in NEAT.
- Harness-proven: unit tests for the self-heal (idempotent, legacy-format
  input) + reading the current version; the existing Workshop Drift-injection
  integration test now also asserts `schemaVersion => 2`, the `migration`
  getter, and the exact `onUpgrade` step, still analyzing 0/0. Full suite green.

### 5f. Workshop per-feature layer toggles — two real bugs (found via a real project)
- **Bug 1 — chopper registration wired for a file that was never generated**.
  `GenerateFeatureUsecase`'s chopper-decoder wiring only checked
  `httpClient == 'chopper'` (the *project's* stack) before importing/calling
  `register<Feature>ChopperDecoders()` in `bootstrap.dart`. But that function
  only exists inside `<feature>_repository_providers.dart`, which
  `FeatureScaffolder` only writes when `useAnnotations && hasHttpClient &&
  includeUseCases` are **all** true (see 5c). A real generated project
  (Remote Data Source on, **Domain UseCase off**) hit exactly this gap:
  `bootstrap.dart` imported and called a function that was never generated —
  `Error: Method not found: 'registerXChopperDecoders'`. Fixed by mirroring
  the exact same condition at the call site
  (`httpClient == 'chopper' && useAnnotations && effHasHttp &&
  options.includeUseCase`). The affected real project's `bootstrap.dart` was
  hand-repaired to unblock it immediately.
- **Bug 2 — "Local Data Source" was silently ignored whenever Remote was
  off**. `FeatureScaffolder`'s `writeLocal = offlineFirst || !hasHttpClient`
  forced a `_local_source.dart` into existence any time there was no remote
  client, **regardless of the Local Data Source toggle's own value** — so
  turning both Remote *and* Local off in the Workshop still generated an
  unused local source file (and the "Blueprint Overview" preview showed it
  too, via the same `|| !remote` logic). Fixed by making `writeLocal` respect
  `includeLocalSource` uniformly: `offlineFirst || (!hasHttpClient &&
  includeLocalSource)`.
- **Scope decision, made deliberately (not just a bug fix)**: fixing bug 2
  exposed a real product question — should a feature with **zero** data
  sources (Remote off, Local off) even be generatable? Previously
  `FeatureGenOptions.hasAnyDataSource` blocked submission entirely
  ("Pick at least one data source"). Decided **yes** — a pure
  entity + presentation feature (no `data/` layer, no `domain/repositories`
  interface, no usecases — nothing to implement or call without any backing
  store) is a legitimate use case (e.g. a settings/about screen wired up by
  hand later). `FeatureScaffolder` now gates `domain/repositories`,
  `domain/usecases`, `data/models`, and `data/repositories_impl` on a new
  `hasAnyDataSource = hasHttpClient || includeLocalSource` check; the
  Workshop's `canGenerate` no longer requires it, and the blocking orange
  warning became an informational grey note. The presentation layer needed
  **no changes** — `dataList` already naturally evaluates to `false` in this
  combo, so the page/provider templates already fell back to their plain
  placeholder shape.
- Harness-proven: a new integration test generates a feature with Remote/
  Local/Domain UseCase all off, asserts no `data/` directory and no
  `domain/repositories`/`domain/usecases` exist, but `domain/entities` and
  the full `presentation/` layer do, and `flutter analyze` 0/0. A second new
  test covers bug 1 specifically (Domain UseCase off, Remote on): asserts
  `bootstrap.dart` never references the ungenerated file, analyze 0/0. Full
  suite green, including every pre-existing packageSplit/chopper/Step 2b
  test (this touches the same call site chopper registration threads
  through).

### 5g. Offline-first build_runner failure — a real (external, upstream) bug

Reported from a real generated project (`flex_app`: packageSplit + offlineFirstSync
+ FlexColorScheme + chopper + go_router_builder + i18n): `database.g.dart` never
generated, cascading into dozens of "Type 'X' not found" kernel errors across
every package that touches Drift (`_local_storage`, `_core`'s `SyncService`, the
witness feature's local source) — none of it related to the actual Dart source,
which analyzed fine once the missing generated file was produced by hand.

Root cause traced to `dart run build_runner build` itself failing to compile:
`drift_dev 2.34.0`'s query analyzer calls `DartPlaceholder.when(...)`, a method
`sqlparser` **removed** in `0.44.6` — published under a `^0.44.0`-compatible
version bump, so pub resolves it without any conflict; the break only surfaces
at drift_dev's own codegen time. Not fixable by bumping `drift_dev` either:
`2.34.1`/`2.34.2` "fix" it by bumping their own `analyzer` constraint to
`^13.0.0`, which then conflicts with `go_router_builder 4.3.0`'s `<13.0.0` cap
— so every currently-published drift_dev version is broken in some way for a
packageSplit + offline + typed-routing project.

**Fix**: `LaunchGenerationUsecase.buildPubspecContent` now writes a
`dependency_overrides: sqlparser: ">=0.44.0 <0.44.6"` block at the workspace
root whenever offline-first is on (same `addConnectivity` signal that already
adds `connectivity_plus`) — a pub workspace resolves one version of every
package for the whole tree, so the override has to live at the root, not in
`packages/<app>_local_storage`'s own pubspec. Revisit/remove once drift_dev
ships a release that supports sqlparser ≥0.44.6 **and** keeps an
analyzer constraint go_router_builder 4.3.0 can satisfy.

Harness-proven: `pubspec_builder_test.dart` gained two cases (override present
+ pinned to the exact range when `addConnectivity: true`; absent otherwise).
The real `flex_app` project was hand-patched with the same override, verified
`dart run build_runner build` + `flutter analyze` clean across the whole
workspace (1 unrelated pre-existing unused-import warning aside). Full suite
green.

### 6. Multiple architectures — later, with caution
- The harness makes **every** architecture a ~3× maintenance cost (each must be proven).
  **Clean done deeply > 3 architectures done shallowly.** If adding one, MVVM at most;
  MVC is dated in Flutter. Don't dilute the moat to match a competitor's brochure.

### 6a. Modular Monorepo — per-feature packages (opt-in) — in progress
> Idea (from a `kido-luci/flutter-starter-template` comparison): let each feature be
> its own Dart workspace package (`packages/<feature>/`, own `pubspec.yaml`,
> `resolution: workspace`) instead of a folder under `lib/features/`. Motivation: a
> team where each dev owns a feature gets real package boundaries (can't
> accidentally import another feature's internals) and an explicit dependency graph
> (pubspec `path:`/workspace deps instead of arbitrary Dart imports) — better
> coordination than a single shared `lib/`. An opt-in wizard toggle, not a
> replacement for the flat layout.
>
> Confirmed by reading kido-luci's actual repo (not guessed): it's a **workspace +
> anchor-insertion** pattern — `# fst:feature:<name>:start/end` +
> `# fst:add-feature inserts above this line`, exactly NEAT's own `// neat:...`
> anchor mechanism, just aggregating **packages** instead of files. NEAT already
> proves this exact plumbing for `<app>_ui`/`<app>_local_storage`. DI stays
> **Riverpod** — no need to adopt kido-luci's `get_it`/`injectable` service locator;
> Riverpod providers are plain top-level objects, importable across packages with no
> extra indirection needed until two features need to reference each other's types
> (their `shared_contracts` package solves that — out of scope until Phase 3, see
> below).
>
> **Real cost, not hand-waved**: every template under `feature_scaffolder.dart`
> assumes `package:$app/features/$name/...` import strings — a package-relative
> variant is mechanical but touches every layer. Sequenced like Supabase/Firebase/
> i18n before it: prove the smallest combo first, then expand coverage.
>
> - ✅ **Phase 1, step 1 — shared `<app>_core` workspace package** — **done**.
>   Discovered while implementing (bigger than the original scope below let on):
>   a feature package can never depend on the app itself — the app already
>   depends on its feature packages, and a pub workspace forbids cycles. Without
>   a shared package sitting *below* both, `Result`/`Failure`/`UseCase`/
>   `NetworkErrorHandler` would have to be duplicated inside every feature
>   package, which defeats the entire point (a bug fixed in one usecase base
>   class should never need fixing in N places). `<app>_core` now ships this
>   Phase-1-minimal slice — `Result`, `Failure`, `UseCase`/`NoParamsUseCase`/
>   `Unit`, a dio-only `NetworkErrorHandler`, a plain (no envied) `dioProvider` +
>   its `LoggerInterceptor`/`AppLogger`, and `AppRoutePath` — gated behind
>   `ArchitectureState.packageSplit`, wired into the root `workspace:`/`path:`
>   exactly like `<app>_local_storage`/`<app>_ui` already are. Every file is
>   generated by **reusing the existing app-level templates** unchanged, just
>   pointed at the core package's own name instead of the app's — no new
>   template logic needed for the content itself, only for where it's written.
>   Envied/`AppEnv` stays out of the core package for now (it would need an
>   interface/implementation split to be shareable — deferred).
>   - **Borrowed from kido-luci's own `packages/architecture`** (read on
>     request): a `Future<T>.fire()` extension (sugar for `unawaited(this)`) —
>     small, low-risk, genuinely useful, added to `<app>_core`.
>   - **Deliberately not borrowed**: their sealed `Failure` hierarchy with named
>     subtypes (`NotFoundFailure`, `ValidationFailure`, ...) — NEAT simplified
>     *away* from exactly this shape earlier (§5d) because a hand-rolled
>     hierarchy was dead code nothing ever constructed; a generator can't know a
>     generated project's domain-specific failure taxonomy upfront the way a
>     hand-written app can. Their `sealed Result<Ok/Err>` (pattern-matchable,
>     more idiomatic Dart 3 than our `fold()`-callback style) is a genuinely
>     interesting idea but a rename that would ripple through every template
>     already using `.fold`/`.getOrThrow` — parked, not adopted, revisit later.
>   - Harness-proven: an integration test generates `packageSplit: true` alone
>     (no feature depends on it yet), asserts the package's files/content and
>     the root workspace wiring, and confirms `flutter analyze` 0/0 for the
>     whole workspace (including running the core package's own `dioProvider`
>     `@Riverpod` codegen — build_runner runs per-package in a workspace, same
>     as the Drift package already does).
> - ✅ **Phase 1, step 2a — split the wizard's first feature — done**. Same
>   narrow combo as scoped: feature-first + Riverpod annotations + dio +
>   remote-only + plain go_router + exactly one feature.
>   - `feature_scaffolder.dart` takes `packageSplit`/`corePackageName`: a third
>     `domainBase`/`dataBase`/`presentationBase` branch (`$lib/domain`,
>     `$lib/data`, `$lib/presentation` — the package root **is** the feature, no
>     `features/<name>/` nesting, and no layer-first variant, since splitting by
>     feature only makes sense feature-first).
>   - Every self-referencing `package:$app/features/$name/...` import (domain ↔
>     data ↔ presentation, ~30 call sites across `domain_templates.dart`/
>     `data_templates.dart`/`presentation_templates.dart`) became a **relative**
>     import instead (`../../domain/entities/...` etc.) — works unchanged in both
>     flat and split layouts, since the nesting depth between layers is the same
>     either way; only the absolute prefix differed. This also let several
>     now-unused `packageName` params get deleted outright (`featureModel`,
>     `featureApiSource`, `featureLocalSource`, `featureUsecaseProviders`,
>     `featureRoute`) instead of threading dead params through.
>   - The handful of *genuine* cross-package imports (usecases' and the
>     repository-providers' `core/usecases/use_case.dart` / `core/result/
>     result.dart` / `core/network/dio_provider.dart`, the list page's
>     `core/error/failure.dart`) took a new optional `corePackageName` param,
>     redirecting to the step-1 core package instead of the app.
>   - **Scope surprise, resolved**: `core/theme/theme_mode_controller.dart` is a
>     single app-wide *stateful* Riverpod provider — the app shell's
>     `MaterialApp` watches it (`themeMode:`) and the generated list page's
>     dark-mode toggle both reads and writes it. Unlike the stateless
>     Result/Failure/UseCase files, this can't be duplicated (app copy + core
>     copy would be two different provider instances — the feature page's
>     toggle would silently stop affecting the app's actual rendered theme). Now
>     single-sourced: `_writeCorePackage` also writes it into `<app>_core`, the
>     app **stops** writing its own local copy when `packageSplit` is on, and
>     `appDart()` imports `theme_mode_controller.dart` from the core package
>     instead of the app-relative path.
>   - The root app's `routesManual()` keeps writing its own `AppRoutePath` (an
>     app-internal reference, not a package-boundary crossing) but now takes
>     `featurePackageName` for the one import that *does* cross the boundary —
>     the split feature's page (`package:<app>_<feature>/presentation/pages/
>     <feature>_page.dart` instead of `package:$app/features/$name/...`).
>   - New feature-package `pubspec.yaml` (`CorePackageTemplates.featurePackagePubspec`)
>     depends on `<app>_core` via `path: ../<app>_core`, never on the app.
>     Needed `sdk: ^3.7.0` (not the other packages' `^3.6.0`) — the generated
>     list page's `ListView.separated` uses a wildcard pattern (`(_, _) => ...`)
>     that the analyzer rejects below language version 3.7.
>   - `launch_generation_usecase.dart` writes the feature package's pubspec,
>     redirects `FeatureScaffolder`'s `lib` root to `packages/<pkg>/lib`, adds it
>     to the root `workspace:`/`path:` wiring, and runs its own `build_runner`
>     pass — the same per-package pattern as `<app>_local_storage`/`<app>_core`.
>   - **Harness-proven**: the Phase 1 integration test (packageSplit + the
>     default first feature) asserts the feature's files live under
>     `packages/<app>_<feature>/` (package-root layout, not `features/<name>/`),
>     every cross-boundary import resolves correctly (core for
>     Result/Failure/UseCase/dio/theme, relative for same-feature refs, never
>     `package:$app/...` — that would be the forbidden cycle), the app's own
>     `theme_mode_controller.dart` is absent, `routes.dart` imports the split
>     page, the root `workspace:`/`path:` lists both packages, and `flutter
>     analyze` passes 0/0 for the **whole workspace**. Full 24-test suite still
>     green — zero regressions.
> - ✅ **Phase 1, step 2b — Workshop adds a second feature package — done**.
>   Real bug this closed: `GenerateFeatureUsecase` had **zero** awareness of
>   `packageSplit` — every Workshop-added feature landed in `lib/features/`
>   under the app regardless of how the project was generated (found by the
>   user generating a real test project and noticing the new feature never
>   left `lib/`). Root cause: the Workspace Contract (`.neat.json`) never
>   recorded `packageSplit` at all, so the Workshop had no way to know.
>   - `NeatContract` gained a `packageSplit` bool (derived convention-based
>     naming, same as `localStoragePackage`/`uiPackage` already do — no need to
>     persist `corePackageName`/per-feature package names separately).
>     `LaunchGenerationUsecase` now writes it.
>   - `ProjectLoader.scanFeatures` was hardcoded to scan `lib/features/` —
>     useless for a split project (features never live there). Now
>     packageSplit-aware: scans `packages/` for `<projectName>_<feature>`
>     dirs, excluding the non-feature siblings (`_core`/`_local_storage`/`_ui`).
>   - `GenerateFeatureUsecase.execute` now derives `corePackageName`/
>     `featurePackageName` from the contract, writes the new package's own
>     `pubspec.yaml` (`CorePackageTemplates.featurePackagePubspec`, same as the
>     wizard's first feature), wires it into the root `workspace:`/`path:`
>     (two new idempotent pubspec-editing helpers), and points
>     `FeatureScaffolder` at `packages/<pkg>/lib` instead of the app's `lib/`.
>   - Route wiring (`_wireRoutes`/`_wireShellBranch*`) now crosses into the new
>     feature package instead of `features/<name>/`, **and** mirrors the new
>     `AppRoutePath` constant into the core package's own copy — a split
>     feature imports `AppRoutePath` from core, never the app, so core's copy
>     needs the constant too or the new route wouldn't compile.
>   - **Found and fixed in passing** (same root cause, different call site):
>     the *wizard's own* first-feature-split path had never actually been
>     exercised combined with `useNavigationShell` — `appShellRouteBuilder`/
>     `routesManualShell` hardcoded `features/<name>/` imports unconditionally,
>     so a wizard user picking shell nav + packageSplit together would have
>     gotten a broken import. Fixed both templates to take an optional
>     `featurePackageName` and threaded it from `LaunchGenerationUsecase`
>     too, not just the Workshop path.
>   - **Scoped out, rejected with a clear error**: nesting a new feature as a
>     *child route* under an existing packageSplit feature. That would need a
>     `path:` dependency from the parent package onto the child — a genuine
>     cross-feature-package dependency, exactly the problem Phase 3
>     (`shared_contracts`) exists to solve. `GenerateFeatureUsecase` now throws
>     a clear exception instead of generating a broken/undeclared import.
>     Shell branches stay supported (app→feature, never feature→feature, so no
>     new dependency problem).
>   - Chopper: the split feature already self-registers its own
>     `register<Feature>ChopperDecoders()` (existing `packageSplit`+chopper
>     machinery in `FeatureScaffolder`/`DataTemplates` — no changes needed
>     there). The only new piece is wiring `bootstrap.dart`'s
>     `// neat:chopper-register-imports`/`-calls` anchors (previously only the
>     wizard's first feature used them) — a new `_registerChopperDecoderSplit`
>     mirrors the wizard's own bootstrap wiring instead of editing the
>     (now-absent, see the core/ cleanup above) app-local
>     `chopper_model_converter.dart`.
>   - Harness-proven: two new integration tests — a dio top-level-route
>     scenario (asserts the new package/pubspec/workspace-wiring/route-import/
>     both AppRoutePath copies/reload-sees-both-features/non-destructive-guard/
>     child-route-rejection, `flutter analyze` 0/0 for the 3-package
>     workspace) and a chopper scenario (asserts the new feature's own
>     registration function + `bootstrap.dart`'s anchors, analyze 0/0). Full
>     fast + integration suites still green, including the pre-existing
>     `navigation-shell` test (confirms the `featurePackageName` param addition
>     didn't regress the non-split shell path).
> - ✅ **Wizard UI toggle — done**. `architecture_screen.dart`'s "Modular
>   Monorepo" section: a toggle gated on `canPackageSplit` (mirrors
>   `launch_generation_usecase.dart`'s `packageSplitSupported` — the generator
>   re-derives the combo independently rather than trusting the raw flag, the
>   same safety net `hasAuth`/`hasRealtime`/`hasStorage` already use, since the
>   UI only *disables* the toggle outside the combo, it doesn't reset the
>   underlying flag). Disabled with an explanatory message outside the combo;
>   the live folder-tree preview and the first-feature path hint both reflect
>   `packages/<app>_<feature>/` when active (`GenerateTreeUsecase` gained a
>   `packageSplit`/`packageName` param for this).
> - ✅ **Chopper support — done**. The one genuinely hard part: chopper's model
>   decoding fix (`chopperModelDecoders`, a `Type → decoder` registry) is
>   normally populated by anchor-inserting each feature's entry directly into
>   the registry file — impossible once split, since the registry now lives in
>   `<app>_core` and core importing every feature's Model to populate itself
>   would recreate the exact app←feature cycle packageSplit exists to avoid.
>   Fixed by flipping the direction: the registry starts genuinely empty in
>   core (no witness), and each split feature generates its own
>   `register<Feature>ChopperDecoders()` function (in its own
>   `<feature>_repository_providers.dart`, importing only its own Model +
>   core's registry — a downward-only import, no cycle). The app's
>   `bootstrap.dart` imports and calls it before `runApp` (gained
>   `// neat:chopper-register-imports`/`// neat:chopper-register-calls`
>   anchors, mirroring the router aggregator's own anchor pair, for when step
>   2b lets a second split feature register itself too). The non-split chopper
>   mechanism (anchor-insertion straight into the registry file) is completely
>   untouched — this new path only exists when `packageSplit` is on.
>   `_writeCorePackage` also stopped hardcoding `httpClient: 'dio'` — it now
>   threads the actual client through, so `NetworkErrorHandler` and which
>   client provider ships (dio for dio/retrofit, chopper's client +
>   witness-free converter for chopper) both match the real stack.
>   `packageSplitSupported`/`canPackageSplit` widened to `dio || chopper`.
>   Harness-proven: a new integration test generates packageSplit + chopper +
>   a first feature, asserts the registration function/call/anchors, that core
>   and the app's own dead-code copy both stay witness-free, and `flutter
>   analyze` passes 0/0 for the whole workspace. Full suite still green.
> - ✅ **Phase 2, go_router_builder — done**. `CoreTemplates.featureRoutes()`
>   (the per-feature typed route file) and `routesAggregator()` (the app's
>   aggregator) got the exact same package-aware treatment `routesManual()`/
>   `featureRoute()` already had for manual routing: `featureRoutes()` gained
>   `corePackageName` to redirect its `AppRoutePath` import (the feature's own
>   page import was already convertible to relative — same package, no
>   change needed there); `routesAggregator()` gained `featurePackageName` to
>   redirect the one legitimate app→feature-package import (the typed routes
>   file itself). go_router_builder's own codegen (`part '<feature>_routes.g.dart'`)
>   just runs inside the split feature package's own build_runner pass —
>   already wired, same as freezed/riverpod_generator. `featurePackagePubspec()`
>   gained a `hasGoRouterBuilder` param adding the generator as a dev dep.
>   `packageSplitSupported`/`canPackageSplit` widened to drop the
>   `!hasGoRouterBuilder` restriction — manual and typed routing both work now.
>   No decoder-registry-style problem here (unlike chopper): go_router_builder
>   has no cross-feature shared mutable state to worry about.
>   Harness-proven: a new integration test generates packageSplit +
>   go_router_builder + a first feature, asserts the AppRoutePath/page import
>   redirects, that the aggregator crosses into the split package, that the
>   feature package's own build_runner produced its `.g.dart`, and `flutter
>   analyze` passes 0/0 for the whole workspace. Full suite still green (one
>   pre-existing unit test's assertion updated to match the new relative
>   self-import, not a behavior regression).
> - ✅ **Phase 2, offline-first + Drift (read-only, no sync/Outbox yet) —
>   done**. `_local_storage` needed no changes at all — it's already a leaf
>   package with nothing else in the workspace depending on it, so both the
>   core package and a split feature package can depend on it directly
>   without creating anything resembling a cycle. The real work was
>   `network_info.dart` + `infrastructure_providers.dart` (the shared
>   `appDatabaseProvider`/`networkInfoProvider` singletons every offline-first
>   feature reuses) moving into the core package, and redirecting
>   `featureRepositoryImpl()`'s offlineFirst branch (Failure/NetworkInfo/
>   Result/AppLogger) + `featureRepositoryProviders()`'s offlineFirst branch
>   (`infrastructure_providers.dart`) to `corePackageName` — the exact same
>   mechanical pattern as every other boundary this phase. Both the core
>   package's and the feature package's own pubspecs gained a sibling `path:`
>   dep on `_local_storage` + `connectivity_plus` where needed.
>   `packageSplitSupported`/`canPackageSplit` widened from "remote-only only"
>   to "remote-only or offline-first-read" — sync/Outbox (`hasSync`) stays
>   out of scope for now, since `sync_service.dart` hasn't had the same
>   core-package treatment yet.
>   - **Also fixed in passing (real bug, unrelated to packageSplit, found
>     because it broke this test)**: `ThemeTemplates.appGap()`'s
>     `useScreenUtil` branch applied `.w`/`.h`/`.sp` to an *already-built*
>     `SizedBox`/`EdgeInsets` instead of to the raw number before wrapping it
>     — those extensions are declared on `num`, not on `SizedBox`/
>     `EdgeInsets`, so it never compiled. Reproduced on a pre-existing,
>     completely unrelated test (`offline-first generates a valid Dart
>     workspace`) to confirm it predated this session's packageSplit work.
>   - **Scope surprise, resolved**: verified empirically (a standalone 2-package
>     workspace reproduction, not just reasoning) that Dart pub workspaces do
>     **not** actually block a member from importing another member's
>     `package:` URI just because its own `pubspec.yaml` doesn't declare that
>     dependency — `dart analyze`/`flutter analyze` resolves every workspace
>     member via one shared `package_config.json` regardless. So the
>     "forbidden cycle" this whole packageSplit epic is framed around isn't
>     literally enforced by the analyzer today — it's a deliberate discipline
>     (never import the app from a feature package) that matters the moment a
>     feature package is ever pulled out of the workspace into its own repo,
>     which is the actual point of packageSplit. Found and fixed one place
>     this discipline had lapsed: `featureRepositoryImpl()`'s chopper
>     branch imported `chopper_model_converter.dart` from the app
>     unconditionally, never redirected to `corePackageName` — invisible to
>     `flutter analyze` inside the workspace, but wrong all the same. Now
>     fixed alongside this phase's other redirects.
>   - Harness-proven: a new integration test generates packageSplit +
>     offline-first + a first feature, asserts the core package ships
>     NetworkInfo/infrastructure_providers.dart and depends on `_local_storage`,
>     that the feature package's repository/providers/local source all cross
>     into the right packages (core for infra, `_local_storage` directly,
>     never the app), and `flutter analyze` passes 0/0 for the whole
>     (now 3-package) workspace. Full suite still green.
> - ✅ **Clean up the app's duplicated `core/` — done**. Every phase above
>   redirected split features to import `<app>_core`'s copy of a file, but the
>   app itself kept writing its own witness-free copy of the same file too —
>   pure dead code nothing in the app read anymore. Now every app-level file
>   that becomes 100% dead once split is skipped entirely (gated on
>   `corePackageName == null`): `result.dart`, `use_case.dart`, `failure.dart`,
>   `network_error_handler.dart`, `logger_interceptor.dart`, `dio_provider.dart`,
>   `chopper_model_converter.dart`/`chopper_client_provider.dart`,
>   `network_info.dart`, `infrastructure_providers.dart`, `app_logger.dart`.
>   Files the app still genuinely needs but that reference one of the above
>   (`error_handler.dart`, `provider_observer.dart`, `bootstrap.dart`) keep
>   being written, just with their internal `AppLogger` import redirected to
>   `corePackageName ?? packageName` instead of duplicating it — the same
>   redirect pattern as every other cross-boundary import this phase. Left
>   deliberately untouched: `app_route_path.dart` — purely cosmetic duplication
>   (no shared mutable state, unlike `theme_mode_controller`/`app_logger`),
>   referenced by 8+ router-template call sites, higher blast radius than
>   payoff for now.
>   Harness-proven: the existing packageSplit+chopper test's assertion changed
>   from reading the app's dead `chopper_model_converter.dart` content to
>   asserting the file no longer exists at all. Full targeted (dio/chopper/
>   go_router_builder/offline-first), fast (`--exclude-tags integration`,
>   165/165), and full integration (`--tags integration`) suites all green —
>   zero regressions.
> - ✅ **Phase 2, offline+sync/Outbox — done**. Same mechanical redirect
>   pattern as every other core/-boundary fix this phase: `sync_service.dart`
>   moves into the core package when packageSplit is on (`_writeCorePackage`
>   gained `hasSync`), the app stops writing its own copy (dead code, gated on
>   `corePackageName == null` — same as every file in the "clean up the
>   duplicated core/" note above), and `featureRepositoryProviders()`'s one
>   remaining unredirected import (`core/sync/sync_service.dart` — the only
>   spot in that function still hardcoded to `packageName`) now uses
>   `corePackageName ?? packageName`. `packageSplitSupported`/`canPackageSplit`
>   dropped the `!hasSync` restriction — every storage strategy (remote-only,
>   offline-first read, offline-first + sync) now works with packageSplit.
>   Harness-proven: a new integration test generates packageSplit +
>   `offlineFirstSync`, asserts core ships `sync_service.dart` importing its
>   own `network_info.dart`, the app has no copy, the split feature's
>   `SyncService` provider crosses into core, and `flutter analyze` 0/0. Full
>   suite still green.
> - ✅ **Phase 2, Supabase/Firebase backends — done**. Dropped `!hasBackend`
>   from `packageSplitSupported`/`canPackageSplit` — dio/chopper/supabase/
>   firebase all work now, with auth/realtime/storage.
>   - `_writeCorePackage` gained `httpClient == 'supabase'/'firebase'`
>     branches (mirrors dio/chopper exactly) writing `supabase_provider.dart`/
>     `firebase_provider.dart` into core; the app's own copies are skipped
>     when split (same dead-code gating as every other core/-boundary file).
>     `networkErrorHandler` needed no changes — it was already httpClient-
>     driven (dio/chopper/supabase/firebase branches all pre-existed from
>     §5d), just never actually exercised with `corePackageName` before since
>     the combo was excluded.
>   - **Auth becomes its own workspace package too — `packages/<app>_auth/`**
>     (superseding an earlier draft of this note that kept Auth app-level).
>     Compared directly against **wesioo**: it splits auth into a standalone
>     `packages/authentication` with **zero** workspace dependencies — its own
>     `Result`/`Failure`/`UseCase`/network interceptors/secure storage,
>     literally copy-pasteable into another app — while its screens/routes/
>     form-state stay in `lib/features/auth/`. NEAT deliberately diverges:
>     the whole feature (screens included) moves into the package, but it
>     depends on `<app>_core` for `Result`/`Failure`/`UseCase` like every
>     other split feature, rather than duplicating them — consistent with
>     NEAT's own single-core-dependency model, and avoiding a second,
>     divergent "zero-dep package" pattern that would only exist for Auth.
>     Mechanically the same conversion as Phase 1 Step 2a's first split
>     feature: `AuthTemplates` gained `authPackageName` (relative self-imports
>     for same-feature references, e.g. `authRepositoryImpl`'s
>     `i_auth_repository.dart` import) alongside the existing
>     `corePackageName` (Result/Failure/client-init-provider/`AppRoutePath`
>     redirects). `router_notifier.dart` — the go_router guard — always stays
>     app-level (it's plumbing, not a feature) but its `auth_provider.dart`
>     import now crosses into the auth package when split, mirroring how
>     `routesAggregator` already crosses into any other split feature's page.
>     `_writeAuth` writes the package's own `pubspec.yaml` (reusing
>     `CorePackageTemplates.featurePackagePubspec`, the same function every
>     other split feature's pubspec already uses), and the auth route
>     aggregator import/build_runner pass follow the established per-package
>     pattern. `ProjectLoader.scanFeatures`'s `nonFeatureSuffixes` gained
>     `'auth'` so the Workshop doesn't mistake the auth package for an
>     addable/existing CRUD feature.
>   - **Another real bug found via a failing integration test**:
>     `_writeCorePackage`'s call to `CoreTemplates.appRoutePath()` never
>     passed `hasAuth`, so core's `AppRoutePath` mirror never got the
>     `login`/`signup`/`forgotPassword` constants — invisible until Auth
>     actually became a package that imports `AppRoutePath` from core (every
>     auth screen/route file failed to resolve `AppRoutePath.login` etc.).
>     Fixed by threading `hasAuth` through that call, mirroring the app's own
>     already-correct call.
>   - `storage_service.dart`/`avatar_upload_field.dart` stay app-level
>     (nothing NEAT generates imports them cross-package), but
>     `storageService()`'s one import of the client-init provider still
>     redirects to `corePackageName ?? packageName`, since *that* file does
>     move when split.
>   - **Two real bugs found and fixed along the way** (both pre-existing,
>     never exercised before since backend+packageSplit was excluded):
>     1. `CorePackageTemplates.pubspec()` never added `supabase_flutter`/
>        `cloud_firestore` (+ `firebase_auth`/`firebase_storage` when
>        auth/storage are on) to the core package's own dependencies — it
>        only ever branched on chopper vs. dio. Without this, riverpod
>        codegen for `supabase_provider.dart`/`firebase_provider.dart`
>        silently failed to produce its `.g.dart`, cascading into
>        `Undefined name 'supabaseClientProvider'` everywhere that imported
>        it. Now a full `switch` on `httpClient` adds the right SDK dep(s).
>     2. `PresentationTemplates._riverpodListStreamNotifier` (the realtime
>        list notifier — `dataList && realtime`) hardcoded its two
>        same-feature imports (`_repository_providers.dart`/`_entity.dart`)
>        as `package:$packageName/features/$featureName/...` instead of a
>        plain relative import, unlike every other same-feature cross-layer
>        import in this codebase. Invisible outside packageSplit (the app
>        always resolves its own package name), but a genuine feature→app
>        import once split. Fixed to match `_riverpodListNotifier`'s existing
>        relative-import convention; the now-fully-unused `packageName` param
>        was deleted from `featureProvider()` rather than threaded through
>        dead (one call site, `feature_scaffolder.dart`).
>   - Harness-proven: two integration tests — packageSplit + Supabase + auth
>     (asserts core ships `supabase_provider.dart`, nothing is left under
>     `lib/features/auth/`, the auth package's `Result`/`Failure`/client
>     imports redirect to core while its self-reference stays a relative
>     import, `router_notifier.dart` crosses into the auth package, and the
>     split feature's own DI crosses into core too) and packageSplit +
>     Firebase + auth + realtime + storage (same, plus `firebase_provider.dart`'s
>     auth/storage singletons, the realtime `watchAll()` stream, and
>     `storageService`'s redirected import) — both `flutter analyze` 0/0.
>     Full suite (including every pre-existing non-split Supabase/Firebase
>     test, which stays on the unsplit `lib/features/auth/` path unchanged)
>     still green.
> - ✅ **Retrofit dropped entirely** — it was never selectable in the wizard
>   (`isUnsupportedPackage`) and its API-source template had zero
>   generation-harness coverage, so "Phase 2, remaining — retrofit" above was
>   never going to close. Removed rather than left gated: the `retrofit`
>   preset/enum value/template branch, `hasRetrofit`/`isRestClient`/
>   `isDioBased`/`isDioLike` derivations, the disabled "Retrofit" card on the
>   Infrastructure screen, and every doc-comment mention across the generator.
>   `isUnsupportedPackage` still blocks `retrofit`/`retrofit_generator` by name
>   (a pub.dev search shouldn't look like a dead end), and
>   `dev_packages_whitelist.dart` still lists `retrofit_generator` alongside
>   every other never-implemented generator (hive_generator, auto_route_generator,
>   etc.) — both deliberately untouched for consistency. Chopper remains the
>   one annotation-driven REST client; dio the one plain one. Full suite green.
> - ✅ **i18n scoping — resolved: no per-package split, but a real bug fixed**.
>   Raised by comparing against `maxit-front-flutter` (a real multi-dev Melos
>   monorepo) — its `packages/feature/<name>/` each ship their own `l10n.yaml`
>   + prefixed `.arb` files, rather than one global translation file. Decided
>   **against** replicating that for NEAT's slang setup:
>   - slang's config only reads from **one** `input_directory` — it can't
>     aggregate `.i18n.json` files that live in genuinely separate workspace
>     packages (each with its own `lib/`) into one generated class. Doing this
>     "properly" would need either independent slang instances per package
>     (unverified whether slang exposes a clean way to avoid a `Translations`/
>     `AppLocale`/`context.t` symbol collision the moment a page needs two
>     packages' translations at once) or a fragile file-copying step.
>   - Translations are cross-cutting by nature (shared strings, the language
>     switcher itself) — unlike code, which has clear per-feature ownership.
>     Even maxit keeps its own app-level `l10n/` for shared strings alongside
>     the per-feature split — a hybrid, not a clean per-package boundary. The
>     real problem it solves there (merge contention on one shared JSON file
>     across a big team) is a softer problem than the cycle discipline the
>     redirects elsewhere in this section solve.
>   - **Found and fixed a real bug while scoping this**: unlike every other
>     cross-cutting concern (`theme_mode_controller`, `AppLogger`, dio/
>     chopper providers), i18n had **never** been redirected to
>     `corePackageName` at all — a split feature's page, `bootstrap.dart`, and
>     `app.dart` all unconditionally imported slang's `strings.g.dart`/
>     `LanguageSwitcher`/`LocaleStore` from the **app**, a genuine
>     feature→app import (the exact cycle packageSplit exists to avoid),
>     simply never caught because no test combined `packageSplit` + i18n
>     before. Fixed the same way as everything else in this section: the
>     whole slang setup (config, translation files, generated
>     `strings.g.dart`, `locale_store.dart`, `language_switcher.dart`, the
>     `dart run slang` codegen pass) is now single-sourced in the core
>     package when `packageSplit` is on — the app stops writing its own copy
>     entirely, and `PresentationTemplates`/`AppTemplates.appDart`/
>     `AppTemplates.bootstrap` all redirect to `corePackageName ?? packageName`.
>     `CorePackageTemplates.pubspec` gained a `hasI18n` param for the slang/
>     `shared_preferences` deps. Harness-proven: a new integration test
>     generates packageSplit + i18n, asserts core ships the whole setup, the
>     app has zero i18n files of its own, and the split feature's page/
>     bootstrap.dart/app.dart all cross into core, never the app — `flutter
>     analyze` 0/0. Full suite still green.
> - **Phase 3 — cross-feature contracts**: two features that need to reference
>   each other (the actual reason for a `shared_contracts`-equivalent package) —
>   deferred until Phase 1/2 are solid, since it's a genuinely separate design
>   question (what belongs in the shared package, and when).
> - Everything else (Supabase/Firebase, auth, i18n, realtime, flavors, CRUD-UI,
>   layer-first) stays **out of scope** until its own phase — don't combine an
>   unproven structural change with unrelated unproven combos.

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
Layer-first · bloc/cubit.
(retrofit was gated too — dropped entirely instead; manual Riverpod was gated
too — unlocked instead, see § below.)

- ✅ **Manual Riverpod (no @riverpod annotations) — unlocked**. The gate was
  real: `_riverpodManualTemplate` (the feature provider) and
  `themeModeControllerRiverpodManual` both generated `StateNotifier`/
  `StateNotifierProvider`, which `flutter_riverpod` 3.x moved out of its main
  barrel into `package:riverpod/legacy.dart` — the generated code simply
  wouldn't compile. Migrated both to the modern `Notifier`/`NotifierProvider`
  API (no legacy import, no deprecation). The "Use @riverpod annotation
  syntax" toggle in Architecture (previously locked ON) now actually toggles
  `useRiverpodAnnotations` — `toggleRiverpodAnnotations` already existed on
  the notifier, only the UI lock and the templates were blocking it. One real
  scope boundary stays, by design, not a bug: manual mode's usecase-level DI
  graph is annotation-only (`dataList = useAnnotations && hasHttpClient &&
  includeUseCases`), so the FakeStore Products witness feature degrades to a
  placeholder page + Notifier stub in manual mode rather than the full-CRUD
  example — the "Generate example feature" toggle's description now says so
  conditionally instead of overpromising. Harness-proven: a new integration
  test generates a manual-Riverpod project (no riverpod_annotation/
  riverpod_generator in the manifest) and asserts both generated files use
  `Notifier`/`NotifierProvider` with zero `StateNotifier` references, 0/0
  analyze. Full suite green.

## Deferred refinements
- ✅ **Outbox exponential backoff & conflict resolution — done**.
  `OutboxEntries` gained `nextRetryAt` (backoff deadline) and `hasConflict`
  (set aside from ordinary retries) columns. `SyncService.flush()` skips
  entries whose backoff hasn't elapsed, computes 5s/10s/20s.../5min-capped
  delays via `_backoffFor`, and self-reschedules a `Timer` for the earliest
  pending retry — recovery no longer depends solely on a connectivity flap.
  `OutboxReplay` now returns a `ReplaySyncResult` (`success`/`retry`/
  `conflict`) instead of `bool`: a `conflict` result parks the entry via
  `AppDatabase.markConflict` (surfaced through `SyncService.conflictedWrites`,
  resolved via `AppDatabase.resolveConflict`) rather than looping it through
  ordinary retries — the generator supplies the plumbing, not a guessed merge
  policy, since only the app author's backend knows what a conflict means for
  them. `docs/OFFLINE.md`'s generated guide documents both. Full suite green.
- ✅ **FlexColorScheme Playground import — done, and a real bug fixed**.
  `appThemeFlexColorScheme` used to have two divergent, untested paste-shape
  heuristics: a "full file" branch (`code.startsWith('import')`) that spliced
  the user's pasted code in **as the entire file** — meaning it only worked if
  the paste happened to define a class named exactly `AppTheme` with
  `light`/`dark` matching what `app.dart` references, which the feature's own
  in-UI hint text example (a `Palette` class) would have violated, breaking
  generation — and a "partial" branch that wrongly assumed `.toTheme` was
  needed (that's `FlexColorScheme.light(...).toTheme`'s contract, not
  `FlexThemeData.light(...)`, which already returns `ThemeData`). Neither path
  had integration coverage. Replaced both with one paren-matching extraction
  (reusing the existing `_findMatchingParen`): pull the
  `FlexThemeData.light(...)`/`.dark(...)` (or `FlexColorScheme.x(...).toTheme`)
  call **expressions** out of whatever the user pasted — imports, wrapper
  class/field names, comments — and slot them into NEAT's own always-correct
  `AppTheme` class; `dark` is optional and derived from `light` when absent.
  Harness-proven: a new integration test pastes a full file using an unrelated
  wrapper class/field shape and asserts `AppTheme.light`/`.dark` are still
  generated correctly with the `AppColors` extension wired into both, 0/0
  analyze. Full suite green.
