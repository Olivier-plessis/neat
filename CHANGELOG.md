# Changelog

All notable changes to NEAT (the Flutter project generator).

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
