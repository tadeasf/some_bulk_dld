# Code Style & Conventions

## Dart/Flutter
- Trailing commas on ALL argument lists
- Prefer const constructors wherever possible
- Pattern matching (Dart 3 switch expressions) over if/else chains
- File names: snake_case. Classes: PascalCase
- Import order: dart → package → relative, separated by blank lines
- All public APIs must have /// doc comments
- Prefer final over var. Never use dynamic unless unavoidable
- Sealed classes for state/event modeling
- Extension types for newtypes / type-safe wrappers
- Records for returning multiple values
- Error handling: Result<T, E> sealed class pattern. Never throw for expected failures
- Max line length: 80 chars
- No print() — use package:logging

## Python (Backend)
- Format: `uv run ruff format .`
- Lint: `uv run ruff check --fix .`
- Type hints on ALL function signatures (params + return)
- Google-style docstrings on all public functions/classes
- Pydantic v2 models for request/response schemas
- Async endpoints in FastAPI wherever possible
- Imports always at top of file — no lazy imports
- No `except: pass` — always handle or log
- Pattern matching (match/case) over if/elif/else for literal comparisons
- Function decomposition: max 20–50 lines, split into _helper() functions
- Single responsibility, return values over modifying globals
- src/ layout: all code under `src/some_bulk_dld_backend/`
