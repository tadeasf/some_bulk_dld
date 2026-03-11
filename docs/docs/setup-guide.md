# Setup Guide

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Flutter SDK | 3.x (stable) | [flutter.dev/get-started](https://flutter.dev/docs/get-started/install) |
| Dart SDK | 3.11+ | Included with Flutter |
| Python | 3.13+ | [python.org](https://www.python.org/downloads/) |
| uv | latest | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| just | latest | `cargo install just` or your package manager |
| Android SDK | API 24–35 | Via Android Studio or `sdkmanager` |
| Java JDK | 17+ | For Android builds |
| Git | 2.x | For submodule support |

## Clone the Repository

```bash
git clone --recurse-submodules https://github.com/tadeasf/some_bulk_dld.git
cd some_bulk_dld
```

If you already cloned without `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

## Backend Setup

```bash
# Install Python dependencies
just deps-backend

# Verify checks pass
just check-backend

# Start the dev server
just backend
```

The backend runs at `http://localhost:8000`. API docs at `http://localhost:8000/docs`.

!!! info "Session Directory"
    The backend creates a `sessions/` directory (gitignored) for instaloader session files. These persist across restarts.

### Environment Variables

The backend uses `pydantic-settings` with the `SBDL_` prefix. All have sensible defaults — no `.env` file required.

| Variable | Default | Description |
|----------|---------|-------------|
| `SBDL_CORS_ORIGINS` | `["http://localhost:3000", "http://localhost:8080"]` | Allowed CORS origins |
| `SBDL_SESSION_DIR` | `sessions` | Session file storage path |
| `SBDL_SESSION_EXPIRY_HOURS` | `24` | Session lifetime |
| `SBDL_RATE_LIMIT_DELAY_SECONDS` | `5.0` | Min delay between requests |
| `SBDL_RATE_LIMIT_MAX_PER_HOUR` | `200` | Hourly request cap |
| `SBDL_RATE_LIMIT_BACKOFF_BASE` | `5.0` | Backoff base (seconds) |
| `SBDL_RATE_LIMIT_BACKOFF_MAX` | `300.0` | Max backoff (5 minutes) |
| `SBDL_RATE_LIMIT_COOLDOWN_SECONDS` | `600` | Cooldown on 429 (10 minutes) |
| `SBDL_INSTAGRAM_REQUEST_TIMEOUT` | `30` | Timeout per Instagram request |

## Flutter Setup

```bash
# Install Flutter dependencies
just deps-flutter

# Run code generation (freezed, riverpod, drift, json_serializable)
just codegen

# Verify checks pass
just check-flutter

# Build debug APK
just build-debug
```

### .env Configuration

The Flutter app reads `flutter_app/.env` for the backend URL:

```env
BACKEND_URL=http://10.0.2.2:8000
```

- `10.0.2.2` is the Android emulator's alias for the host machine's `localhost`
- For a physical device on the same network, use your machine's LAN IP

### Android Emulator

```bash
# List available emulators
just emulators

# Launch one
just emu Pixel_7_API_35

# Run the app
just run
```

### Release Signing

For release builds, you need a signing key:

```bash
# Generate a keystore
keytool -genkey -v \
  -keystore ~/some-bulk-dld-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias some_bulk_dld
```

Create `flutter_app/android/key.properties` (gitignored):

```properties
storePassword=your_password
keyPassword=your_password
keyAlias=some_bulk_dld
storeFile=/home/youruser/some-bulk-dld-release.jks
```

Then build:

```bash
just build-release    # APK
just build-aab        # App Bundle (Play Store)
```

## Running Everything

=== "Two terminals"

    ```bash
    # Terminal 1: Backend
    just backend

    # Terminal 2: Flutter app
    just run
    ```

=== "Quick check"

    ```bash
    # Verify everything compiles and tests pass
    just check
    ```

## Common Issues

### `uv: command not found`

Install uv:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### `just: command not found`

Install just via your package manager or cargo:

```bash
# Fedora/RHEL
sudo dnf install just

# macOS
brew install just

# Cargo (any platform)
cargo install just
```

### Flutter `pub get` fails

Ensure you have Flutter on the stable channel:

```bash
flutter channel stable
flutter upgrade
```

### Android SDK not found

Set `ANDROID_HOME` and ensure the required SDK platforms are installed:

```bash
export ANDROID_HOME=$HOME/Android/Sdk
sdkmanager "platforms;android-35" "build-tools;35.0.0"
```

### Backend port conflict with MkDocs

Both the backend and `mkdocs serve` default to port 8000. Use a different address for docs:

```bash
cd docs && uv run mkdocs serve --dev-addr 127.0.0.1:8001
```

### instaloader login fails

- Instagram may require you to verify the login from a known device first
- Try logging in via a browser on the same machine, then retry
- If you get 2FA prompts, the app handles them — enter the code when asked
- Rate limiting kicks in after too many attempts — wait 10 minutes
