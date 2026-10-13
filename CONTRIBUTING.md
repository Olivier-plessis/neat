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

Generated projects are `dart format`-clean and their CI checks it
(`dart format --output=none --set-exit-if-changed .`); their `analysis_options.yaml`
pins `formatter: page_width: 80`. NEAT's own source is **not** formatted as a whole
yet (about half of the files would change), so its CI step stays commented out.

`.githooks/pre-push` checks the Dart files a push touches, so formatting can be
adopted file by file:

```bash
git config core.hooksPath .githooks   # once per clone
git push --no-verify                  # skip it for one push
```

Run `dart format <file>` on a file before you push it. The better end state is one
dedicated "format everything" commit, then the hook and the CI step both check `.`.

## Scope

See [ROADMAP.md](ROADMAP.md). We keep the stack opinionated (Riverpod + Bloc/Cubit only)
and prefer **depth done correctly** over breadth. New architectures multiply the harness
cost — discuss in an issue first.
