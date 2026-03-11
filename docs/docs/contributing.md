# Contributing

## Mandatory Checks

Run after **every** change:

```bash
just check            # all checks (Flutter + backend)
just check-flutter    # dart format, dart analyze, flutter test
just check-backend    # ruff check, ruff format --check, pytest
```

Never commit code that fails these checks.

## Code Style

### Dart / Flutter

| Rule | Details |
|------|---------|
| Trailing commas | On ALL argument lists (enforced by `dart format`) |
| Constructors | Prefer `const` wherever possible |
| Control flow | Pattern matching (Dart 3 switch expressions) over if/else |
| File names | `snake_case` |
| Class names | `PascalCase` |
| Import order | `dart:` > `package:` > relative, separated by blank lines |
| Documentation | `///` doc comments on all public APIs |
| Variables | Prefer `final` over `var`; never use `dynamic` unless unavoidable |
| State modeling | Sealed classes for states and events |
| Error handling | `Result<T, E>` sealed class — never throw for expected failures |
| Line length | Max 80 characters |
| Logging | `package:logging` — never `print()` |

Format and analyze:

```bash
just fmt-flutter       # auto-format
just analyze-flutter   # static analysis
```

### Python (Backend)

| Rule | Details |
|------|---------|
| Formatter | `ruff format` |
| Linter | `ruff check` with E, F, I, N, UP, B, A, SIM, TCH, RUF |
| Type hints | On ALL function signatures (params + return type) |
| Docstrings | Google-style on all public functions/classes |
| Models | Pydantic v2 for request/response schemas |
| Endpoints | `async` wherever possible |
| Imports | Always at top of file — no lazy imports |
| Error handling | No `except: pass` — always handle or log |
| Control flow | `match`/`case` over `if`/`elif`/`else` for literal comparisons |
| Functions | Max 20–50 lines; split into `_helper()` functions |
| Line length | Max 120 characters |
| Layout | All code under `src/some_bulk_dld_backend/` |

Format and lint:

```bash
just fmt-backend       # auto-format
just lint-backend      # lint with auto-fix
```

## Code Generation

The Flutter app uses `build_runner` for:

- **freezed** — immutable data classes
- **riverpod_generator** — typed providers from `@Riverpod` / `@riverpod` macros
- **json_serializable** — JSON serialization
- **drift_dev** — database code

After modifying annotated classes:

```bash
just codegen           # one-time build
just codegen-watch     # watch mode (rebuilds on save)
```

Generated files (`*.g.dart`, `*.freezed.dart`) are committed to the repo.

## Project Structure

### Adding a New Feature (Flutter)

1. Create directory under `lib/features/{feature_name}/`
2. Add subdirectories: `data/`, `domain/` (if needed), `presentation/`
3. Data layer: repository + DTOs (freezed)
4. Presentation: provider (`@riverpod`), screen, widgets
5. Add route in `lib/app.dart`
6. Run `just codegen`
7. Run `just check-flutter`

### Adding a New Endpoint (Backend)

1. Add Pydantic models in `src/some_bulk_dld_backend/models/`
2. Add router function in the appropriate `routers/*.py`
3. Add tests in `tests/`
4. Run `just check-backend`

## Testing

### Flutter Tests

```bash
just test-flutter      # all tests
```

Test files go in `flutter_app/test/`. Naming convention: `{feature}_test.dart`.

Current test coverage:

- Unit tests: Result type, download queue state transitions, progress computation
- Widget tests: History screen rendering, status chips, date formatting

### Backend Tests

```bash
just test-backend      # all tests (pytest)
```

Test files go in `fastapi_backend/tests/`. Uses `httpx.AsyncClient` with `ASGITransport`.

Tests manually wire `app.state` since `ASGITransport` doesn't trigger the lifespan context manager.

Current test coverage: 12 tests across auth and profile endpoints.

## Pull Request Process

1. Create a feature branch from `master`
2. Make your changes
3. Run `just check` — all checks must pass
4. Commit with a descriptive message
5. Push and open a PR
6. CI runs automatically on the affected submodule(s)
7. Get review and merge

## Useful Commands

| Command | Description |
|---------|-------------|
| `just` | List all available recipes |
| `just check` | Run all checks |
| `just fmt` | Format all code (Flutter + backend) |
| `just pre-commit` | Format + check (full sweep) |
| `just codegen` | Run build_runner |
| `just backend` | Start backend dev server |
| `just run` | Launch Flutter app |
| `just docs-serve` | Preview docs locally |
| `just build-debug` | Build debug APK |
| `just build-release` | Build signed release APK |
