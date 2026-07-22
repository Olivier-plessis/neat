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

### 1. Open-source on GitHub ← docs done, publish step remains

- License: **MIT** (max adoption, zero friction). ✅ present.
- ✅ Real README (refreshed: accurate test count, "shipped/in progress/next"
  section no longer lists AGENTS.md/i18n/branding as upcoming — they're done).
- ✅ CONTRIBUTING (harness-first contribution bar, architecture-in-a-minute).
- ✅ ROADMAP (this file).
- ⬜ **Publish**: flip the `github.com:Olivier-plessis/neat` remote to public
  and push. Not something to do silently — visibility + history become
  public and it's hard to walk back, so this is a manual, explicit step for
  the repo owner, not something to script.
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

### 5h. Drift DAO separation + downgrade safety — ✅ (maxit-front-flutter comparison)

> Prompted by reading `maxit-front-flutter` (a real team-split monorepo) to see how a
> production project structures its Drift layer differently from NEAT. Found three
> differences; the user decided per-point: skip the per-feature-database split
> (keep one shared `AppDatabase` — not worth the design cost against packageSplit's
> team-autonomy goal), but adopt downgrade safety and per-table DAO files.

- **Downgrade safety**: `AppDatabase`'s `MigrationStrategy` only ever handled
  upgrades (`onUpgrade`, see 5e) — a schema **downgrade** (older app build opened
  against a newer on-disk database, e.g. after a rollback) hit no handling at all
  and Drift would leave the mismatched schema in place. Every generated
  `database.dart` now also sets `beforeOpen`: if `details.versionBefore! >
  schemaVersion`, it drops every table (`DROP TABLE IF EXISTS
  ${table.actualTableName}` for all of `allTables`, wrapped in `PRAGMA
  foreign_keys = OFF/ON`) and recreates them via `createMigrator().createAll()` —
  same pattern maxit uses identically across both of its databases.
  `GenerateFeatureUsecase._ensureMigrationStrategy`'s self-heal block for
  pre-5e projects was updated to insert this too, so old projects catch up in
  one pass.
- **Per-table DAO files**: every CRUD method used to be inlined directly onto the
  monolithic `AppDatabase` class via anchor insertion (`// neat:daos`). Now each
  table gets its own `@DriftAccessor` DAO class in its own file
  (`packages/<app>_database/lib/src/dao/<feature>_dao.dart`,
  `.../dao/outbox_dao.dart` for the Outbox), registered via `@DriftDatabase(...,
  daos: [FooDao, OutboxDao])` and reached as `_db.fooDao.xxx()` /
  `_db.outboxDao.xxx()` from `FeatureLocalSource` and `SyncService` — mirroring
  maxit's actual file-per-table convention instead of one growing god-class.
  Deliberately scoped: `FeatureLocalSource`/`SyncService` stay typed to
  `AppDatabase` (no new DI providers or barrel exports) — file separation was the
  ask, not a DI restructure. `GenerateFeatureUsecase._injectDriftTable` now writes
  the new DAO file directly and inserts both an import at `// neat:dao-imports`
  and the class name at `// neat:daos`, instead of inlining methods. Old
  already-generated projects aren't retrofitted (no anchor exists yet in their
  `database.dart`) — accepted, same as every other new `// neat:` anchor.
- **Package renamed `local_storage` → `<app>_database`**: verified against a real
  generated project (`neat_test/liza`) while checking that Point 1 actually
  landed there — it did, but the user flagged the package name itself as
  confusing, since after this refactor it contains **only** Drift (a typed SQL
  database + DAOs), never a generic cache/SharedPreferences/secure-storage mix.
  Renamed to `<app>_database`, prefixed like the extracted UI package (unlike
  `core`/`auth`/feature packages, which stay unprefixed — see the naming
  rationale comments at each call site). `ProjectLoader.scanFeatures` and
  `GenerateFeatureUsecase` both detect the package name from disk (checking for
  `<app>_database` first, falling back to the old `local_storage`) so projects
  generated before the rename keep working in the Workshop without a migration
  step — the generator itself only ever writes the new name going forward.
- Harness-proven: the chopper+offline-sync full-generation test now asserts
  `database.dart` has no inlined Outbox methods and a new
  `packages/<app>_database/lib/src/dao/outbox_dao.dart` contains them; the
  Workshop Drift-injection test asserts `database.dart` has no inlined
  `upsertOrders`, contains the `OrdersDao` import/registration, and a new
  `orders_dao.dart` has the real method; every package-name assertion across
  the integration suite (imports, pubspecs, workspace members) was updated to
  the new `<app>_database` name. Full fast suite (245 tests) and every
  offline/sync/packageSplit integration test green.
- **Follow-up — table definitions split the same way**: the user asked
  specifically whether NEAT matched maxit's `table/<name>_table.dart` files
  (a plain `class FooTable extends Table` in its own file, imported by both
  the database and its DAO) — it didn't yet; the Table classes were still
  inlined in `database.dart`. Added `LocalStorageTemplates.featureTableFile`/
  `outboxTableFile` (mirrors `featureDaoFile`/`outboxDaoFile` exactly) and
  `LocalStoragePackageWriter` now writes
  `packages/<app>_database/lib/src/table/<feature>_table.dart` (and
  `.../table/outbox_table.dart` when sync is on). `database.dart` shrinks to
  imports (`// neat:table-imports` anchor, new) + the `@DriftDatabase(tables:
  [...], daos: [...])` registration — no table or DAO bodies at all now. Each
  DAO file imports its table file directly (`import '../table/<feature>_table.dart';`)
  in addition to `../database.dart`, matching maxit's own DAO imports exactly —
  confirmed by reading `quick_action_dao.dart`/`quick_action_dao.g.dart` in
  `maxit-front-flutter` directly: the row data class (e.g. `QuickActionTableData`)
  is generated once, into the *database's* own `.g.dart`, never duplicated by the
  DAO's `.g.dart` — proving a table can safely live in its own file without
  drift_dev generating conflicting output. `GenerateFeatureUsecase._injectDriftTable`
  writes the new table file and wires `// neat:table-imports` the same way it
  already wired `// neat:dao-imports`. `agents_md_template.dart` and
  `CoreTemplates.removeFirstFeatureDoc` updated to reference the new anchor/files.
  Harness-proven: every test asserting on inline table-class text in
  `database.dart` (the sync test's `class OutboxEntries`, the Workshop
  Drift-injection test's `class OrdersRows`, both JSON-entity tests' column
  lines) now asserts its **absence** from `database.dart` and its presence in
  the new `table/*.dart` file instead. Full fast suite (245 tests) + all 58
  integration tests green, including real `build_runner`/`flutter analyze` on
  every generated combo (proving drift_dev itself accepts the split, not just
  that the generator emits the right strings).

### 5i. Offline-first + web target — real bug, found running a real project in Chrome

- **The defect**: a project generated with `targetPlatforms` including `web`
  **and** offline-first storage crashed at runtime — every provider downstream
  of `appDatabaseProvider` (`productLocalSourceProvider`,
  `productRepositoryProvider`, `getProductUsecaseProvider`, the first
  feature's own list provider) failed in cascade with `ProviderException:
  Tried to use a provider that is in error state`. Root cause, found in the
  Chrome devtools log of a real generated project (`liza_web`):
  `drift_flutter`'s `driftDatabase()` throws `Invalid argument(s): When
  compiling to the web, the \`web\` parameter needs to be set.` unless a
  `DriftWebOptions` is supplied — `LocalStorageTemplates.database()`'s
  `_open()` only ever emitted the native-only
  `driftDatabase(name: 'app_db')` call, with no web branch at all, even
  though `identity.targetPlatforms` already offers `web` as a real wizard
  option and `launch_generation_usecase.dart` already computed an `isWeb`
  flag — just never threaded it as far as the Drift template (only used for
  `usePathUrlStrategy()` before this fix).
- **The fix**: `LocalStorageTemplates.database()` gained an `isWeb` param;
  when true, `_open()` branches on `kIsWeb`
  (`import 'package:flutter/foundation.dart' show kIsWeb;`) and supplies
  `web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker:
  Uri.parse('drift_worker.dart.js'))`, falling through to the exact same
  native one-liner as before on every other platform. `isWeb` threads through
  `LocalStoragePackageWriter.write` from the flag `launch_generation_usecase.dart`
  already had at hand.
- **The one thing that couldn't be templated**: `sqlite3.wasm` and
  `drift_worker.dart.js` are prebuilt, versioned release binaries (confirmed
  against drift's own docs, https://drift.simonbinder.eu/platforms/web/ —
  "No bootstrapping command... files must be manually downloaded and placed
  in the `web/` folder"), not generatable Dart source, and no local package
  in the resolved dependency tree ships them reliably enough to copy at
  generation time. Rather than silently leaving the user to discover this the
  same way (a browser stack trace), a new `CoreTemplates.driftWebSetupDoc`
  writes `docs/DRIFT_WEB_SETUP.md` — only when `localStoragePackage != null &&
  isWeb` — spelling out exactly what to download, from where, and where to
  put it, plus the `Content-Type: application/wasm` production-serving note.
  Same "generate a doc instead of a half-solution" precedent as
  `REMOVE_FIRST_FEATURE.md`.
- **Verified desktop-only is unaffected**: `drift_flutter`'s own pubspec
  already depends on `path_provider` + `sqlite3` (native-asset-hooks-based)
  transitively for macOS/Windows/Linux — confirmed directly by reading
  `drift_flutter`'s installed `pubspec.yaml`, no NEAT-side dependency was
  ever missing for native platforms. No changes needed or made there.
- Harness-proven: a new integration test generates an offline-first + `web`-only
  project and asserts `database.dart` contains the `kIsWeb` import, the
  `DriftWebOptions` branch with both exact filenames, and the native fallback
  line untouched; `docs/DRIFT_WEB_SETUP.md` exists and names the right
  package path; `flutter analyze` 0/0 (this validates the generated Dart
  type-checks against the real pinned `drift_flutter`/`flutter/foundation.dart`
  APIs, though it can't exercise an actual browser run the way the original
  bug report did). The existing non-web offline-first test gained negative
  assertions (`kIsWeb`/`DriftWebOptions` absent, no setup doc written) as a
  regression guard. Full fast suite (245 tests) + all 59 integration tests
  green.

### 5j. Customize endpoints (Entity + CRUD, chopper) — real gap found via a real project

> Follow-up from a "Custom Endpoints" (§7 Phase 2) design pass that was
> reverted: the user pointed out `afsv`'s `book` feature (Custom Endpoints)
> generated three near-identical models (`AllBooksRequestModel`,
> `AddBookRequestModel`, `UpdateBookRequestModel` — same 6 fields, three
> names) versus `product`'s (Entity + CRUD) single shared model — real
> duplication, confirmed by reading the generated files directly. Read
> dummyjson.com/docs/recipes as a concrete reference API: GET/POST/PUT all
> return the same `Recipe`, but create is `POST /recipes/add`, not
> `POST /recipes` — a shape Entity+CRUD's single `apiPath` (one base for all
> 5 operations) can't express. Rather than fixing Custom Endpoints' model
> duplication, the better fix was making Entity+CRUD's own fixed 5 operations
> individually path/verb-configurable, so it can model APIs like this
> natively instead. Custom Endpoints itself is unchanged (still exists for
> endpoint *sets* that don't map onto 5 CRUD operations at all, e.g.
> dummyjson's `/recipes/tags` returning plain strings).

- **New model**: `CrudEndpointOverrides` (hand-written, mirrors
  `EndpointSpec`'s own style rather than freezed) — a name + method + path
  per fixed operation (`getAll`/`getById`/`create`/`update`/`delete`, names
  defaulting to those exact identifiers). `FeatureGenOptions` gained
  `customizeEndpoints` (off by default) + `endpointOverrides`.
  `getById`/`update`/`delete` keep a literal `{id}` in their path —
  chopper's own `@Path()` binding matches it natively, no runtime
  substitution needed.
- **Template**: `DataTemplates.featureApiSource`'s chopper branch gets a new
  `customizeEndpoints` path: `@ChopperApi(baseUrl: '')` (empty, like Custom
  Endpoints) and each of the 5 methods carries its own full literal
  `path:` + verb + **method name**, instead of one shared `baseUrl` with
  fixed per-method suffixes and fixed names. `DataTemplates.featureRepositoryImpl`
  (offline-first non-sync + remote-only branches) follows the same custom
  names at its 5 remote call sites, so a rename is load-bearing, not
  cosmetic — the Outbox-based sync-mode write methods are untouched (they
  queue by raw `endpoint:`/`operation:` string, replayed later by
  `SyncService`, never call the `ApiSource` directly). Dio/Supabase/Firebase
  untouched — chopper-only, same scope discipline as Custom Endpoints itself
  (no REST path concept for Supabase/Firebase's table/collection
  addressing).
- **Workshop UI**: a new "Customize endpoints" toggle in the Architecture
  Layers step (chopper projects only), collapsed/off by default — the
  existing single "API Path" field stays the default behavior. Once
  switched on, 5 fixed rows (Get All/Get By Id/Create/Update/Delete, no
  add/remove — these are the CRUD operations, not an arbitrary list), each
  with a fixed role label plus an editable name + HTTP verb + path,
  pre-filled with the current derived defaults
  (`CrudEndpointOverrides.defaultsFor`) so the user only has to change what
  actually differs (e.g. just `createPath`, or rename `add` → `createRecipe`).
  Same row-editor language as Custom Endpoints' `_EndpointRow` (which itself
  has a real, functional name field — confirmed via a user screenshot
  showing "getProduct" being typed live), simplified: no expansion, no
  request/response body editors (every operation shares the feature's one
  entity, already defined in Entity Fields). The role label (Get All/Get By
  Id/etc.) stays visible alongside the editable name so renaming never
  costs the user their bearings on which of the 5 operations a row is.
- Harness-proven: an integration test (dummyjson-shaped: `apiPath:
  '/recipes'`, `createPath: '/recipes/add'`, `createName: 'createRecipe'`,
  `updateMethod: patch`) asserts the generated `recipe_api_source.dart`
  carries the exact per-method verb+path+name combination and an empty
  `baseUrl`, that `recipe_repository_impl.dart`'s call site follows the
  renamed method (`.createRecipe(model)`, not `.add(model)`), that the
  entity/model stay singular (not one per operation), and `flutter analyze`
  0/0. Full fast suite (245 tests) + all integration tests green.

### 5k. "Set as home page" — closes a promise the welcome placeholder's own doc made and nothing delivered

> Found via a real generated project (`liza`): the user added their first
> feature via the Workshop after launching with no first feature, but the
> app kept showing the launch-time "Welcome" placeholder — routing was never
> updated. `AppRoutePath.welcome`'s own doc comment already promised "until
> you add one via the Workshop", but `GenerateFeatureUsecase` had zero
> references to "welcome" anywhere — the promise was never implemented.
> Confirmed by reading the real project: `app_router.dart`'s `redirect:`
> closure still pointed at the dead `welcome` constant after the user
> manually edited `initialLocation`. Decision: fully delete the placeholder
> (not just bypass it) — confirmed with the user, who didn't expect the
> Welcome page to ever resurface after a real first feature exists.

- **New option**: `FeatureGenOptions.setAsHomePage` (`@Default(true)`) — a
  `LayerToggle` in the Identity & Routing step, shown only when
  `features.isEmpty` (the project's actual first feature; meaningless
  otherwise, so hidden rather than disabled).
- **`GenerateFeatureUsecase._removeWelcomePlaceholder`**: when the option is
  on and this is genuinely the first feature, repoints every
  `AppRoutePath.welcome` reference at the new feature's own route constant
  and deletes the placeholder's own files. Four steps, each defensive/no-op
  on content it doesn't find (idempotent — safe to call on a project that
  never had a welcome placeholder): (1) `routes.dart` — drop the placeholder's
  own import + aggregator entry outright, via a `RegExp` (not a literal
  string) tolerant of `dart format`'s line-wrapping for long package names;
  (2) delete `welcome_route.dart`/`.g.dart`/`welcome_page.dart`; (3) drop the
  dead `AppRoutePath.welcome` constant (app's own copy + the core package's
  mirrored copy under packageSplit); (4) a project-wide sweep
  (`AppRoutePath.welcome` → `AppRoutePath.$feature`) across every `.dart`
  file — not a fixed list of known call sites, since `homeRouteExpr()`
  (`generation_io.dart`) reaches `initialLocation`, the onboarding `onDone`
  redirect, *and* the post-login auth guard redirect, and enumerating every
  template call site by name would be fragile.
- Harness-proven: two integration tests (launch with no first feature, then
  `GenerateFeatureUsecase` add one) — `setAsHomePage: true` (default) asserts
  the placeholder's files are gone, `routes.dart`/`app_router.dart`/
  `app_route_path.dart` contain no `welcome` reference and do contain the new
  feature's, and `flutter analyze` 0/0; `setAsHomePage: false` (opt-out)
  asserts the placeholder stays untouched, coexisting exactly like before
  this option existed. Full fast suite (257 tests) green.

### 5l. Paginated list envelope unwrap — closes the gap the envelope-detection heuristic (§7-adjacent) left in codegen

> Follow-up from the same `liza` project diagnosis as §5k, found in the same
> message: the user manually wired routing to the new "recepies" feature and
> hit a runtime crash — `FormatException: JsonConverter expected response
> body to be Iterable<RecepiesModel>, but got Map` — confirmed by reading the
> generated `recepies_api_source.dart` (`getAll()` declared
> `Future<Response<List<Model>>>`) against dummyjson.com/recipes' actual
> shape (a paginated wrapper object, not a bare array). An earlier session
> had already taught `JsonEntityInferencer` to *detect* this wrapper and
> infer fields from its first element (avoiding wrong fields), but detection
> alone didn't fix the HTTP layer — `getAll()` still assumed a bare array.
> This closes that gap: the detected wrapper key now flows all the way to
> the generated `getAll()`.
- **`InferenceResult`** gained `envelopeKey` (the JSON key the entity's own
  list lives under, e.g. `"recipes"`; `null` when no wrapper was detected).
  **`FeatureGenOptions`** gained `listEnvelopeKey` (`@Default('')`), set by
  `EntityFieldsStep.onInfer`/`onReset` from the inference result — no new
  Workshop UI control; the existing "Detected a paginated list wrapper..."
  warning already surfaces this to the user.
- **`DataTemplates.featureApiSource`**: dio's `getAll()` unwraps the key
  inline, self-contained (`_dio.get<Map<String, dynamic>>` +
  `response.data?['key']` instead of `_dio.get<List<dynamic>>`) — no
  repository change needed. Chopper can't do the same (an abstract
  `@GET()`-annotated interface has no method body): its `getAll()` return
  type becomes `Response<dynamic>` instead of `Response<List<Model>>` when a
  key is set — `dynamic` sidesteps `ModelJsonConverter`'s per-Type decoder
  dispatch entirely, leaving the raw decoded `Map` for the repository layer
  to unwrap instead. Applies to both the plain and `customizeEndpoints`
  branches; `getById`/`create`/`update`/`delete` are untouched (only
  `getAll()`'s response is ever a paginated wrapper in the shapes seen so
  far). Supabase/Firebase untouched — no pagination-envelope concept in
  their generated table/collection queries.
- **`DataTemplates.featureRepositoryImpl`**: a `getAllRemote()` helper
  swaps in the unwrap-by-key + per-item `fromJson` expression at exactly
  `getAll()`'s two call sites (offline-first + remote-only chopper
  branches) — every other operation keeps the plain `unwrapChopperResponse`
  helper unchanged.
- Harness-proven: a unit group in `data_templates_test.dart` (chopper +
  dio, key set vs unset, api source + repository) plus a full integration
  test — launches with no first feature, adds one via `GenerateFeatureUsecase`
  from dummyjson's real recipes shape run through the real
  `JsonEntityInferencer`, then an **executable regression probe**
  (`flutter test` against a hand-written probe file in the generated
  project, same technique as the existing chopper-converter probe) proves
  the actual runtime bug is gone: `ModelJsonConverter.convertResponse` no
  longer throws decoding the envelope body, and the repository's generated
  unwrap expression decodes real typed Models — `flutter analyze` can't
  catch this class of bug (the old code compiled fine; it only failed
  against a real decoded response). `flutter analyze` 0/0. Full fast suite
  (263 tests) green.

### 5m. packageSplit + chopper: bootstrap.dart's decoder-registration anchors self-heal too — a real bug from the same envelope-fix testing session

> Found immediately after §5l shipped, verifying it on a second real project
> (`arth`, packageSplit + chopper): the *same* `FormatException` still hit
> `dummyjson.com/users` — but this time on every single call, not just
> `getAll()`. Reading the generated project: `users_repository_providers.dart`
> had a perfectly-generated `registerUsersChopperDecoders()`, but nothing in
> the whole project ever called it — `chopperModelDecoders` stayed empty, so
> chopper's own built-in converter (never NEAT's `ModelJsonConverter`, since
> the per-Type decoder lookup always missed) tried to decode every response
> and threw. Root cause: `AppTemplates.bootstrap` only writes `bootstrap.dart`'s
> `// neat:chopper-register-imports`/`-calls` anchors when the *wizard's own*
> first feature already uses chopper (`chopperRegisterFeaturePackage != null`)
> — a project launched with zero features (`generateFirstFeature: false`,
> the same fully-valid, common combo §5k/§5l both already exercise) never had
> them to begin with, so `_registerChopperDecoderSplit`'s anchor-insertion
> silently no-op'd the very first time a chopper feature was added via the
> Workshop. The exact same class of gap as §5k's welcome-placeholder bug
> (an assumption baked in at launch time that doesn't hold for "added later
> via Workshop"), and one this codebase had already solved once before for
> the sibling shell-branch registration anchors (`healBootstrapShellAnchors`)
> — its own doc comment even flagged chopper's missing counterpart as "an
> accepted, pre-existing limitation," believing it was legacy-only. It wasn't.
- **`GenerateFeatureUsecase.healBootstrapChopperAnchors`** (new,
  `@visibleForTesting`) mirrors `healBootstrapShellAnchors` exactly: adds
  `// neat:chopper-register-imports` after the last import line and
  `// neat:chopper-register-calls` right before `registerErrorHandler();`,
  idempotent. Called at the top of `_registerChopperDecoderSplit`, same spot
  `_registerShellPageSplit` already calls its own healer.
- Harness-proven: 3 new fast unit tests (`anchor_healing_test.dart`) against
  the exact real `arth` bootstrap.dart shape (anchors added in the right
  spots, idempotent, a properly-anchored file left untouched) + a new
  integration test — launches packageSplit+chopper with zero features, adds
  the first one via `GenerateFeatureUsecase`, asserts both anchors and the
  actual import/call exist afterward (not just the registration function
  existing — the exact thing that silently failed) and `flutter analyze`
  0/0. Full fast suite (266 tests) green.
- The user's own two real test projects were hit by this in immediate
  succession while verifying §5l (`liza` first, `arth` second) — `arth`'s
  `lib/core/bootstrap.dart` was hand-patched directly to the same shape this
  fix now generates, to unblock testing before a NEAT restart.

### 5n. Typed `<Feature>ListModel` wrapper — replaces §5l's `dynamic`-based envelope unwrap

> Follow-up, same session: verifying §5l on a real project, the user hand-patched
> `users_api_source.dart`/`users_repository_impl.dart` themselves — added a
> `UsersListModel` (`{ users, total, skip, limit }`) and typed `getAll()` as
> `Future<Response<UsersListModel>>` instead of `Response<dynamic>`, asked
> what I thought. Assessment: genuinely better — zero `dynamic` in the
> repository, the decoder registry stays uniform (every response type routes
> through the same `chopperModelDecoders[InnerType]` lookup, no special case
> for `getAll()`), and pagination metadata (`total`/`skip`/`limit`) survives
> instead of being discarded. The one real risk (a required field on a
> hand-inferred wrapper missing from a live response, throwing a *new*
> `FormatException`) is no worse than the risk the entity model itself
> already carries everywhere else in NEAT — no principled reason to treat
> the wrapper specially. `_detectListEnvelope` already parses the wrapper's
> sibling scalar fields to validate the "exactly one array field" guard, so
> the data needed was sitting right there, unused. Confirmed with the user
> before implementing (explicit "oui" — "le but de neat est quand même de
> faire gagner du temps"), then replaced §5l's `dynamic` approach outright
> rather than keeping both.
- **`JsonEntityInferencer`**: `InferenceResult` gained `envelopeFields` — the
  wrapper's own sibling scalars (e.g. `total`/`skip`/`limit`), inferred via
  the same `_childrenOf` used for the entity (guaranteed scalar-only by
  `_detectListEnvelope`'s own "exactly one array field" guard, so no
  object/list branching needed). `FeatureGenOptions` gained the matching
  field, wired from `EntityFieldsStep` alongside the existing `listEnvelopeKey`.
- **`DataTemplates.featureModel`**: new `_listWrapperModelFreezed`/`_listWrapperModelPlain`
  generate `<Feature>ListModel` (freezed or plain, matching the project's
  own config) alongside the entity model in the same file — deliberately
  *not* built on the existing `_modelFreezed`/`_modelPlain` (every other
  model in that file assumes a domain `Entity` counterpart with
  `fromEntity`/`toEntity`; the wrapper is a pure transport shape with
  neither). The list field's Dart name is `camel(envelopeKey)` — `@JsonKey`
  only when that differs from the raw key (every real-world key seen so far
  — `recipes`/`users`/`data`/`items` — already matches).
- **`DataTemplates.featureApiSource`/`featureRepositoryImpl`**: chopper's
  `getAll()` now returns `Response<<Feature>ListModel>` (routes through
  `ModelJsonConverter`'s ordinary per-Type registry, same as every other
  response) instead of `Response<dynamic>`; the repository's `getAllRemote()`
  simplified from a multi-line unwrap-and-cast expression to a single
  `.<envelopeFieldName>` property access. Dio decodes the wrapper directly
  (`<Feature>ListModel.fromJson(response.data!).<envelopeFieldName>`), still
  self-contained in the ApiSource. `featureRepositoryProviders` registers
  *both* the entity Model's and the wrapper ListModel's decoders now (split
  and non-split paths both updated).
- Harness-proven: unit coverage extended in `data_templates_test.dart`
  (wrapper generation, `@JsonKey` only-when-renamed, both http clients, both
  decoder registrations) and `json_entity_inferencer_test.dart`
  (`envelopeFields` asserted across every existing envelope-detection case).
  The existing §5l integration test's assertions/probe were rewritten for
  the typed shape — the probe now drives `ModelJsonConverter.convertResponse`
  with the *real* registered `RecipeListModel` decoder end to end (stronger
  than the old dynamic/dynamic pass-through check it replaced). `flutter
  analyze` 0/0. Full fast suite (271 tests) green.

### 5o. Skeletonizer placeholder hoisted to a top-level `final` — found via a wesioo comparison

> Follow-up, same session: the user pointed at `wesioo`'s
> `doctor_agenda_page.dart` (`_skeletonState`, a module-level `final`
> computed once via an IIFE) next to a NEAT-generated `users_page.dart`,
> asking why NEAT rebuilds the whole placeholder model instead of doing the
> same. Confirmed the gap: `_riverpodListPage`'s Skeletonizer branch called
> `List.generate(8, (_) => ${'$'}{p}Entity(...))` **inline inside `build()`** —
> reconstructing 8 full nested placeholder entities (every field, every
> nested object) from scratch on *every* rebuild while loading, not once.
> Not `const`-able (a `DateTime` placeholder isn't a const expression), but
> a plain top-level `final` gets the same one-time-computation benefit
> without needing wesioo's IIFE (NEAT's placeholders are fixed values, no
> `DateTime.now()`-relative setup step to wrap).
- **`PresentationTemplates._riverpodListPage`**:
  the placeholder construction moves to a generated top-level
  `final _<feature>SkeletonItems = List.generate(8, (_) => <Feature>Entity(...));`
  declared once, right after the imports (mirrors wesioo's own placement — a
  clearly separated "skeleton data" section before the widget class).
  `build()`'s Skeletonizer branch shrinks to
  `Skeletonizer(child: _<Feature>List(items: _<feature>SkeletonItems))`.
- Harness-proven: new `presentation_templates_test.dart` (3 tests — the
  hoisted var exists, `build()` references it instead of an inline
  `List.generate`, and it's positioned before the class/`build()` in the
  generated source) + full fast suite (274 tests) + full integration suite
  (64 tests, unaffected — the existing `contains('Skeletonizer(')`
  assertion holds either way) all green.
- Applied by hand to the user's own `arth` test project as an immediate
  reference (their `users_page.dart` had independently converged on
  wesioo's `?? <fallback>` pattern, using `?? []` — replaced with
  `?? _usersSkeletonItems` so the shimmer effect actually has skeleton-shaped
  rows to animate over instead of an empty list).

### 5p. Widgetbook gets its own `web` target, independent of the app's own platforms

> Follow-up, same session: the user asked why Widgetbook — a component
> catalog meant to be browsed on a big screen — didn't default to a
> desktop/web template instead of inheriting whatever platforms the app
> itself picked (mobile-only, in their case). Confirmed: NEAT never ran
> `flutter create` for Widgetbook at all. In loose mode (no extracted `<ui>`
> package) its catalog is a bare file sharing the app's own scaffold, so a
> mobile-only app meant a mobile-only catalog. In the *extracted* (workspace
> member) case — the actual default, since `ThemeEngineState.extractUiPackage`
> defaults to `true` — it's worse: `ThemeWriter` only hand-writes
> `widgetbook/pubspec.yaml`/`lib/main.dart` as text, `flutter create` never
> touches that directory, so it has **zero** platform runner folders of its
> own — not runnable on *any* platform, not just the wrong one. User's own
> framing: reuse the existing opt-in and auto-add a platform in
> `LaunchGenerationUsecase` when it's on — right instinct, though the
> extracted case needed its own fix beyond just appending to
> `identity.targetPlatforms` (a separate directory `flutter create` never
> reaches, regardless of what's in that list).
- Empirically verified before writing any code (not assumed): `flutter
  create` on a directory that already has a hand-written `pubspec.yaml` +
  `lib/main.dart` only fills in *missing* platform folders — it doesn't
  touch either file. Safe to run late, after `ThemeWriter` has already
  placed the extracted member's own files.
- **Loose mode** (`generateWidgetbook && !extractUiPackage`): `web` is added
  to a locally-scoped `requestedPlatforms` set feeding the app's own (only)
  `flutter create` call — deliberately *not* a mutation of
  `identity.targetPlatforms` itself, so `isWeb` (computed from that field
  elsewhere) keeps reflecting the user's actual platform choice, not this
  widgetbook-driven addition.
- **Extracted (member) mode** (the default): a **second** `flutter create
  --platforms web --no-pub` call, scoped to the `widgetbook/` directory,
  inserted after `PubspecWriter.write()` (so the root workspace's own
  `workspace:` list already names it — pub's workspace resolution needs
  that first) and before the workspace-wide `flutter pub get` (`--no-pub`
  here to avoid a premature, redundant resolution attempt).
- Harness-proven: extended the existing "extracted UI package + Widgetbook"
  integration test (asserts `widgetbook/web/` now exists, the app's own
  `web/` doesn't, and `flutter create` left the hand-written pubspec/
  main.dart untouched) + fixed the main "chopper + offline-sync" test's
  widgetbook assertions (it turned out to already be exercising member mode
  by default, not loose mode as first assumed — `widgetbook/lib/main.dart`,
  not `widgetbook/main.dart`) + a new dedicated loose-mode test
  (`extractUiPackage: false`, mobile-only `targetPlatforms`) confirming the
  app gets a `web/` folder while `isWeb`-gated bootstrap behavior
  (`usePathUrlStrategy()`) stays off. `flutter analyze` 0/0 on both shapes.
  Full fast suite (274 tests, unaffected — this is integration-only
  behavior) + full integration suite green.

### 5q. Widgetbook + ScreenUtil: `ScreenUtilInit` was never run for the catalog — real crash, found running §5p on a real project

> Follow-up, same session, found the moment §5p's fix let the user actually
> launch the widgetbook catalog for the first time: `LateInitializationError:
> Field '_minTextAdapt' has not been initialized`, thrown building
> `WidgetbookApp`. Root cause: the design-system components (`AppGap`,
> typography) call `.sp`/`.w`/`.h` — flutter_screenutil extensions that
> require `ScreenUtilInit`'s `builder` to have run at least once — but
> unlike the app's own `AppTemplates.appDart` (which wraps its `MaterialApp`
> in exactly that), `ThemeTemplates.widgetbookApp` never did. `useScreenUtil`
> is the *default* for nearly every project (`!isWebOnly`), so this wasn't a
> rare combination — any generated project with Widgetbook on would hit it
> the instant the catalog rendered a single component. `flutter analyze`
> never caught it in §5o/§5p's own tests because it's a pure runtime failure
> — the generated code compiles and lints cleanly either way.
- **`ThemeTemplates.widgetbookApp`**: gained `useScreenUtil` — wraps the
  `Widgetbook.material(...)` catalog in the same `ScreenUtilInit(designSize:
  ..., minTextAdapt: true, splitScreenMode: true, builder: ...)` shape
  `AppTemplates.appDart` already uses, plus the matching
  `flutter_screenutil` import.
- **`UiPackageWriter.widgetbookPubspec`**: gained `useScreenUtil` too — pub
  requires a package to declare its own direct dependency on anything it
  imports, so the extracted widgetbook member needs its own
  `flutter_screenutil` entry even though the `<ui>` path-dependency already
  has one (no implicit transitive re-export). Threaded through
  `ThemeWriter.write`'s two call sites (both already had `useScreenUtil` in
  scope).
- Harness-proven: an **executable regression probe** (same technique as the
  session's earlier chopper-converter one) — pumps the real generated
  `WidgetbookApp` in a widget test and asserts no exception — added to the
  extracted-member integration test. Verified with a genuine negative
  control before trusting it: reverted the fix via `git stash`, reran, watched
  the test fail for the right reason (missing `flutter_screenutil` dependency),
  then restored and reran green — the probe has teeth, not just a
  plausible-looking assertion. `flutter analyze` 0/0, full fast suite (274
  tests, unaffected) + full integration suite green.

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
    > Discovered while implementing (bigger than the original scope below let on):
    > a feature package can never depend on the app itself — the app already
    > depends on its feature packages, and a pub workspace forbids cycles. Without
    > a shared package sitting *below* both, `Result`/`Failure`/`UseCase`/
    > `NetworkErrorHandler` would have to be duplicated inside every feature
    > package, which defeats the entire point (a bug fixed in one usecase base
    > class should never need fixing in N places). `<app>_core` now ships this
    > Phase-1-minimal slice — `Result`, `Failure`, `UseCase`/`NoParamsUseCase`/
    > `Unit`, a dio-only `NetworkErrorHandler`, a plain (no envied) `dioProvider` +
    > its `LoggerInterceptor`/`AppLogger`, and `AppRoutePath` — gated behind
    > `ArchitectureState.packageSplit`, wired into the root `workspace:`/`path:`
    > exactly like `<app>_local_storage`/`<app>_ui` already are. Every file is
    > generated by **reusing the existing app-level templates** unchanged, just
    > pointed at the core package's own name instead of the app's — no new
    > template logic needed for the content itself, only for where it's written.
    > Envied/`AppEnv` itself stays out of the core package (would need an
    > interface/implementation split to be shareable) — but the core dio/
    > chopper client's `apiBaseUrl` **is** bridged in, via `ApiConfig` (see
    > the later entry below — real bug, found via a real project).
    >
- **Borrowed from kido-luci's own `packages/architecture`** (read on
  > request): a `Future<T>.fire()` extension (sugar for `unawaited(this)`) —
  > small, low-risk, genuinely useful, added to `<app>_core`.
>   - **Deliberately not borrowed**: their sealed `Failure` hierarchy with named
      > subtypes (`NotFoundFailure`, `ValidationFailure`, ...) — NEAT simplified
      > *away* from exactly this shape earlier (§5d) because a hand-rolled
      > hierarchy was dead code nothing ever constructed; a generator can't know a
      > generated project's domain-specific failure taxonomy upfront the way a
      > hand-written app can. Their `sealed Result<Ok/Err>` (pattern-matchable,
      > more idiomatic Dart 3 than our `fold()`-callback style) is a genuinely
      > interesting idea but a rename that would ripple through every template
      > already using `.fold`/`.getOrThrow` — parked, not adopted, revisit later.
>   - Harness-proven: an integration test generates `packageSplit: true` alone
      > (no feature depends on it yet), asserts the package's files/content and
      > the root workspace wiring, and confirms `flutter analyze` 0/0 for the
      > whole workspace (including running the core package's own `dioProvider`
      > `@Riverpod` codegen — build_runner runs per-package in a workspace, same
      > as the Drift package already does).
> - ✅ **Phase 1, step 2a — split the wizard's first feature — done**. Same
    > narrow combo as scoped: feature-first + Riverpod annotations + dio +
    > remote-only + plain go_router + exactly one feature.
    >
- `feature_scaffolder.dart` takes `packageSplit`/`corePackageName`: a third
  > `domainBase`/`dataBase`/`presentationBase` branch (`$lib/domain`,
  > `$lib/data`, `$lib/presentation` — the package root **is** the feature, no
  > `features/<name>/` nesting, and no layer-first variant, since splitting by
  > feature only makes sense feature-first).
>   - Every self-referencing `package:$app/features/$name/...` import (domain ↔
      > data ↔ presentation, ~30 call sites across `domain_templates.dart`/
      > `data_templates.dart`/`presentation_templates.dart`) became a **relative**
      > import instead (`../../domain/entities/...` etc.) — works unchanged in both
      > flat and split layouts, since the nesting depth between layers is the same
      > either way; only the absolute prefix differed. This also let several
      > now-unused `packageName` params get deleted outright (`featureModel`,
      > `featureApiSource`, `featureLocalSource`, `featureUsecaseProviders`,
      > `featureRoute`) instead of threading dead params through.
>   - The handful of *genuine* cross-package imports (usecases' and the
      > repository-providers' `core/usecases/use_case.dart` / `core/result/
>     result.dart` / `core/network/dio_provider.dart`, the list page's
      > `core/error/failure.dart`) took a new optional `corePackageName` param,
      > redirecting to the step-1 core package instead of the app.
>   - **Scope surprise, resolved**: `core/theme/theme_mode_controller.dart` is a
      > single app-wide *stateful* Riverpod provider — the app shell's
      > `MaterialApp` watches it (`themeMode:`) and the generated list page's
      > dark-mode toggle both reads and writes it. Unlike the stateless
      > Result/Failure/UseCase files, this can't be duplicated (app copy + core
      > copy would be two different provider instances — the feature page's
      > toggle would silently stop affecting the app's actual rendered theme). Now
      > single-sourced: `_writeCorePackage` also writes it into `<app>_core`, the
      > app **stops** writing its own local copy when `packageSplit` is on, and
      > `appDart()` imports `theme_mode_controller.dart` from the core package
      > instead of the app-relative path.
>   - The root app's `routesManual()` keeps writing its own `AppRoutePath` (an
      > app-internal reference, not a package-boundary crossing) but now takes
      > `featurePackageName` for the one import that *does* cross the boundary —
      > the split feature's page (`package:<app>_<feature>/presentation/pages/
>     <feature>_page.dart` instead of `package:$app/features/$name/...`).
>   - New feature-package `pubspec.yaml` (`CorePackageTemplates.featurePackagePubspec`)
      > depends on `<app>_core` via `path: ../<app>_core`, never on the app.
      > Needed `sdk: ^3.7.0` (not the other packages' `^3.6.0`) — the generated
      > list page's `ListView.separated` uses a wildcard pattern (`(_, _) => ...`)
      > that the analyzer rejects below language version 3.7.
>   - `launch_generation_usecase.dart` writes the feature package's pubspec,
      > redirects `FeatureScaffolder`'s `lib` root to `packages/<pkg>/lib`, adds it
      > to the root `workspace:`/`path:` wiring, and runs its own `build_runner`
      > pass — the same per-package pattern as `<app>_local_storage`/`<app>_core`.
>   - **Harness-proven**: the Phase 1 integration test (packageSplit + the
      > default first feature) asserts the feature's files live under
      > `packages/<app>_<feature>/` (package-root layout, not `features/<name>/`),
      > every cross-boundary import resolves correctly (core for
      > Result/Failure/UseCase/dio/theme, relative for same-feature refs, never
      > `package:$app/...` — that would be the forbidden cycle), the app's own
      > `theme_mode_controller.dart` is absent, `routes.dart` imports the split
      > page, the root `workspace:`/`path:` lists both packages, and `flutter
>     analyze` passes 0/0 for the **whole workspace**. Full 24-test suite still
      > green — zero regressions.
> - ✅ **Phase 1, step 2b — Workshop adds a second feature package — done**.
    > Real bug this closed: `GenerateFeatureUsecase` had **zero** awareness of
    > `packageSplit` — every Workshop-added feature landed in `lib/features/`
    > under the app regardless of how the project was generated (found by the
    > user generating a real test project and noticing the new feature never
    > left `lib/`). Root cause: the Workspace Contract (`.neat.json`) never
    > recorded `packageSplit` at all, so the Workshop had no way to know.
    >
- `NeatContract` gained a `packageSplit` bool (derived convention-based
  > naming, same as `localStoragePackage`/`uiPackage` already do — no need to
  > persist `corePackageName`/per-feature package names separately).
  > `LaunchGenerationUsecase` now writes it.
>   - `ProjectLoader.scanFeatures` was hardcoded to scan `lib/features/` —
      > useless for a split project (features never live there). Now
      > packageSplit-aware: scans `packages/` for `<projectName>_<feature>`
      > dirs, excluding the non-feature siblings (`_core`/`_local_storage`/`_ui`).
>   - `GenerateFeatureUsecase.execute` now derives `corePackageName`/
      > `featurePackageName` from the contract, writes the new package's own
      > `pubspec.yaml` (`CorePackageTemplates.featurePackagePubspec`, same as the
      > wizard's first feature), wires it into the root `workspace:`/`path:`
      > (two new idempotent pubspec-editing helpers), and points
      > `FeatureScaffolder` at `packages/<pkg>/lib` instead of the app's `lib/`.
>   - Route wiring (`_wireRoutes`/`_wireShellBranch*`) now crosses into the new
      > feature package instead of `features/<name>/`, **and** mirrors the new
      > `AppRoutePath` constant into the core package's own copy — a split
      > feature imports `AppRoutePath` from core, never the app, so core's copy
      > needs the constant too or the new route wouldn't compile.
>   - **Found and fixed in passing** (same root cause, different call site):
      > the *wizard's own* first-feature-split path had never actually been
      > exercised combined with `useNavigationShell` — `appShellRouteBuilder`/
      > `routesManualShell` hardcoded `features/<name>/` imports unconditionally,
      > so a wizard user picking shell nav + packageSplit together would have
      > gotten a broken import. Fixed both templates to take an optional
      > `featurePackageName` and threaded it from `LaunchGenerationUsecase`
      > too, not just the Workshop path.
>   - **Scoped out, rejected with a clear error**: nesting a new feature as a
      > *child route* under an existing packageSplit feature. That would need a
      > `path:` dependency from the parent package onto the child — a genuine
      > cross-feature-package dependency, exactly the problem Phase 3
      > (`shared_contracts`) exists to solve. `GenerateFeatureUsecase` now throws
      > a clear exception instead of generating a broken/undeclared import.
      > Shell branches stay supported (app→feature, never feature→feature, so no
      > new dependency problem).
>   - Chopper: the split feature already self-registers its own
      > `register<Feature>ChopperDecoders()` (existing `packageSplit`+chopper
      > machinery in `FeatureScaffolder`/`DataTemplates` — no changes needed
      > there). The only new piece is wiring `bootstrap.dart`'s
      > `// neat:chopper-register-imports`/`-calls` anchors (previously only the
      > wizard's first feature used them) — a new `_registerChopperDecoderSplit`
      > mirrors the wizard's own bootstrap wiring instead of editing the
      > (now-absent, see the core/ cleanup above) app-local
      > `chopper_model_converter.dart`.
>   - Harness-proven: two new integration tests — a dio top-level-route
      > scenario (asserts the new package/pubspec/workspace-wiring/route-import/
      > both AppRoutePath copies/reload-sees-both-features/non-destructive-guard/
      > child-route-rejection, `flutter analyze` 0/0 for the 3-package
      > workspace) and a chopper scenario (asserts the new feature's own
      > registration function + `bootstrap.dart`'s anchors, analyze 0/0). Full
      > fast + integration suites still green, including the pre-existing
      > `navigation-shell` test (confirms the `featurePackageName` param addition
      > didn't regress the non-split shell path).
> - ✅ **Wizard UI toggle — done**. `architecture_screen.dart`'s "Modular
    > Monorepo" section: a toggle gated on `canPackageSplit` (mirrors
    > `launch_generation_usecase.dart`'s `packageSplitSupported` — the generator
    > re-derives the combo independently rather than trusting the raw flag, the
    > same safety net `hasAuth`/`hasRealtime`/`hasStorage` already use, since the
    > UI only *disables* the toggle outside the combo, it doesn't reset the
    > underlying flag). Disabled with an explanatory message outside the combo;
    > the live folder-tree preview and the first-feature path hint both reflect
    > `packages/<app>_<feature>/` when active (`GenerateTreeUsecase` gained a
    > `packageSplit`/`packageName` param for this).
> - ✅ **Chopper support — done**. The one genuinely hard part: chopper's model
    > decoding fix (`chopperModelDecoders`, a `Type → decoder` registry) is
    > normally populated by anchor-inserting each feature's entry directly into
    > the registry file — impossible once split, since the registry now lives in
    > `<app>_core` and core importing every feature's Model to populate itself
    > would recreate the exact app←feature cycle packageSplit exists to avoid.
    > Fixed by flipping the direction: the registry starts genuinely empty in
    > core (no witness), and each split feature generates its own
    > `register<Feature>ChopperDecoders()` function (in its own
    > `<feature>_repository_providers.dart`, importing only its own Model +
    > core's registry — a downward-only import, no cycle). The app's
    > `bootstrap.dart` imports and calls it before `runApp` (gained
    > `// neat:chopper-register-imports`/`// neat:chopper-register-calls`
    > anchors, mirroring the router aggregator's own anchor pair, for when step
    > 2b lets a second split feature register itself too). The non-split chopper
    > mechanism (anchor-insertion straight into the registry file) is completely
    > untouched — this new path only exists when `packageSplit` is on.
    > `_writeCorePackage` also stopped hardcoding `httpClient: 'dio'` — it now
    > threads the actual client through, so `NetworkErrorHandler` and which
    > client provider ships (dio for dio/retrofit, chopper's client +
    > witness-free converter for chopper) both match the real stack.
    > `packageSplitSupported`/`canPackageSplit` widened to `dio || chopper`.
    > Harness-proven: a new integration test generates packageSplit + chopper +
    > a first feature, asserts the registration function/call/anchors, that core
    > and the app's own dead-code copy both stay witness-free, and `flutter
>   analyze` passes 0/0 for the whole workspace. Full suite still green.
> - ✅ **Phase 2, go_router_builder — done**. `CoreTemplates.featureRoutes()`
    > (the per-feature typed route file) and `routesAggregator()` (the app's
    > aggregator) got the exact same package-aware treatment `routesManual()`/
    > `featureRoute()` already had for manual routing: `featureRoutes()` gained
    > `corePackageName` to redirect its `AppRoutePath` import (the feature's own
    > page import was already convertible to relative — same package, no
    > change needed there); `routesAggregator()` gained `featurePackageName` to
    > redirect the one legitimate app→feature-package import (the typed routes
    > file itself). go_router_builder's own codegen (`part '<feature>_routes.g.dart'`)
    > just runs inside the split feature package's own build_runner pass —
    > already wired, same as freezed/riverpod_generator. `featurePackagePubspec()`
    > gained a `hasGoRouterBuilder` param adding the generator as a dev dep.
    > `packageSplitSupported`/`canPackageSplit` widened to drop the
    > `!hasGoRouterBuilder` restriction — manual and typed routing both work now.
    > No decoder-registry-style problem here (unlike chopper): go_router_builder
    > has no cross-feature shared mutable state to worry about.
    > Harness-proven: a new integration test generates packageSplit +
    > go_router_builder + a first feature, asserts the AppRoutePath/page import
    > redirects, that the aggregator crosses into the split package, that the
    > feature package's own build_runner produced its `.g.dart`, and `flutter
>   analyze` passes 0/0 for the whole workspace. Full suite still green (one
    > pre-existing unit test's assertion updated to match the new relative
    > self-import, not a behavior regression).
> - ✅ **Phase 2, offline-first + Drift (read-only, no sync/Outbox yet) —
    > done**. `_local_storage` needed no changes at all — it's already a leaf
    > package with nothing else in the workspace depending on it, so both the
    > core package and a split feature package can depend on it directly
    > without creating anything resembling a cycle. The real work was
    > `network_info.dart` + `infrastructure_providers.dart` (the shared
    > `appDatabaseProvider`/`networkInfoProvider` singletons every offline-first
    > feature reuses) moving into the core package, and redirecting
    > `featureRepositoryImpl()`'s offlineFirst branch (Failure/NetworkInfo/
    > Result/AppLogger) + `featureRepositoryProviders()`'s offlineFirst branch
    > (`infrastructure_providers.dart`) to `corePackageName` — the exact same
    > mechanical pattern as every other boundary this phase. Both the core
    > package's and the feature package's own pubspecs gained a sibling `path:`
    > dep on `_local_storage` + `connectivity_plus` where needed.
    > `packageSplitSupported`/`canPackageSplit` widened from "remote-only only"
    > to "remote-only or offline-first-read" — sync/Outbox (`hasSync`) stays
    > out of scope for now, since `sync_service.dart` hasn't had the same
    > core-package treatment yet.
    >
- **Also fixed in passing (real bug, unrelated to packageSplit, found
  > because it broke this test)**: `ThemeTemplates.appGap()`'s
  > `useScreenUtil` branch applied `.w`/`.h`/`.sp` to an *already-built*
  > `SizedBox`/`EdgeInsets` instead of to the raw number before wrapping it
  > — those extensions are declared on `num`, not on `SizedBox`/
  > `EdgeInsets`, so it never compiled. Reproduced on a pre-existing,
  > completely unrelated test (`offline-first generates a valid Dart
>     workspace`) to confirm it predated this session's packageSplit work.
>   - **Scope surprise, resolved**: verified empirically (a standalone 2-package
      > workspace reproduction, not just reasoning) that Dart pub workspaces do
      > **not** actually block a member from importing another member's
      > `package:` URI just because its own `pubspec.yaml` doesn't declare that
      > dependency — `dart analyze`/`flutter analyze` resolves every workspace
      > member via one shared `package_config.json` regardless. So the
      > "forbidden cycle" this whole packageSplit epic is framed around isn't
      > literally enforced by the analyzer today — it's a deliberate discipline
      > (never import the app from a feature package) that matters the moment a
      > feature package is ever pulled out of the workspace into its own repo,
      > which is the actual point of packageSplit. Found and fixed one place
      > this discipline had lapsed: `featureRepositoryImpl()`'s chopper
      > branch imported `chopper_model_converter.dart` from the app
      > unconditionally, never redirected to `corePackageName` — invisible to
      > `flutter analyze` inside the workspace, but wrong all the same. Now
      > fixed alongside this phase's other redirects.
>   - Harness-proven: a new integration test generates packageSplit +
      > offline-first + a first feature, asserts the core package ships
      > NetworkInfo/infrastructure_providers.dart and depends on `_local_storage`,
      > that the feature package's repository/providers/local source all cross
      > into the right packages (core for infra, `_local_storage` directly,
      > never the app), and `flutter analyze` passes 0/0 for the whole
      > (now 3-package) workspace. Full suite still green.
> - ✅ **Clean up the app's duplicated `core/` — done**. Every phase above
    > redirected split features to import `<app>_core`'s copy of a file, but the
    > app itself kept writing its own witness-free copy of the same file too —
    > pure dead code nothing in the app read anymore. Now every app-level file
    > that becomes 100% dead once split is skipped entirely (gated on
    > `corePackageName == null`): `result.dart`, `use_case.dart`, `failure.dart`,
    > `network_error_handler.dart`, `logger_interceptor.dart`, `dio_provider.dart`,
    > `chopper_model_converter.dart`/`chopper_client_provider.dart`,
    > `network_info.dart`, `infrastructure_providers.dart`, `app_logger.dart`.
    > Files the app still genuinely needs but that reference one of the above
    > (`error_handler.dart`, `provider_observer.dart`, `bootstrap.dart`) keep
    > being written, just with their internal `AppLogger` import redirected to
    > `corePackageName ?? packageName` instead of duplicating it — the same
    > redirect pattern as every other cross-boundary import this phase. Left
    > deliberately untouched: `app_route_path.dart` — purely cosmetic duplication
    > (no shared mutable state, unlike `theme_mode_controller`/`app_logger`),
    > referenced by 8+ router-template call sites, higher blast radius than
    > payoff for now.
    > Harness-proven: the existing packageSplit+chopper test's assertion changed
    > from reading the app's dead `chopper_model_converter.dart` content to
    > asserting the file no longer exists at all. Full targeted (dio/chopper/
    > go_router_builder/offline-first), fast (`--exclude-tags integration`,
    > 165/165), and full integration (`--tags integration`) suites all green —
    > zero regressions.
> - ✅ **Phase 2, offline+sync/Outbox — done**. Same mechanical redirect
    > pattern as every other core/-boundary fix this phase: `sync_service.dart`
    > moves into the core package when packageSplit is on (`_writeCorePackage`
    > gained `hasSync`), the app stops writing its own copy (dead code, gated on
    > `corePackageName == null` — same as every file in the "clean up the
    > duplicated core/" note above), and `featureRepositoryProviders()`'s one
    > remaining unredirected import (`core/sync/sync_service.dart` — the only
    > spot in that function still hardcoded to `packageName`) now uses
    > `corePackageName ?? packageName`. `packageSplitSupported`/`canPackageSplit`
    > dropped the `!hasSync` restriction — every storage strategy (remote-only,
    > offline-first read, offline-first + sync) now works with packageSplit.
    > Harness-proven: a new integration test generates packageSplit +
    > `offlineFirstSync`, asserts core ships `sync_service.dart` importing its
    > own `network_info.dart`, the app has no copy, the split feature's
    > `SyncService` provider crosses into core, and `flutter analyze` 0/0. Full
    > suite still green.
> - ✅ **Phase 2, Supabase/Firebase backends — done**. Dropped `!hasBackend`
    > from `packageSplitSupported`/`canPackageSplit` — dio/chopper/supabase/
    > firebase all work now, with auth/realtime/storage.
    >
- `_writeCorePackage` gained `httpClient == 'supabase'/'firebase'`
  > branches (mirrors dio/chopper exactly) writing `supabase_provider.dart`/
  > `firebase_provider.dart` into core; the app's own copies are skipped
  > when split (same dead-code gating as every other core/-boundary file).
  > `networkErrorHandler` needed no changes — it was already httpClient-
  > driven (dio/chopper/supabase/firebase branches all pre-existed from
  > §5d), just never actually exercised with `corePackageName` before since
  > the combo was excluded.
>   - **Auth becomes its own workspace package too — `packages/<app>_auth/`**
      > (superseding an earlier draft of this note that kept Auth app-level).
      > Compared directly against **wesioo**: it splits auth into a standalone
      > `packages/authentication` with **zero** workspace dependencies — its own
      > `Result`/`Failure`/`UseCase`/network interceptors/secure storage,
      > literally copy-pasteable into another app — while its screens/routes/
      > form-state stay in `lib/features/auth/`. NEAT deliberately diverges:
      > the whole feature (screens included) moves into the package, but it
      > depends on `<app>_core` for `Result`/`Failure`/`UseCase` like every
      > other split feature, rather than duplicating them — consistent with
      > NEAT's own single-core-dependency model, and avoiding a second,
      > divergent "zero-dep package" pattern that would only exist for Auth.
      > Mechanically the same conversion as Phase 1 Step 2a's first split
      > feature: `AuthTemplates` gained `authPackageName` (relative self-imports
      > for same-feature references, e.g. `authRepositoryImpl`'s
      > `i_auth_repository.dart` import) alongside the existing
      > `corePackageName` (Result/Failure/client-init-provider/`AppRoutePath`
      > redirects). `router_notifier.dart` — the go_router guard — always stays
      > app-level (it's plumbing, not a feature) but its `auth_provider.dart`
      > import now crosses into the auth package when split, mirroring how
      > `routesAggregator` already crosses into any other split feature's page.
      > `_writeAuth` writes the package's own `pubspec.yaml` (reusing
      > `CorePackageTemplates.featurePackagePubspec`, the same function every
      > other split feature's pubspec already uses), and the auth route
      > aggregator import/build_runner pass follow the established per-package
      > pattern. `ProjectLoader.scanFeatures`'s `nonFeatureSuffixes` gained
      > `'auth'` so the Workshop doesn't mistake the auth package for an
      > addable/existing CRUD feature.
>   - **Another real bug found via a failing integration test**:
      > `_writeCorePackage`'s call to `CoreTemplates.appRoutePath()` never
      > passed `hasAuth`, so core's `AppRoutePath` mirror never got the
      > `login`/`signup`/`forgotPassword` constants — invisible until Auth
      > actually became a package that imports `AppRoutePath` from core (every
      > auth screen/route file failed to resolve `AppRoutePath.login` etc.).
      > Fixed by threading `hasAuth` through that call, mirroring the app's own
      > already-correct call.
>   - `storage_service.dart`/`avatar_upload_field.dart` stay app-level
      > (nothing NEAT generates imports them cross-package), but
      > `storageService()`'s one import of the client-init provider still
      > redirects to `corePackageName ?? packageName`, since *that* file does
      > move when split.
>   - **Two real bugs found and fixed along the way** (both pre-existing,
      > never exercised before since backend+packageSplit was excluded):
      >
1. `CorePackageTemplates.pubspec()` never added `supabase_flutter`/
   > `cloud_firestore` (+ `firebase_auth`/`firebase_storage` when
   > auth/storage are on) to the core package's own dependencies — it
   > only ever branched on chopper vs. dio. Without this, riverpod
   > codegen for `supabase_provider.dart`/`firebase_provider.dart`
   > silently failed to produce its `.g.dart`, cascading into
   > `Undefined name 'supabaseClientProvider'` everywhere that imported
   > it. Now a full `switch` on `httpClient` adds the right SDK dep(s).
>     2. `PresentationTemplates._riverpodListStreamNotifier` (the realtime
         > list notifier — `dataList && realtime`) hardcoded its two
         > same-feature imports (`_repository_providers.dart`/`_entity.dart`)
         > as `package:$packageName/features/$featureName/...` instead of a
         > plain relative import, unlike every other same-feature cross-layer
         > import in this codebase. Invisible outside packageSplit (the app
         > always resolves its own package name), but a genuine feature→app
         > import once split. Fixed to match `_riverpodListNotifier`'s existing
         > relative-import convention; the now-fully-unused `packageName` param
         > was deleted from `featureProvider()` rather than threaded through
         > dead (one call site, `feature_scaffolder.dart`).
>   - Harness-proven: two integration tests — packageSplit + Supabase + auth
      > (asserts core ships `supabase_provider.dart`, nothing is left under
      > `lib/features/auth/`, the auth package's `Result`/`Failure`/client
      > imports redirect to core while its self-reference stays a relative
      > import, `router_notifier.dart` crosses into the auth package, and the
      > split feature's own DI crosses into core too) and packageSplit +
      > Firebase + auth + realtime + storage (same, plus `firebase_provider.dart`'s
      > auth/storage singletons, the realtime `watchAll()` stream, and
      > `storageService`'s redirected import) — both `flutter analyze` 0/0.
      > Full suite (including every pre-existing non-split Supabase/Firebase
      > test, which stays on the unsplit `lib/features/auth/` path unchanged)
      > still green.
> - ✅ **Retrofit dropped entirely** — it was never selectable in the wizard
    > (`isUnsupportedPackage`) and its API-source template had zero
    > generation-harness coverage, so "Phase 2, remaining — retrofit" above was
    > never going to close. Removed rather than left gated: the `retrofit`
    > preset/enum value/template branch, `hasRetrofit`/`isRestClient`/
    > `isDioBased`/`isDioLike` derivations, the disabled "Retrofit" card on the
    > Infrastructure screen, and every doc-comment mention across the generator.
    > `isUnsupportedPackage` still blocks `retrofit`/`retrofit_generator` by name
    > (a pub.dev search shouldn't look like a dead end), and
    > `dev_packages_whitelist.dart` still lists `retrofit_generator` alongside
    > every other never-implemented generator (hive_generator, auto_route_generator,
    > etc.) — both deliberately untouched for consistency. Chopper remains the
    > one annotation-driven REST client; dio the one plain one. Full suite green.
> - ✅ **i18n scoping — resolved: no per-package split, but a real bug fixed**.
    > Raised by comparing against `maxit-front-flutter` (a real multi-dev Melos
    > monorepo) — its `packages/feature/<name>/` each ship their own `l10n.yaml`
    >
+ prefixed `.arb` files, rather than one global translation file. Decided
  > **against** replicating that for NEAT's slang setup:
    >
- slang's config only reads from **one** `input_directory` — it can't
  > aggregate `.i18n.json` files that live in genuinely separate workspace
  > packages (each with its own `lib/`) into one generated class. Doing this
  > "properly" would need either independent slang instances per package
  > (unverified whether slang exposes a clean way to avoid a `Translations`/
  > `AppLocale`/`context.t` symbol collision the moment a page needs two
  > packages' translations at once) or a fragile file-copying step.
>   - Translations are cross-cutting by nature (shared strings, the language
      > switcher itself) — unlike code, which has clear per-feature ownership.
      > Even maxit keeps its own app-level `l10n/` for shared strings alongside
      > the per-feature split — a hybrid, not a clean per-package boundary. The
      > real problem it solves there (merge contention on one shared JSON file
      > across a big team) is a softer problem than the cycle discipline the
      > redirects elsewhere in this section solve.
>   - **Found and fixed a real bug while scoping this**: unlike every other
      > cross-cutting concern (`theme_mode_controller`, `AppLogger`, dio/
      > chopper providers), i18n had **never** been redirected to
      > `corePackageName` at all — a split feature's page, `bootstrap.dart`, and
      > `app.dart` all unconditionally imported slang's `strings.g.dart`/
      > `LanguageSwitcher`/`LocaleStore` from the **app**, a genuine
      > feature→app import (the exact cycle packageSplit exists to avoid),
      > simply never caught because no test combined `packageSplit` + i18n
      > before. Fixed the same way as everything else in this section: the
      > whole slang setup (config, translation files, generated
      > `strings.g.dart`, `locale_store.dart`, `language_switcher.dart`, the
      > `dart run slang` codegen pass) is now single-sourced in the core
      > package when `packageSplit` is on — the app stops writing its own copy
      > entirely, and `PresentationTemplates`/`AppTemplates.appDart`/
      > `AppTemplates.bootstrap` all redirect to `corePackageName ?? packageName`.
      > `CorePackageTemplates.pubspec` gained a `hasI18n` param for the slang/
      > `shared_preferences` deps. Harness-proven: a new integration test
      > generates packageSplit + i18n, asserts core ships the whole setup, the
      > app has zero i18n files of its own, and the split feature's page/
      > bootstrap.dart/app.dart all cross into core, never the app — `flutter
>     analyze` 0/0. Full suite still green.
> - ✅ **Phase 3 — child routes (the concrete cross-feature case) — done,
>   narrower than originally framed**. The plan going in was a new
>   `shared_contracts` package for "two features that reference each other's
>   types." Implementing the one concrete, already-blocked use case (a
>   Workshop child route nested under an existing split feature — previously
>   `GenerateFeatureUsecase` threw a clear rejection) turned out **not** to
>   need a third package type at all:
>   - **Plain go_router**: the child's `GoRoute` nests inside the parent's
>     *within the app's own shared `routes.dart`* — the app already depends
>     on every feature package for their top-level routes, so this needed
>     zero new dependencies, just redirecting the child's page import to its
>     own package (`wireChildIntoRoutes` gained an optional
>     `childPackageName`, mirroring `_wireRoutes`' existing `featurePackageName
>     ?? packageName` pattern for non-child features).
>   - **go_router_builder**: genuinely the harder case — the nested
>     `TypedGoRoute<ChildRoute>` + `ChildRoute` class live inside the
>     **parent package's own** `<parent>_routes.dart`, so the parent really
>     does need to import the child page directly. Solved with a plain
>     one-way `path:` dependency (parent → child) via a new
>     `_addPathDependencyToPackage` — not a cycle (the child never depends
>     back), so nothing a `shared_contracts` package would have done
>     differently. Also needed: the *parent* package's own `build_runner`
>     pass has to re-run after this edit (a new `$ChildRoute` mixin the
>     parent's edited routes file now references) — previously feature-gen
>     only ever re-ran build_runner for the *new* feature's own package.
>   `AppRoutePath`'s nested `'/parent/child'` constant gained the same
>   dual-write (app's own copy + core's mirrored copy) every other
>   packageSplit wiring point already has.
>   **The broader "arbitrary shared_contracts for any two features to share
>   an entity" case stays deferred** (see Backlog) — genuinely still an open
>   design question (what belongs in the shared package, when does NEAT
>   generate one, how does the Workshop route a reference into it), and nothing
>   about the child-route fix above resolves it; child routes just didn't
>   turn out to need it.
>   Harness-proven: new unit tests for both `wireChildIntoRoutes`/
>   `wireChildIntoTypedRoutes`' packageSplit branch; the existing Step 2b
>   integration test's "child routes are rejected" assertion flipped to assert
>   the now-working wiring instead; a new dedicated integration test adds a
>   go_router_builder child feature to an existing split project and asserts
>   the parent's `path:` dependency, its regenerated `$ChildRoute` mixin, the
>   dual-write `AppRoutePath` constant, and 0/0 analyze across the resulting
>   4-package workspace. Full suite green.
> - Everything else (Supabase/Firebase, auth, i18n, realtime, flavors, CRUD-UI,
>   layer-first) stays **out of scope** until its own phase — don't combine an
>   unproven structural change with unrelated unproven combos.
> - ✅ **Package naming simplified: drop the app-name prefix, except the
>   extracted UI package** — done. Every split package used to be prefixed
>   with the app name (`<app>_core`, `<app>_local_storage`, `<app>_auth`, and
>   the split feature itself, `<app>_<feature>`), mirroring `<app>_ui`'s own
>   naming. In practice that just made `packages/` noisy: within a Dart
>   workspace, package names only need to be unique from each other, not
>   globally, so the app-name prefix on `core`/`local_storage`/`auth`/
>   `<feature>` added nothing a dev actually reads or types. Now those four
>   are named plainly (`core`, `local_storage`, `auth`, `<feature>`) — only
>   `<app>_ui` keeps its prefix (deliberately, to avoid reading as a
>   too-generic bare `ui`). `<app>_widgetbook` also keeps its prefix, for an
>   unrelated, harder reason: it can't be named just `widgetbook`, since it
>   depends on the real `widgetbook` pub package. `ProjectLoader.scanFeatures`
>   updated to match: a feature package is no longer detected by stripping a
>   `<projectName>_` prefix — every directory under `packages/` that isn't
>   `core`/`local_storage`/`auth`/the UI package name is a feature. Harness-
>   proven: full integration suite (44 tests) re-verified green after the
>   rename, including one formatting-only fix (an `import ... as home;` line
>   no longer word-wraps across two lines now that the alias is shorter).
> - ✅ **`ApiConfig` bridges `apiBaseUrl` into the core package — real bug,
>   found via a real packageSplit + envied + chopper project** — done. The
>   core package's dio/chopper client provider hardcoded `useEnvied: false`
>   unconditionally (it can't import the app's `AppEnv` — that would recreate
>   the app→feature cycle packageSplit exists to avoid), so every split
>   feature's remote call silently hit an empty `baseUrl` —
>   `Invalid argument(s): No host specified in URI users` at runtime, found
>   from a real device log (the wizard's own FakeStore example feature
>   masked this, since it uses an absolute-URL override that bypasses
>   `baseUrl` entirely — only a Workshop-added feature with a normal relative
>   path exposed it). Fixed with the same "set a static value from the
>   composition root, read it as ambient state everywhere else" shape
>   `AppEnv.setEnv(env)` itself already uses: a new `core/network/
>   api_config.dart` (`ApiConfig.baseUrl`, a plain settable `String`),
>   `bootstrap()` assigns it once from `env.apiBaseUrl` before `runApp`
>   (only when `hasEnvied && corePackageName != null` — gated the same as
>   every other packageSplit redirect), and `CoreTemplates.dioProvider`/
>   `chopperClientProvider` gained a `sharedConfig` param so the core
>   package's own copy reads `ApiConfig.baseUrl` instead of
>   `AppEnv.current.apiBaseUrl`. Supabase/Firebase were never affected — their
>   core-side providers just read an already-initialized singleton
>   (`Supabase.instance.client`), with the actual `Supabase.initialize(...)`
>   call (which does need `AppEnv`) already living in `bootstrap()` itself,
>   app-side. Harness-proven: a new integration test generates packageSplit +
>   chopper + envied, asserts `api_config.dart`'s content, the client
>   provider reading `ApiConfig.baseUrl` (never importing `AppEnv`), and
>   `bootstrap()`'s bridge line, plus `flutter analyze` 0/0 across the whole
>   workspace. The real project that surfaced this was hand-patched directly
>   (same immediate-unblock precedent as every other real-bug fix this
>   session) alongside the generator fix.
> - ✅ **Shell page registry + sub-routes under a shell branch** — done,
>   two real gaps found via a real packageSplit + go_router_builder + shell
>   project (two branches, no way to add a third-level route under either).
>   - **Sub-routes under a shell branch (the actual blocker)**: the
>     Workshop's child-route wiring assumed `parentFeature` always owned a
>     standalone `<parent>_routes.dart` — a shell branch's route lives inside
>     `app_shell_route.dart`/`routes.dart` instead, so this **silently
>     no-op'd** for the typed case (the file it looked for never existed —
>     the child got generated but never wired into any route, no error) and
>     **corrupted the file at the wrong location** for the plain case
>     (`_addChildrenAnchorToParent`'s `\n  ),` proximity match found an
>     unrelated closing paren, since a shell branch's `GoRoute` sits 3 levels
>     deeper than the flat top-level case it was written for). Fixed by
>     making every shell branch template (`appShellRouteBuilder`/
>     `shellBranchBuilder`/`shellRouteEntryPlain`/`shellBranchPlain`)
>     **proactively** carry a nested `routes: [ // neat:typed-children:<f> ]`
>     (typed) / `// neat:children:<f>` (plain) clause from the moment the
>     branch is created — reusing the exact same anchor names (and the same
>     `wireChildIntoTypedRoutes`/`wireChildIntoRoutes`-adjacent transform
>     shape) the top-level child-route mechanism already established, just
>     new sibling entry points (`wireChildIntoTypedShell`/
>     `wireChildIntoPlainShell`) since a shell host needs a different
>     detection/self-heal strategy. Detecting "is this parent a shell
>     branch" is now a simple, 100% reliable anchor-presence check — no more
>     fragile indentation/proximity guessing.
>   - **Self-heal for existing (pre-fix) shell branches**: a legacy flat
>     branch (no anchor at all — e.g. a project generated before this fix)
>     gets its nested `routes: [...]` clause retrofitted the first time a
>     child is nested under it, via a **corrected balanced-paren scan**
>     (walks from the owning `GoRoute(`/`TypedGoRoute<...>(` to its own
>     matching close, replacing the old proximity-match bug rather than
>     reusing it) — and only that specific branch; sibling branches stay
>     untouched (narrow fix, matching how `_addChildrenAnchorToParent`
>     already self-heals lazily per-parent, not eagerly for everything).
>   - **Shell page registry (decoupling, not strictly required by the
>     dependency-direction rules)**: `app_shell_route.dart`/`routes.dart`
>     live in the app, which can always import any feature package directly
>     (app→feature, never the cycle packageSplit forbids) — so this wasn't
>     fixing a correctness bug the way the sub-routes gap was. Built anyway,
>     by explicit choice, mirroring `maxit-front-flutter`'s own pattern of
>     keeping a shell-owning file from hard-importing every branch's page.
>     Mirrors `chopperModelDecoders`' exact shape: a new
>     `core/router/shell_page_registry.dart` (`shellPageBuilders`, a plain
>     `Map<String, ShellPageBuilder>` + `lookupShellPage`), each shell-branch
>     (or shell-branch-child) feature gets a small new
>     `<f>_shell_registration.dart` (`register<Feature>ShellPage()`), and
>     `bootstrap()` calls every registered one before `runApp` via new
>     `// neat:shell-register-imports`/`-calls` anchors — same "self-register,
>     call from bootstrap" shape `_registerChopperDecoderSplit` already uses,
>     down to a new `CorePackageTemplates.pubspec` `useShell` param (the
>     registry needs `go_router` for `GoRouterState`, which a bare `core`
>     package never depended on before). Only active when packageSplit is on
>     — non-split shell branches have no cross-package coupling to solve, so
>     they keep direct imports, byte-identical to before.
>   - **Composition**: a child nested under a shell branch is, once the
>     registry exists, structurally identical to a top-level branch (both
>     are pages an app-owned file references) — so it also registers itself
>     and reads the registry, never a direct import, regardless of whether
>     its *parent* branch predates the registry (a real project — a legacy
>     branch stays on direct import; only the new child uses the registry —
>     confirmed correct: mixed direct-import/registry state is already
>     normal here, same as chopper's own two registration mechanisms).
>   - **Real bug, found running the fix against a copy of the actual project
>     that motivated this**: the self-heal path (Workshop adds a child under
>     an *existing* pre-registry shell branch) created the registration
>     wiring in `bootstrap.dart` but never created
>     `shell_page_registry.dart` itself (that only ever happened at wizard
>     time or when a *new* branch was added) — and, once created, its
>     `go_router` import had no matching pubspec dependency (`core`'s
>     pubspec never needed `go_router` before). Both fixed:
>     `_registerShellPageSplit` now creates the registry file (and adds the
>     `go_router` dependency) the first time it's needed, not just wires
>     `bootstrap.dart`.
>   - Harness-proven: new unit tests for the registry (packageSplit vs.
>     direct-import template output) and sub-routes (nest under a fresh
>     anchored branch, self-heal a legacy branch then nest, a corruption-
>     regression case reproducing the exact old bug), new integration tests
>     (packageSplit + go_router_builder AND plain go_router, 2 shell branches
>     + 1 nested child, asserting the registry/registration files/bootstrap
>     wiring/pubspec deps and `flutter analyze` 0/0), and the fix re-run
>     directly against a copy of the real project that surfaced it end to
>     end. Full suite green.
> - ✅ **Merge a child route into its parent (opt-in) — done, real bug found:
>   cross-layer relative imports weren't nesting-depth-aware**. Idea from a
>   real Workshop session: a "apparence" feature added as a child route of
>   "profile" felt like it should just be a settings sub-page of profile, not
>   a whole separate feature/package — mirrors `maxit-front-flutter`'s
>   `packages/feature/profile`, which groups several sub-features
>   (`page/<sub>/`, `data/<sub>/`) inside one package. Confirmed the design
>   with the user before building: own entity/repository/datasource (never
>   extending the parent's — risks clobbering the user's own hand-edits to
>   already-generated files), organized in a `<child>/` subfolder at each
>   layer inside the parent's own package/folder, and the child's routing
>   still injects into the parent's own routes file exactly as it already did
>   for a non-merged child (no change needed there beyond the page import
>   path). `FeatureGenOptions.mergeIntoParent` (opt-in, only meaningful for
>   Child Route — Workshop toggle + Blueprint Overview preview both gate on
>   it) and a new `FeatureScaffolder.writeFeature` `mergeBase` param: when set,
>   it takes priority over packageSplit/isFeatureFirst and re-roots
>   `domain/data/presentation` under it, each gaining a `$featureName/`
>   subfolder — exactly the existing (but never packageSplit-relevant)
>   layer-first shape, just re-rooted at the parent instead of the app.
>   Initially not offered when the parent is a shell branch (that already has
>   its own registry-based mechanism — combining the two wasn't explored yet,
>   same "don't combine an unproven combo" discipline as Custom Endpoints +
>   packageSplit) — **later extended, see the second follow-up below**. Still
>   rejected with Custom Endpoints (its own `EndpointTemplates` cross-layer
>   imports aren't nesting-aware either — rejected clearly, same as the
>   packageSplit case).
>   **Real bug, found by the integration tests this feature needed (not
>   theorized)**: every cross-layer relative import in `data_templates.dart`/
>   `presentation_templates.dart` (model → entity, repository impl → entity +
>   i-repository, repository providers → i-repository, usecase providers →
>   repository providers + usecases, list page/notifier → entity) hardcoded a
>   fixed `'../../domain'`/`'../../data'` prefix — correct only when
>   `domainBase`/`dataBase`/`presentationBase` are direct siblings under a
>   shared root (the packageSplit and isFeatureFirst branches). Nesting a
>   `$featureName/` folder *inside* each layer (both the new `mergeBase`
>   branch and, latent all along, the pre-existing but never-integration-
>   tested layer-first/non-featureFirst pattern) adds one more directory
>   level and moves the sibling layer's own `$featureName/` folder into the
>   path — e.g. `data/reviews/models/reviews_model.dart` needs
>   `'../../../domain/reviews/entities/reviews_entity.dart'`, not
>   `'../../domain/entities/...'`. Every affected template function gained a
>   `domainCross`/`dataCross` param (default: the old 2-up literal, unchanged
>   for every existing caller), computed once in `FeatureScaffolder
>   .writeFeature` from a `crossLayerNested` flag (`mergeBase != null ||
>   (!packageSplit && !isFeatureFirst)`) and threaded through — fixing the
>   layer-first architecture pattern's own latent bug as a side effect, not
>   just the new merge case. Harness-proven: new unit tests for
>   `wireChildIntoRoutes`/`wireChildIntoTypedRoutes`'s merged-import branches
>   and `FeatureScaffolder`'s `mergeBase` path + cross-layer-import content
>   (the existence-only version of this test passed despite the broken
>   imports — content assertions are what caught the bug), and two new
>   integration tests (packageSplit + go_router_builder, and non-split
>   feature-first + plain go_router) each merge a child into a parent and
>   assert no new package/workspace member/path dependency, files nested
>   under a `<child>/` subfolder per layer, the parent's routes file import
>   (relative for the typed/same-package case, `package:`-redirected-into-
>   parent for the plain/app-shared-routes.dart case), and `flutter analyze`
>   0/0. Full suite green.
>   - ✅ **Follow-up: two real crashes found via a real packageSplit +
>     go_router_builder + chopper project — done**. The harness above never
>     combined merge with chopper, so it missed both:
>     1. **`_registerChopperDecoderSplit`'s call site force-unwrapped
>        `featurePackageName!`** unconditionally whenever `packageSplit` —
>        when merged, `featurePackageName` is `null` by design (no separate
>        package), so this threw `Null check operator used on a null value`
>        the moment a merged feature also used chopper (the Workshop's own
>        "Merging ... into parent ..." log, then a crash with no further
>        progress). Fixed: the caller now passes `parentPackageName!` instead
>        when merging, and `_registerChopperDecoderSplit` gained a
>        `mergeIntoParent` flag so the `bootstrap.dart` import it wires
>        points at the merged child's actual nested location
>        (`data/$featureName/repositories/...` inside the *parent's* package,
>        not that package's own root).
>     2. **The per-feature `build_runner` re-run also assumed a separate
>        package existed** (`packages/$featurePackageName`, `null` when
>        merged — would have targeted a nonexistent `packages/null`). Fixed:
>        when merging it now runs in `packages/$parentPackageName` instead
>        (the merged child's own newly-generated annotated files live there
>        now) — and the separate go_router_builder-only "re-run the parent
>        package" step right after it is skipped in that case (redundant,
>        already covered).
>     Also addressed a related **silent-mismatch UX gap** (not a crash, but
>     reported in the same session): merging is intentionally not offered for
>     a shell-branch parent (see above), and the Workshop enforces that
>     server-side — but the Blueprint Overview preview and the toggle itself
>     can't know a parent is a shell branch without a filesystem check, so
>     they still showed "merged" while the actual result silently generated a
>     normal, non-merged child. The generation log now says so explicitly
>     (`"Merge into parent" is ignored for a shell-branch parent ...`) instead
>     of silently diverging from what the toggle showed; the preview-side
>     mismatch itself is a known, accepted cosmetic limitation (fixing it
>     would need the Workshop to inspect the project's filesystem on parent
>     selection, not just its already-loaded `.neat.json` state).
>     Harness-proven: the packageSplit merge integration test above switched
>     from dio to chopper (mirrors the "packageSplit + chopper" test's own
>     combo) specifically to exercise this path, with new assertions on
>     `bootstrap.dart`'s import (`package:home/data/reviews/repositories/
>     reviews_repository_providers.dart`) and its register call — both would
>     have caught this before it ever reached a real project. Full suite
>     green.
>   - ✅ **Second follow-up: mergeIntoParent extended to shell-branch parents
>     — done, prompted by the exact same real project** (the shell-branch
>     restriction above was still live when the user retested "ingredient"
>     merging into "recepies", a real bottom-nav shell branch — same silent-
>     mismatch UX gap flagged in the first follow-up, but this time the user
>     asked to actually close the gap rather than just surface it). Dropped
>     the `!parentIsShellBranch` condition from `mergeIntoParent`'s
>     computation entirely. The registry (`shell_page_registry.dart`) exists
>     to keep `app_shell_route.dart`/`routes.dart` from hard-importing every
>     branch's page — but a merged child's page now lives *inside* the
>     parent's own package, which the app already depends on directly (it's a
>     top-level shell branch), so that reason doesn't apply: `needsShellRegistration`
>     is now `... && !mergeIntoParent` (no `<f>_shell_registration.dart` written
>     for a merged child), and `wireChildIntoTypedShell`/`wireChildIntoPlainShell`
>     gained a `mergeIntoParent` branch that imports the child's page directly
>     from its new nested location (`package:$parentPackageName/presentation/
>     $childFeature/pages/...`, mirroring the non-shell merge case's import
>     shape) and constructs it directly (`const ChildPage()`) instead of
>     `lookupShellPage(...)` — skipping the registry call-site wiring
>     entirely. Every other merge mechanic (`mergeBase` scaffolding, the
>     `domainCross`/`dataCross` cross-layer import fix, the chopper decoder
>     registration fix, the `packages/$parentPackageName` build_runner re-run)
>     already worked unchanged for a shell-branch parent — none of that logic
>     ever checked `parentIsShellBranch` itself, only `mergeIntoParent`, so
>     lifting the one restriction was sufficient. Workshop toggle's subtitle
>     updated to match (was "ignored if the parent turns out to be a shell
>     branch"). Harness-proven: two new unit tests (`wireChildIntoTypedShell`/
>     `wireChildIntoPlainShell`'s `mergeIntoParent` branch — asserts no
>     registry/`lookupShellPage` reference, a direct import + construction
>     instead) and a new integration test reproducing the exact real scenario
>     (packageSplit + go_router_builder + chopper + a "recepies" shell branch
>     merging in "ingredient") — asserts no separate package, the direct
>     `app_shell_route.dart` import, no shell-registration file/bootstrap
>     call, the chopper decoder import pointing at the merged nested path,
>     and `flutter analyze` 0/0 across the workspace. The pre-existing (non-
>     merged) shell-child integration tests re-verified green, unaffected.
>     Full suite green.
> - ✅ **packageSplit without a first feature — done** (user noticed:
>     turning off "Generate example feature" grayed out the packageSplit
>     toggle, and since packageSplit can't be turned on retroactively on an
>     existing project, skipping it at launch meant losing access to it
>     forever — even though the Workshop treats every feature-add identically
>     regardless of whether it's the 1st or 5th). The UI's own
>     `canPackageSplit` required `generateFirstFeature`, but the generator's
>     own `packageSplitSupported` never did — an unnecessary UI restriction,
>     confirmed by reading both gates side by side. Proved the combo with a
>     new integration test rather than trusting that reasoning alone, which
>     surfaced two real bugs:
>   - **Bug 1**: `_writeCorePackage`'s own `CoreTemplates.appRoutePath(...)`
>     call never passed `hasFirstFeature`, so it always defaulted to `true`
>     and wrote `AppRoutePath.home` — while the app's router files (which do
>     respect `generateFirstFeature`) referenced `AppRoutePath.welcome`,
>     producing an `undefined_getter` error. Then, when the Workshop later
>     added the real "home" feature, its own `AppRoutePath.home` insertion
>     collided with the stale one core already had, producing a
>     `duplicate_definition` error too. Fixed by threading a new
>     `hasFirstFeature` param through `_writeCorePackage`, set from
>     `architecture.generateFirstFeature` at its call site.
>   - **Bug 2** (pre-existing, only ever masked): `CorePackageTemplates.pubspec`
>     hardcoded stale `riverpod_annotation: ^4.0.2` / `riverpod_generator:
>     ^4.0.3` floors, while `featurePackagePubspec` (the split feature
>     package) hardcodes newer `^4.0.3`/`^4.0.4`. In a pub workspace, a
>     feature package's higher floor always dragged the whole workspace up to
>     a mutually-compatible version — silently hiding that core's own pins
>     were stale, in every packageSplit combo tested until now. With no
>     first feature, nothing raises the floor, so the workspace resolved
>     `riverpod_generator: 4.0.3` paired with a `riverpod` core version whose
>     `AnyNotifier.runBuild` signature had already moved on (`WhenComplete
>     Function()`, not `void`), producing an `invalid_override` error on the
>     generated `theme_mode_controller.g.dart`. Found by generating both
>     combos side by side and diffing the actual resolved `pubspec.lock`
>     versions and generated `.g.dart` output, not by reasoning alone. Fixed
>     by bumping `CorePackageTemplates.pubspec`'s floors to match
>     `featurePackagePubspec`'s.
>   - `canPackageSplit` (`architecture_screen.dart`) no longer requires
>     `generateFirstFeature`; the toggle's description branches on whether a
>     first feature is present (mentions the Workshop when it isn't) instead
>     of listing it as a requirement.
>   - Harness-proven: a new integration test generates `packageSplit: true` +
>     `generateFirstFeature: false`, asserts the core package exists with
>     zero feature packages, `lib/features/` never existed, the welcome
>     placeholder owns the root route, then drives the Workshop to add "home"
>     as the real first feature and asserts it lands as its own split
>     package depending on core — `flutter analyze` 0/0 for the whole
>     sequence. All 16 packageSplit integration tests green (the 15
>     pre-existing combos + this new one), full fast suite (245 tests) and a
>     project-wide `flutter analyze` green.

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
    - ✅ **Follow-up: onboarding/auth redirects and the app title still leaked
      the wizard's leftover default feature name — done**, found in a real
      user's generated project (`packages/core/lib/core/constants/
      app_route_path.dart` correctly had `welcome` with no first feature, but
      `onboarding_routes.dart` referenced the nonexistent
      `AppRoutePath.product` — `'product'` being `ArchitectureState`'s
      default `firstFeatureName`, left over from the wizard even with the
      toggle off). Root cause: two call sites in
      `launch_generation_usecase.dart` built the "go home" redirect as
      `'AppRoutePath.${_camelCase(featureName)}'` unconditionally — the
      onboarding page's `onDone` callback, and the post-login auth guard in
      `router_notifier.dart` — neither checked `generateFirstFeature`, unlike
      `CoreTemplates.appRoutePath` itself (which already branches on
      `hasFirstFeature` correctly) or `_writeRouter` (which already routes
      `app_router.dart`/`routes.dart` to the welcome placeholder). Fixed with
      one shared `_homeRouteExpr({featureName, hasFirstFeature})` helper
      (`AppRoutePath.welcome` when `!hasFirstFeature`, mirroring
      `CoreTemplates.appRoutePath`'s own branch) used at both sites, with
      `hasFirstFeature` threaded into `_writeAuth`'s params. Also fixed in
      passing, a real bug independent of this toggle: `app.dart`'s
      `MaterialApp(.router)` `title:` was wired to `featureName` too — the
      app's window/task-switcher title was always the example feature's
      name, not the app's own — now uses `packageName`. Harness-proven: a new
      integration test generates onboarding + auth + `generateFirstFeature:
      false` together (the exact combo that exposed this — neither existing
      onboarding test nor the no-first-feature tests combined the two) and
      asserts both redirects target `AppRoutePath.welcome`, the app title is
      the project's own package name, and `flutter analyze` 0/0. Full
      onboarding suite (5 tests) and fast suite (245 tests) still green.
    - ✅ **Follow-up: `docs/REMOVE_FIRST_FEATURE.md` — done** (user question:
      can the wizard's first feature be deleted later, e.g. to drop the
      FakeStore Products demo once real features exist?). Investigated
      building an actual delete-feature capability first — rejected: a
      feature isn't self-contained in its own folder, it also inserts lines
      into up to ~12 categories of shared files (routes.dart, AppRoutePath,
      the chopper decoder registry, the Drift database, root/package
      `pubspec.yaml` for packageSplit, the shell registry/nav bar...), and
      neither `NeatContract` nor `ProjectLoader` track which files a given
      feature touched (features are derived by scanning `lib/features/`/
      `packages/`, not recorded) — building safe deletion would mean adding
      that tracking first, disproportionate effort for what's usually a
      one-time cleanup. Shipped the cheaper alternative instead: a generated
      `docs/REMOVE_FIRST_FEATURE.md` (written whenever `generateFirstFeature`
      is on, alongside the feature itself) that spells out every file to
      revert, computed from the exact same flags the generator used —
      routing always; the chopper decoder registry only when `httpClient ==
      'chopper'`; the Drift database only when offline-first (with a
      migrations-anchor line only when sync is also on); workspace/pubspec
      wiring only when packageSplit; the nav shell only when a shell branch
      exists. Also points out the simplest path of all: a fresh project with
      **"Generate example feature"** off needs no cleanup at all.
      Harness-proven: added assertions to three already-passing integration
      tests spanning the full conditional matrix — the main chopper +
      offline-sync test (chopper + Drift + migrations sections present,
      packageSplit/shell absent), the plain-go_router no-first-feature test
      (doc absent entirely), and the packageSplit + shell-branches test
      (packageSplit + shell sections present, chopper/Drift absent) — rather
      than standing up a new combo from scratch. Fast suite (245 tests)
      still green.
- ✅ **Phase 2 — Typed endpoints ("Custom Endpoints")** — **done**, scoped down
  from the full vision on purpose. A new opt-in Workshop mode, **alongside**
  (not replacing) Entity + CRUD: a feature is N arbitrary
  `method + path + request/response JSON` endpoints instead of one entity.
  Reuses the Phase 1 inference engine directly — `JsonEntityInferencer.infer`
  gained an optional `requireId: false` (default `true`, every existing call
  site unchanged) so a request/response body with no natural id (e.g. a login
  response with just `token`/`expiresAt`) doesn't get one synthesised.
  Delivered scope, narrower than the original pitch on purpose:
    - **Chopper-only.** No dio/Supabase/Firebase variant — matches the
      pitch's own note below ("use chopper + a typed request model").
    - **Workshop-only**, not the wizard — same precedent as Phase 1.
    - **Remote-only** — no local storage/offline-first/realtime. "N arbitrary
      endpoints" doesn't map onto "one Drift table" the way one entity does.
    - **Data+domain layers only** — one typed chopper method + request/
      response `Model`s + one `UseCase` per endpoint, no repository
      interface (nothing to abstract — there's no entity), no auto-generated
      UI: the feature still gets exactly one placeholder page (same shape as
      the existing zero-data-source case), left for the developer to wire by
      hand.
    - **Not combined with packageSplit** for this pass (rejected with a clear
      exception rather than silently mis-wiring).
  New pieces: `EndpointSpec` (plain value class next to `FieldSpec`, in
  `generation/domain/models/` — not `feature_gen/`, to keep the shared layer
  from depending on the Workshop-specific one) with an `HttpMethod` enum;
  `EndpointTemplates` (own `_freezedModel`/`_plainModel` — deliberately not
  reusing `DataTemplates`'s model templates, which always assume a 1:1 domain
  `Entity` and generate `fromEntity`/`toEntity`; the field-level
  `FieldCodegen` helpers were generic enough to reuse as-is); a
  `FeatureScaffolder.useCustomEndpoints` branch; a Workshop UI mode toggle
  ("Entity + CRUD" / "Custom Endpoints") with a per-endpoint
  `ExpansionTile` row (name/method/path + two `EntityFieldsEditor` instances,
  reused unmodified, for request/response bodies). Harness-proven: a
  dedicated integration test generates a 3-endpoint auth feature (a
  request+response login, a response-only `me`, a bodyless `logout`) and
  asserts no entity/repository/local-source, correct usecase signatures
  (`UseCase<X, Y>` vs `NoParamsUseCase<Unit>`), correct model files (skipped
  entirely for the bodyless endpoint), the chopper decoder registry gaining
  one entry per response model, and `flutter analyze` + build_runner 0/0.
  Two real bugs surfaced only by that test, both fixed: chopper method
  annotations need a **named** `path:` argument (`@POST(path: '/auth/login')`,
  not positional), and the old CRUD chopper-registration/build_runner
  conditions needed an explicit `!useCustomEndpoints` guard so they didn't
  fire with the wrong (CRUD) naming for endpoint-shaped features.

**Notes vs the source pitch:** use chopper + a typed request model (not dio +
`Map<String,dynamic>`); `Response<XModel>` needs a chopper converter that can
deserialize — validate at implementation time.

## State management policy

Keep **Riverpod (annotations + manual Notifier/NotifierProvider) + Bloc/Cubit** only.
GetX / Provider / MobX are considered dated and are out of scope.

## Known gated paths (visible in UI, not yet enabled)

Layer-first.
(retrofit was gated too — dropped entirely instead; manual Riverpod and
bloc/cubit were gated too — both unlocked instead, see § below.)

- ✅ **Bloc/Cubit — unlocked in stub mode (deliberately not full CRUD parity)**.
  `isUnsupportedPackage` blocked any package name containing `'bloc'` outright.
  Unblocking it revealed the templates were already mostly there and correct
  (`StateTemplates.featureCubit`/`featureBloc` + Events/States,
  `ThemeTemplates.brightnessCubit`/`brightnessBloc`, `app_templates.dart`'s
  `BlocProvider` wiring) — just never exercised by a single test, since
  `flutter_bloc` could never actually be selected. Fixed along the way:
    - `PresentationTemplates.featureProvider`'s dead `useCubit`/`_cubitTemplate`
      branch removed — it was leftover from before `StateTemplates` existed,
      always called with `useCubit: false` from its one call site, and would
      have produced the wrong file layout entirely (writing a Cubit into
      `providers/<feature>_provider.dart` instead of `cubit/<feature>_cubit.dart`)
      had a project somehow selected both riverpod and bloc packages at once.
    - `NeatContract` gained a `useCubit` bool. `GenerateFeatureUsecase` used to
      hardcode `useCubit: false` for every Workshop-added feature regardless of
      the project's actual choice — a real bug: adding a 2nd feature to a Cubit
      project would silently generate a full Bloc for it instead. Now reads
      `c.useCubit` from the contract.
    - `buildPubspecContent` auto-injects `flutter_bloc` (mirroring the existing
      go_router_builder → go_router safety net) when a bloc-family package is
      selected but not `flutter_bloc` itself (e.g. the plain, Flutter-less
      `bloc` package from a pub.dev search).
    - `AgentsMdTemplate` gained a real "State management (Bloc/Cubit)" section
      (previously silently omitted the row entirely for non-Riverpod projects)
      that's honest about the stub: no repository-/usecase-level DI graph
      exists for Bloc/Cubit yet, unlike the Riverpod path.
    - **Deliberate scope boundary, decided with the user, same treatment as
      manual Riverpod**: the FakeStore Products witness feature stays a
      placeholder stub in Bloc/Cubit mode (no real data loading, no CRUD) —
      `dataList` is annotation-only (`useAnnotations && hasHttpClient &&
    includeUseCases`), so building full parity would mean designing an
      entire DI mechanism for Bloc/Cubit from scratch (get_it? `RepositoryProvider`?
      manual construction?) — a separate, much larger effort, not this pass.
      The "Generate example feature" toggle's description says so.
      Harness-proven: new integration tests generate a full-Bloc project (with
      only the plain `bloc` package selected, proving the `flutter_bloc`
      auto-injection) and a Cubit project, asserting the right files/classes exist
      (and the *other* variant's folder does *not*), `.neat.json`/`AGENTS.md` are
      accurate, and 0/0 analyze; plus a Workshop test proving a 2nd feature added
      to a Cubit project is generated as a Cubit too (regression test for the
      hardcoded-false bug above). Full suite green.

- ✅ **Bloc/Cubit + chopper: two follow-up bugs, found via a real generated
  project (`bloc_app`)**. `chopper_model_converter.dart` — plain Dart
  (`ModelJsonConverter`/`chopperModelDecoders`/`unwrapChopperResponse`/
  `ChopperApiException`, zero Riverpod imports) — was written only when
  `httpClient == 'chopper' && hasRiverpod`, a leftover from when chopper only
  ever paired with Riverpod. But `<feature>_repository_impl.dart` imports
  `unwrapChopperResponse` **unconditionally** whenever `httpClient ==
  'chopper'`, regardless of state management (the data layer is
  state-management-agnostic — see the Bloc/Cubit entry above) — so every
  Bloc/Cubit + chopper project generated a repository importing a file that
  was never written: `Target of URI doesn't exist`. Fixed by splitting the
  write: `chopper_model_converter.dart` now goes out whenever `httpClient ==
  'chopper'`, full stop; `chopper_client_provider.dart` (an actual Riverpod
  `Provider`/`@Riverpod` — correctly still gated to `hasRiverpod`, since
  nothing in Bloc/Cubit stub mode's missing DI graph consumes it) is
  unaffected. Same root cause, second call site:
  `NetworkErrorHandler.handle()` (`UseCase.call()`'s only catch site) also
  only mapped `ChopperApiException` when `hasRiverpod` — so a Bloc/Cubit +
  chopper project's errors silently fell through to the generic fallback
  message instead of the chopper-specific status-code mapping. Fixed the same
  way (drop the `hasRiverpod` condition from `isChopper`). The user's real
  project was hand-patched with the missing file to unblock it immediately.
  **Found and fixed in passing**: `DomainTemplates.featureGetUsecase`'s
  offline-first branch imported `core/result/result.dart` for no reason —
  `getOrThrow()` is a plain instance method on the sealed `Result<T>` class
  (not an extension), already resolvable via the inferred type without a
  direct import (the repository interface it's called on already imports
  `result.dart` itself) — a real `unused_import` warning present in every
  offline-first integration test's analyze output up to now, unrelated to
  Bloc/Cubit but noticed while re-auditing this exact area. Harness-proven: a
  new integration test generates a Bloc + chopper project and asserts
  `chopper_model_converter.dart` exists (and `chopper_client_provider.dart`
  correctly doesn't), `NetworkErrorHandler` maps `ChopperApiException`, and
  0/0 analyze; `error_handling_test.dart`'s stale "converter file not
  generated" unit test updated to assert the fixed behavior instead. Full
  suite green.

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
- ✅ **Onboarding feature — first-launch-only flow — done**. `ArchitectureState
  .generateOnboarding` (opt-in toggle on the Architecture screen, gated on
  Riverpod annotations — the "seen it" flag needs `@riverpod` — same gating
  as Realtime/Storage). Deliberately narrow scope, matching the earlier design
  pass: NEAT generates `lib/core/onboarding/onboarding_page.dart` (a
  content-free `PageView` skeleton — dots indicator, Skip/Next, 3 placeholder
  slides) and `onboarding_seen_provider.dart` (`@Riverpod(keepAlive: true)`
  bool over `shared_preferences`, `load()`/`markSeen()`, mirroring
  `LocaleStore`'s init-before-runApp convention but as a **provider** so it's
  watchable from a redirect) — both always app-level, no packageSplit
  placement question (no cross-feature dependency to solve). NEAT does **not**
  wire the routing gate itself (bootstrap/app_router stay untouched) — that's
  the scoping call that kept this simple instead of needing to generalize
  across `useNavigationShell`/auth-gated routing/packageSplit all at once, same
  "generator supplies the plumbing, not a guessed policy" principle as the
  Outbox conflict-resolution feature. Instead, `OnboardingPage`'s doc comment
  and the generated `AGENTS.md` (new section, mirroring the i18n one) both spell
  out exactly how to wire a go_router `redirect:`, including the one real
  footgun: go_router only accepts one `refreshListenable`, so a project that
  also has Auth's `RouterNotifier` must merge the check into its `redirect()`
  instead of attaching a second listenable. `shared_preferences` is
  auto-injected into pubspec (deduplicated against i18n's own injection of the
  same package, so enabling both doesn't double the dependency line — a real
  bug caught in `buildPubspecContent`'s tests, not just theorized). `.neat.json`
  gained `generateOnboarding` for the Workshop/contract to track. Harness-proven:
  a new integration test generates a real project with the toggle on, asserts
  the provider/page content, the pubspec dependency, that bootstrap.dart stays
  untouched (proving the "no auto-wiring" scoping decision actually held), and
  0/0 `flutter analyze`. New unit tests for both templates and the pubspec
  dedup case. Full suite green (217 fast tests).
  - ✅ **Follow-up: auto-wired for go_router_builder — done**. The "no
    auto-wiring" call above traded working-out-of-the-box for avoiding a
    combinatorial mess (shell/auth/packageSplit all at once) — reasonable, but
    it meant the feature was invisible until someone hand-wired it, which
    doesn't read as "on" from the UI. Revisited using wesioo's
    `router_notifier.dart` as the reference (one consolidated guard, not
    stacked listenables — validates the existing "merge into RouterNotifier"
    guidance rather than replacing it). Scoped the redo to
    **go_router_builder only** — the one path with a proven guard mechanism
    already (Auth's `RouterNotifier`); plain go_router's own
    `authRoutesPlainEntries()` exists but has never actually been wired
    anywhere, so there's no precedent to build on there yet, and it keeps the
    unwired fallback (unchanged). `autoWireOnboarding = hasOnboarding &&
    hasGoRouterBuilder` in `launch_generation_usecase.dart` now:
    registers `AppRoutePath.onboarding` + a typed `OnboardingRoute`
    (`OnboardingTemplates.onboardingRoutesBuilder`, mirroring
    `AuthTemplates.authRoutesBuilder`'s shape) aggregated into `routes.dart`
    at the existing anchors; makes `OnboardingSeen` itself `implements
    Listenable` (same shape as `RouterNotifier`) so it can be
    `refreshListenable` directly when there's no Auth; when there **is** Auth,
    merges the check into the existing `RouterNotifier.redirect()` instead
    (checked first — shown before even asking to log in) rather than
    attaching a second listenable. The one real gap the "generate the page"
    version had: the persisted flag was never actually loaded before the
    first redirect decision, since that needs a `ref` and `bootstrap()` runs
    before `runApp` — fixed by pre-warming a `ProviderContainer` and handing
    it to `UncontrolledProviderScope` (the exact move `bootstrap()`'s own
    existing doc comment already hinted at). Both `OnboardingPage`'s doc
    comment and the AGENTS.md section now branch on whether the redirect was
    actually auto-wired, so neither ever says "wire it yourself" when NEAT
    already did. Harness-proven: two new integration tests — one mirroring
    the exact reported case (go_router_builder, no Auth, `useNavigationShell`
    — asserts the onboarding route sits as a top-level sibling of the shell
    route, not inside it) and one with Auth on (asserts exactly one
    `implements Listenable` across the generated router code, i.e. the merge
    didn't create a second guard) — both 0/0 `flutter analyze` on the real
    generated project. New unit tests for every modified template
    (`appRoutePath`, `appRouterBuilder`, `bootstrap`, `routerNotifier`,
    `onboardingRoutesBuilder`). Hand-verified by applying the same diff
    directly to the reporter's own nexus project (no Auth, shell,
    go_router_builder) — 0/0 analyze there too. Full suite green (227 fast
    tests).
  - ✅ **Second follow-up: AppRoutePath single-sourced in packages/core for
    packageSplit — done**. Testing the auto-wired onboarding redirect against
    a packageSplit project surfaced a real bug: `_writeCorePackage`'s mirror
    of `AppRoutePath` never got `hasOnboarding` threaded through, so the
    app's own copy had the `/onboarding` constant but the core package's
    mirror didn't — any split feature referencing it (a plausible "Replay
    onboarding" settings action) would fail to compile. Fixed narrowly at
    first (thread the missing param), but the report prompted a bigger
    question: why mirror `AppRoutePath` into two files that must be kept in
    sync by hand at all, when `theme_mode_controller.dart` already proves the
    better pattern (single-sourced in `packages/core`, the app imports it
    from there, zero drift possible by construction)? Investigated why
    `AppRoutePath` didn't already follow that pattern — the Workshop's
    `generate_feature_usecase.dart` has had 6 call sites deliberately
    inserting into *both* copies since packageSplit was built, so the mirror
    wasn't an oversight, just an intentional choice for a plain
    `static const String` class (unlike `theme_mode_controller`, a stateful
    provider where two copies would be two different runtime instances — a
    real bug, not just drift risk). Re-scoped to the version that actually
    holds: **single-source it like theme_mode_controller after all**,
    eliminating the drift-risk class instead of just patching this one
    instance of it. `CoreTemplates.appRoutePath`/`appRouter`/
    `appRouterBuilder`/`routesManual`/`routesManualWelcome`/`welcomeRoute`/
    `routesManualShell`/`appShellRouteBuilder`, `AuthTemplates.routerNotifier`,
    and `OnboardingTemplates.onboardingRoutesBuilder` all gained (or started
    using an already-present) `corePackageName` param redirecting the import
    to `package:$corePackageName/core/constants/app_route_path.dart` — every
    app-level file that references route paths, not just the onboarding-added
    ones. `_buildScaffold` now writes the app's own copy only when
    `corePackageName == null` (non-split). The Workshop needed **zero**
    changes — `_addRouteConstant` already no-ops gracefully when its target
    file doesn't exist, so it silently stops touching the (now nonexistent)
    app copy instead of erroring or recreating it. Harness-proven: new unit
    tests for every fixed template's redirect, the packageSplit onboarding
    integration test now asserts the app copy doesn't exist at all (not just
    that both copies match), and three pre-existing packageSplit integration
    tests (§6a Phase 3 child route, §7 shell + nested child, Step 2b) had
    their own now-stale "both copies" assertions updated to match. Hand
    verified by deleting the duplicate directly in the reporter's own
    packageSplit test project and fixing its 3 redirected imports — 0/0
    analyze. Full suite still green.
- ✅ **Sentry (CI/CD screen, opt-in) — done**. A new `CiTool.sentry` "Monitoring"
  card (added directly by the user) plus a DSN `TextField` gated behind
  `CicdState.hasSentryDelivery`. The interesting design decision wasn't the
  toggle — it was two things that don't generalize from the existing
  Auth/Realtime/Storage opt-ins: (1) the DSN is a secret, so it needed to
  flow through the existing envied/`AppEnv` mechanism (a new single
  `sentryDsn` field, same shape as `supabaseUrl` but *not* varying per
  flavor, unlike `apiBaseUrl` — one Sentry project per app, not per
  environment) rather than ever being a literal in checked-in
  `bootstrap.dart`; without envied, it's left blank with a `// TODO` instead
  of embedding the typed value (mirrors Supabase's own non-envied fallback).
  (2) `SentryFlutter.init` doesn't add an init *line* the way Supabase/
  Firebase do — it takes `runApp` itself as its `appRunner` callback and
  installs its own `FlutterError.onError`/`PlatformDispatcher.onError`
  hooks, which would otherwise **stack** with NEAT's existing
  `runZonedGuarded` + `registerErrorHandler()` + `AppLogger.f` fallback —
  the same "don't stack two guards" lesson as Onboarding's redirect merging
  into Auth's `RouterNotifier` rather than attaching a second
  `refreshListenable`. Resolved by calling `registerErrorHandler()` *before*
  `SentryFlutter.init` (so Sentry chains onto AppLogger's hooks instead of
  competing with them) and wrapping only the final `runApp($root)` call in
  `SentryFlutter.init(...)`, leaving the outer `runZonedGuarded`/`AppLogger.f`
  as the last-resort catch for anything before Sentry initializes. A real
  bug caught by actually printing the generated output rather than assuming
  the string shape: the non-envied fallback's `// TODO` comment sat on the
  same line as the DSN argument's trailing comma, silently swallowing it
  into the comment and producing a syntax error — fixed by putting the TODO
  on its own line above the argument. `sentry_flutter` is injected into
  pubspec via a new `addSentry` flag (mirrors `addSlang`/`addOnboarding`'s
  "derived from a toggle, not the packages list" shape). Harness-proven: new
  unit tests for `CoreTemplates.appEnv`/`flavorEnv`/`envFile`'s `hasSentry`
  branch and `AppTemplates.bootstrap`'s wrapping (both with and without
  envied — the second one is exactly what caught the comma bug), and a new
  integration test generating a real project with Sentry enabled, asserting
  the pubspec dependency, the DSN landing in `.env` (never as a literal in
  `bootstrap.dart`), `SentryFlutter.init` wrapping `runApp`, and `flutter
  analyze` 0/0. Full suite green (245 fast tests).
  - ✅ **Follow-up: disabled in debug mode — done**. A second-opinion review
    (Gemini) suggested a Chopper/Dio interceptor that reports every `>=400`
    response to Sentry — rejected: real Sentry usage widely considers
    blanket status-code reporting an anti-pattern (a handled 401 refresh, a
    422 shown as a form error, etc. aren't bugs), it would need a separate
    implementation per HTTP client (chopper/dio; never supabase/firebase),
    and it bypasses NEAT's own `NetworkErrorHandler`/`Failure`/`UseCase
    .call()` pipeline that already normalizes and decides what's worth
    surfacing — the right hook (deferred, see Backlog) is `AppLogger.e`/`.f`
    itself, which every backend's errors already funnel through. Separately,
    local dev iteration shouldn't spam a real Sentry project or burn its
    quota — gated on `kDebugMode` (not the dev/staging/prod *flavor*, which
    would only work for named-"dev" environments and not at all for a
    single-environment project with no envied flavors configured): `options
    .dsn = kDebugMode ? '' : AppEnv.current.sentryDsn` — Sentry treats an
    empty DSN as disabled, so no extra if/else is needed around the init
    call. Harness-proven: the existing envied unit test and integration test
    updated to assert the `kDebugMode` guard; a new unit test confirms the
    non-envied branch (DSN unconditionally blank) never references
    `kDebugMode` and skips the `flutter/foundation.dart` import entirely
    (would otherwise be an unused import) — verified by actually printing
    both branches' output rather than assuming the string shape, same
    discipline that caught the comma bug above. Full suite green.

## Backlog — not yet scheduled

- **`shared_contracts`-equivalent package for arbitrary cross-feature entity
  sharing — still deferred**. Narrower than it sounds after §6a Phase 3:
  child routes (the one concrete case NEAT had UI/Workshop support for) got
  solved without a new package type (see §6a Phase 3 above — a plain one-way
  `path:` dependency covers it). What's still genuinely open: feature A's
  domain/presentation needing feature B's **entity** (or another domain type)
  directly, with no natural parent/child hierarchy to justify a one-way
  dependency either way. Real open questions: what goes in the shared
  package (just entities, or interfaces too?), when does NEAT generate one
  (proactively for every packageSplit project, or lazily on first need?),
  and how would the Workshop even surface "this feature needs that feature's
  type" as a choice? No concrete, currently-blocked use case to anchor a
  design pass on (unlike child routes) — revisit if one shows up.

- **Sentry: forward `AppLogger.e`/`.f` to `Sentry.captureException` —
  deferred**. Flagged during the Sentry feature's own design pass (see the
  entry above) as the right integration point for actually *reporting*
  errors — one hook, works across all four backends (dio/chopper/supabase/
  firebase) since they already funnel through `AppLogger`/`NetworkErrorHandler`,
  and respects the log-level distinction already baked into offline-first's
  fallback path (`.w` for an expected, recovered-from network blip vs `.f`/
  `.e` for a real uncaught error) — no separate allow-list of "reportable"
  status codes to invent. Not built yet: `AppLogger`'s own template
  (`CoreTemplates.appLogger`) doesn't currently take a `hasSentry` param, and
  doing this properly should also decide whether `.w` ever forwards (as a
  breadcrumb, not a full event) — a real design question, not just a
  one-line change. Revisit alongside (or instead of) a Chopper/Dio
  interceptor if request-level breadcrumbs are wanted later; Sentry's own
  official Dio integration is likely a better fit than a hand-rolled
  interceptor for that specific need if it comes up.

- **Sentry User Feedback (`SentryFeedbackWidget`/`Sentry.captureFeedback()`) —
  deferred, sequenced after the `AppLogger` hook above**. Considered (second
  opinion, Gemini) after shipping the base Sentry integration. Real feedback
  is always tied to a specific captured event (`associatedEventId`), so it
  can't be wired at all until the `AppLogger.e`/`.f` → `Sentry.captureException`
  hook above exists to actually produce an event id to attach to. Also a
  genuine UX-design question, not a generator-plumbing default the way the
  DSN/`kDebugMode` gate were: the pre-built `SentryFeedbackWidget` needs a
  `navigatorKey`/valid `BuildContext` to present, but NEAT's fatal-error path
  (`PlatformDispatcher.instance.onError`, the outer `runZonedGuarded` handler)
  fires exactly when the app may already be in a broken state with no
  guaranteed valid widget tree to show a modal over — auto-popping a feedback
  dialog straight out of a crash handler is the risky version of this
  feature. If revisited, lean towards a manually-triggered "Send Feedback"
  affordance (e.g. a Settings/About screen button using `Sentry.lastEventId`)
  over an automatic post-crash popup — same request, safer context.

- **Modular Monorepo (packageSplit) for manual Riverpod / Bloc-Cubit — not
  planned unless real demand shows up**. `canPackageSplit` requires
  `hasRiverpod && useRiverpodAnnotations`; the toggle stays disabled for both
  manual Notifier and Bloc/Cubit projects (Infrastructure's "Split first
  feature into its own package" description now says so explicitly instead of
  just "Riverpod annotations", which read as an oversight rather than a
  boundary). Root cause: every packageSplit cross-package wiring point
  (`<feature>_repository_providers.dart`, `<feature>_usecase_providers.dart`,
  `appDatabaseProvider`, `dioProvider`, etc.) is just a top-level
  `@Riverpod(keepAlive: true)`-annotated function — importable across
  packages with zero extra plumbing *because* that's how Riverpod's codegen
  works. Neither alternative has an equivalent:
    - **Bloc/Cubit** would need an entirely separate cross-package DI mechanism
      — most likely a service locator (`get_it`, the usual Bloc pairing) living
      *alongside* the existing Riverpod-based shared infra (`NetworkInfo`,
      Drift, the core package's providers) rather than replacing it. That's a
      second DI paradigm to design and harness, not a toggle flip.
    - **Manual Riverpod** stays the same mechanism (providers are still
      importable top-level objects), but every packageSplit template is written
      in `@riverpod` annotation syntax specifically — each one would need a
      parallel `Provider((ref) => ...)` / `NotifierProvider` hand-written
      variant, roughly doubling that template surface.
      Deliberately left unscheduled: the audience for "wants a multi-package
      monorepo" and "insists on avoiding Riverpod codegen" is presumed to barely
      overlap — teams mature enough to want packageSplit are usually already
      comfortable with codegen. Revisit only if a real project needs this
      combination.

- **FakeStore Products witness feature: README notice for removing it later**.
  The generated project's docs never tell the user that `product`/`user_profile`
  (whichever name they picked) is a *demo* feature wired against a public API,
  not part of their app — right now the only way to know is reading the code.
  Add a short "Removing the example feature" section (README, or wherever the
  other generated `docs/*.md` guides live) listing exactly what to delete: the
  feature folder itself, its chopper/route/DI registrations (the same anchor
  lines `// neat:...` marks for Workshop insertion), and its pubspec entry if
  packageSplit put it in its own package. Should reuse the anchor list the
  generator already tracks rather than re-deriving it by hand, so the notice
  can't drift out of sync with what actually got wired for a given stack.

- ✅ **State Management picker on the Infrastructure screen — logged and done
  in the same pass**. Raised while reviewing the Infrastructure screen
  (screenshot showing Backend Provider / HTTP Client as dedicated card
  pickers): now that Bloc/Cubit is real (see the entry above), the only way to
  pick it was still "search `flutter_bloc` by hand in Dependencies" — no
  discoverability, and a real footgun, since Riverpod was baked directly into
  `_corePackages` (shared by every backend preset) with no swap mechanism, so
  a user could easily end up with **both** Riverpod and Bloc packages
  selected at once.
    - Split `_corePackages` into `_sharedCore` (model codegen/routing/env —
      state-management-agnostic) + `_riverpodPreset` + the new `_blocPreset`
      (`flutter_bloc`) — `_corePackages` itself stays as `_sharedCore +
    _riverpodPreset` purely for backward compatibility (so a fresh project's
      default manifest is byte-for-byte the same as before).
    - New `StateManagementKind` enum + `presetForStateManagement`/
      `stateManagementOf`/`stateManagementMarkerPackages`, mirroring
      `HttpClientKind`'s shape exactly. New `SelectedPackages
    .applyStateManagementPreset` (strip-then-add, scoped to the marker set)
      — same mechanism as `applyBackendPreset`/`setRoutingStyle`, independent of
      both.
    - **Fixed the interaction bug this surfaced**: `applyBackendPreset` used to
      blindly re-add its preset's full `_corePackages` slice on every backend
      switch — harmless when that slice was always Riverpod (already present,
      so silently deduped), but it would have **resurrected Riverpod alongside
      an existing Bloc choice** the moment backend or HTTP client got switched
      afterward. Fixed: `applyBackendPreset` now skips any state-management
      package in the incoming preset whenever the manifest already has *some*
      state management selected, regardless of family.
    - New "State management" card row in Infrastructure's Backend tab (Riverpod
      / Bloc/Cubit), same `_BackendCard` component as Backend Provider, right
      above it.
    - Verified: web preview isn't viable for this screen (NEAT is desktop-only
      — `window_manager` has no web implementation, confirmed by actually
      trying `flutter run -d chrome`, which crashes before first frame with
      `MissingPluginException`), so this was verified via `flutter analyze` +
      new provider-level tests exercising the exact notifier calls the widget
      makes (switching to Bloc, back to Riverpod, and — the regression case —
      switching backend/HTTP client *after* choosing Bloc) rather than a
      literal click-through, consistent with how every other Infrastructure
      change this cycle was verified. Full suite green.
