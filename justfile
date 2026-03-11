# some_bulk_dld — monorepo task runner

default:
    @just --list

# ══════════════════════ ALL ══════════════════════

# Run all checks across both submodules
check: check-flutter check-backend

# ══════════════════════ FLUTTER ══════════════════════

# Run all Flutter checks
check-flutter:
    cd flutter_app && dart format --set-exit-if-changed .
    cd flutter_app && dart analyze --fatal-infos
    cd flutter_app && flutter test

# Format Flutter code
fmt-flutter:
    cd flutter_app && dart format .

# Analyze Flutter code
analyze-flutter:
    cd flutter_app && dart analyze --fatal-infos

# Run Flutter tests
test-flutter:
    cd flutter_app && flutter test

# Get Flutter dependencies
deps-flutter:
    cd flutter_app && flutter pub get

# Run code generation (freezed, riverpod, drift, json_serializable)
codegen:
    cd flutter_app && dart run build_runner build --delete-conflicting-outputs

# Watch code generation
codegen-watch:
    cd flutter_app && dart run build_runner watch --delete-conflicting-outputs

# Build debug APK
build-debug:
    cd flutter_app && flutter build apk --debug

# Build release APK (requires signing key)
build-release:
    cd flutter_app && flutter build apk --release

# Build release AAB (for Play Store)
build-aab:
    cd flutter_app && flutter build appbundle --release

# Run on connected device
run:
    cd flutter_app && flutter run

# List emulators
emulators:
    cd flutter_app && flutter emulators

# Launch emulator by name
emu name:
    cd flutter_app && flutter emulators --launch {{name}}

# Clean Flutter build artifacts
clean-flutter:
    cd flutter_app && flutter clean && flutter pub get

# Generate launcher icons
icons:
    cd flutter_app && dart run flutter_launcher_icons

# Generate splash screen
splash:
    cd flutter_app && dart run flutter_native_splash:create

# ══════════════════════ BACKEND ══════════════════════

# Run all backend checks
check-backend:
    cd fastapi_backend && uv run ruff check .
    cd fastapi_backend && uv run ruff format --check .
    cd fastapi_backend && uv run pytest

# Format backend code
fmt-backend:
    cd fastapi_backend && uv run ruff format .

# Lint backend code (with autofix)
lint-backend:
    cd fastapi_backend && uv run ruff check --fix .

# Run backend tests
test-backend:
    cd fastapi_backend && uv run pytest -v

# Run backend dev server
backend:
    cd fastapi_backend && uv run uvicorn src.some_bulk_dld_backend.main:app --reload --host 0.0.0.0 --port 8000

# Sync backend dependencies
deps-backend:
    cd fastapi_backend && uv sync

# ══════════════════════ DOCS ══════════════════════

# Serve docs locally
docs-serve:
    cd docs && uv run mkdocs serve

# Build docs
docs-build:
    cd docs && uv run mkdocs build

# ══════════════════════ FORMAT ALL ══════════════════════

# Format everything
fmt: fmt-flutter fmt-backend

# Full pre-commit sweep
pre-commit: fmt check
