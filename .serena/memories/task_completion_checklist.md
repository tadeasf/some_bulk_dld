# Task Completion Checklist

After every task, run:

```bash
just check        # Runs ALL checks across both submodules
```

This runs:
1. `dart format --set-exit-if-changed .` (Flutter formatting)
2. `dart analyze --fatal-infos` (Flutter static analysis)
3. `flutter test` (Flutter tests)
4. `uv run ruff check .` (Python linting)
5. `uv run ruff format --check .` (Python formatting)
6. `uv run pytest` (Python tests)

**If any check fails, fix the issue before moving on. Never skip checks.**

For a full pre-commit sweep (format then check):
```bash
just pre-commit
```
