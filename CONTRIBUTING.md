# Contributing to NEAT

Thanks for your interest! NEAT is a code generator, so the bar is simple but firm:
**generated code must compile cleanly.**

## The golden rule: the harness must stay green

Every change to a template or wiring step must keep the generation harness passing.

```bash
flutter test --exclude-tags integration   # fast unit tests (wiring logic, ~seconds)
flutter test --tags integration            # generates REAL projects, runs build_runner
                                           # + `flutter analyze` with a 0-error/0-warning gate
flutter analyze                            # NEAT itself must also be clean
```

If you change a template, add or update a test that proves the new output compiles
(prefer a fast unit test for the string wiring; add an integration case when a new
combination needs to be proven end-to-end).

## Architecture in one minute

- **Wizard** (`features/architecture`, `features/dependencies`, …) → configures the stack.
- **Generation** (`features/generation`) → `FeatureScaffolder` + the `templates/` write the
  project; `LaunchGenerationUsecase` orchestrates it and writes the `.neat.json` contract.
- **Workshop** (`features/feature_gen`) → `ProjectLoader` reads the contract,
  `GenerateFeatureUsecase` adds a feature to an existing project **non-destructively**,
  wiring routes/Drift at `// neat:` anchors.

State models live in `domain/models` (freezed). Domain code never imports presentation.

## Conventions

- freezed for value objects; required fields first (lint), then `@Default`s.
- Non-destructive edits to generated files use **anchors** (`// neat:route-entries`, etc.).
- Keep new capabilities **gated** (visible but disabled) until the harness proves them.

## Formatting

The whole tree is `dart format`-clean (width 80, pinned in `analysis_options.yaml`) and the CI
checks it (`dart format --output=none --set-exit-if-changed .`), like the CI of the projects NEAT
generates. `.githooks/pre-push` runs the same check before a push:

```bash
git config core.hooksPath .githooks                       # once per clone
git config blame.ignoreRevsFile .git-blame-ignore-revs    # optional: blame skips the format commit
git push --no-verify                                      # skip the hook for one push
```

Format from the terminal (`dart format .`) or set your IDE's Dart line length to 80. In Android Studio
that is Settings → Editor → Code Style → Dart (or the general hard wrap) — its own Reformat Code can
otherwise produce a different layout than `dart format` and fail the CI.

## Scope

See [ROADMAP.md](ROADMAP.md). We keep the stack opinionated (Riverpod + Bloc/Cubit only)
and prefer **depth done correctly** over breadth. New architectures multiply the harness
cost — discuss in an issue first.
