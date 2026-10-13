# Changelog

All notable changes to NEAT (the Flutter project generator).

## 1.1.0 — Offline sync that works end to end

Everything found by building a real app with NEAT (**archy**: Riverpod + Supabase + Drift
offline-first sync, `packageSplit`). Each fix was first made and verified in that project, then
ported here with tests; the details are in ROADMAP §5r–§5ac.

### Upgrading a project generated with 1.0.x

Your project keeps working and `.neat.json` is unchanged. One thing to know: the Workshop now
generates sync code for the 1.1 engine, so **adding an Offline + Sync feature to a project generated
before 1.1 does not compile until that project has the new engine**. Copy these from a freshly
generated project (or port them by hand, as archy did):

- `core/sync/sync_service.dart` — new required `resource`, `dependsOn`, serialised flushes;
- the Outbox DAO — `resetRetries`, `discardWrites`;
- `AppDatabase.clearAll()` — used by sign-out.

Generated projects also require **Flutter ≥ 3.47 / Dart ≥ 3.13** (see "Toolchain").

### Offline-first sync (§5w, §5aa, §5ac)

- **Writes made offline now reach the server.** The sync engine used to be wired but never started:
  it ran only when connectivity *changed*, replayed every feature's entries with the wrong handler,
  swallowed errors and parked a write for good after five failures. It now starts with the list
  provider, flushes at start-up, on every queued write and when back online, is scoped to its own
  resource, logs failures, and gives parked writes a fresh start at the next launch.
- **Drift is the source of truth for lists** (`watchAll()`; the list is a stream with a
  pull-to-refresh), so a write still in the Outbox is never hidden by a remote result. Supabase
  creates are replayed as `upsert`; chopper replays no longer drop 4xx/5xx responses; sign-out wipes
  the local database.
- **A child waits for its parent.** A `<parent>_id` field makes the Workshop write
  `SyncService(dependsOn: …)`, so a task never reaches the server before its worksite
  (foreign-key violation when both were queued offline).
- **Deleting a parent on the device cleans up its children.** The parent's `deleteById` runs in a
  transaction with a `// neat:on-delete-children` anchor where the Workshop inserts the deletion of the
  child's rows and `OutboxDao.discardWrites(…)` for its queued writes. An optional reference is
  reported, not guessed.
- The generated project ships executable tests for all of it (SyncService contract, repository,
  `discardWrites`), run by its own `flutter test`.

### Supabase (§5r, §5x, §5ab)

- **`supabase/migrations/<timestamp>_create_<table>.sql` is generated**: the table, an `updated_at`
  trigger, row level security (owner-scoped by default), explicit grants, and `CHECK`s for enum
  fields. `owner_id`, `created_at` and `updated_at` stay out of the Dart model.
- The Workshop asks for the **table name** (the Outbox resource follows it) and whether rows are
  **owned by the signed-in user**.
- **A `<parent>_id` field is a real foreign key**: a `uuid` column with `references … on delete
  cascade` (`set null` when optional) and an index, read from the parent's own generated files.
- Email confirmation and reset links open the app instead of a browser (redirect passed to Supabase,
  URL scheme registered in the Android manifest and `Info.plist`). The redirect URL still has to be added
  once in the Supabase dashboard — `docs/SUPABASE.md` says where.
- Sign-up tells "confirm your email" from "signed in" (`SignUpOutcome`) and can resend the
  confirmation.

### Entities and the Workshop (§5v, §5y, §5z)

- **`enum` field type**: a domain enum carrying its database text (`fromValue` with a safe
  fallback), `String` in the DTO and the Drift row, mappers both ways, a SQL `CHECK`.
- **Client-side ids**: `<Entity>.create(…)` with a uuid v4, so a row can be created offline.
- A feature added through the Workshop follows the **project's** dependency versions and SDK (it used
  to take NEAT's current ones and break version solving on older projects), uses the extracted UI
  package, and honours the i18n choice.
- The Workshop preview shows what is really generated (`packages/<name>`, the Drift table, the
  migration); the Riverpod observer logs provider names only, never state (a password form's state
  used to leak into the console).

### Generated projects pass their own CI (§5s, formatting)

- `flutter analyze` (infos are fatal), `dart format` and `flutter test` pass on a fresh
  `packageSplit` + Supabase/Firebase project: the backend client and `flutter_hooks` are declared
  where they are imported, and `flutter test` has a real test to run.
- `analysis_options.yaml` pins `formatter: page_width: 80`, so the CLI, the CI and every IDE agree;
  the generated GitHub workflow uses `actions/checkout@v5` (Node 24).
- `AGENTS.md` documents the sync contract and the enum, client-id and foreign-key conventions.

### Toolchain (§5u)

- Generated projects target **Flutter 3.47 / Dart 3.13** (`.fvmrc` defaults to 3.47.2): freezed 4,
  analyzer 14 (build_runner, riverpod_generator, json_serializable, go_router_builder…), drift 2.35,
  hooks_riverpod 3.4, go_router 17.

### NEAT itself

- The whole source tree is `dart format`-clean; the CI checks it and `.githooks/pre-push` runs the
  same check (see CONTRIBUTING.md). CI actions moved to Node 24 (`checkout@v5`, `cache@v5`).
- 460 unit/contract tests plus the full generation harness (every scenario generates a real project
  and runs `flutter analyze`).

## 1.0.0 — Generator frozen baseline

First stable, frozen baseline of the generation engine. Every exposed option is
covered by the generation test harness (real project generated → `flutter
analyze`, **0 error / 0 warning** gate): 38 unit/contract tests + 5 end-to-end
integration tests.

### Generated project capabilities

- **Clean Architecture** scaffold (feature-first), camelCase-correct identifiers.
- **State management**: Riverpod with code generation (`@riverpod`).
- **Routing**: go_router and go_router_builder (typed routes + aggregator).
- **Environments**: envied with 3 flavors (dev/staging/prod) + a single
  `main.dart` delegating to `bootstrap()`.
- **Bootstrap**: `runZonedGuarded` + global error handler routed to `AppLogger`.
- **Theming**: a live-preview theme engine — Custom M3 **and** FlexColorScheme —
  with responsive sizing via flutter_screenutil (`.sp` fonts, `.w`/`.h` gaps &
  paddings).
- **Design-system components** (opt-in): AppButton / AppCard / AppTextField, with
  an interactive **Widgetbook** catalog.
- **Full CRUD** witness feature (getAll / getById / create / update / delete) on
  a typed **Drift** table.
- **Offline-first** (3 strategies): Remote Only · Offline-First (local-first reads
  + cache fallback) · Offline + Sync (Outbox queue + `SyncService` replay with a
  retry cap).
- **Networking & observability**: configured Dio/Chopper provider, logging
  interceptors (Bearer redacted), `AppLogger`, Riverpod `ProviderObserver`.
- **Ready-to-use DI graph** per feature (source → repository → usecases → sync).
- **Opt-in `<app>_ui` workspace package** (theme + tokens + components) with the
  app and a standalone `<app>_widgetbook` member depending on it — native Dart
  workspaces.
- **CI/CD** config generation (GitHub Actions, GitLab CI, Codemagic, Fastlane,
  Shorebird) and a generated `docs/OFFLINE.md` usage guide.

### Disabled (visible but not selectable — not yet validated)

- Layer-First structural pattern.
- Manual Riverpod (`NotifierProvider`) — locked to the generator path.
- retrofit, and the BLoC/Cubit family.

### Known follow-ups (out of the frozen scope)

- Validate & re-enable the gated paths (manual Riverpod, retrofit, BLoC/Cubit,
  Layer-First).
- FlexColorScheme with pasted Playground code (default config is covered).
- Outbox: exponential backoff & conflict resolution.
