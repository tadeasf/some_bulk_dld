# Suggested Commands

## All Checks
```bash
just check              # Run all checks (flutter + backend)
just pre-commit         # Format + check everything
```

## Flutter
```bash
just check-flutter      # dart format --set-exit-if-changed, dart analyze, flutter test
just fmt-flutter        # Format Flutter code
just analyze-flutter    # Analyze Flutter code
just test-flutter       # Run Flutter tests
just deps-flutter       # flutter pub get
just codegen            # build_runner build
just codegen-watch      # build_runner watch
just build-debug        # Build debug APK
just build-release      # Build release APK (requires signing key)
just run                # Run on connected device
just clean-flutter      # flutter clean && flutter pub get
```

## Backend
```bash
just check-backend      # ruff check, ruff format --check, pytest
just fmt-backend        # Format backend code
just lint-backend       # ruff check --fix
just test-backend       # pytest -v
just backend            # Run dev server (uvicorn, port 8000)
just deps-backend       # uv sync
```

## Docs
```bash
just docs-serve         # Serve docs locally
just docs-build         # Build docs
```

## Format All
```bash
just fmt                # Format everything (flutter + backend)
```

## Git / System
```bash
git submodule update --init --recursive   # Init submodules after clone
git submodule status                      # Check submodule state
```
