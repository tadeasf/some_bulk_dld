# Flutter App

The Flutter app is an Android-first client for the SomeBulkDld backend. It lives in the `flutter_app/` git submodule.

## Project Structure

```
lib/
├── main.dart                           # Entry point, init notifications/prefs
├── app.dart                            # MaterialApp.router, GoRouter, auth redirect
├── core/
│   ├── api_client.dart                 # Dio provider + SessionInterceptor
│   ├── app_error.dart                  # Sealed AppError type + mapDioException()
│   ├── constants.dart                  # App-wide constants (keys, defaults, channels)
│   ├── database.dart                   # Drift DB (DownloadSessions + DownloadJobs)
│   ├── logger.dart                     # Logging setup (dart:developer)
│   ├── notifications.dart              # flutter_local_notifications init
│   ├── permissions.dart                # Storage/notification permission helpers
│   ├── result.dart                     # sealed Result<T, E> { Ok, Err }
│   └── theme.dart                      # Material 3 light/dark themes
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_dto.dart           # Freezed DTOs: LoginResponseDto, SessionStatusDto
│   │   │   └── auth_repository.dart    # login, complete2fa, logout, checkStatus
│   │   └── presentation/
│   │       ├── auth_provider.dart      # AuthNotifier (keepAlive, session restore)
│   │       ├── auth_state.dart         # Sealed: Unknown, Authenticated, NeedsTwoFactor, Unauthenticated
│   │       ├── login_screen.dart       # Login form with validation
│   │       └── two_factor_dialog.dart  # 2FA code entry dialog
│   ├── profile/
│   │   ├── data/
│   │   │   ├── profile_dto.dart        # Freezed DTOs: ProfileInfo, MediaItem, etc.
│   │   │   └── profile_repository.dart # getProfile()
│   │   └── presentation/
│   │       ├── content_toggles.dart    # ContentType enum + toggle map provider
│   │       ├── home_screen.dart        # Username lookup + ProfileCard + download button
│   │       ├── profile_card.dart       # Profile pic, stats, bio, badges
│   │       └── profile_provider.dart   # ProfileNotifier with lookup/clear
│   ├── download/
│   │   ├── data/
│   │   │   ├── download_dao.dart       # Drift DAO: create/update sessions & jobs
│   │   │   └── download_repository.dart# API calls for media lists + file download
│   │   ├── domain/
│   │   │   ├── download_task.dart      # Freezed DownloadTask + DownloadTaskStatus enum
│   │   │   └── download_queue_state.dart# Sealed: Idle, FetchingMetadata, Downloading, Completed, Failed
│   │   └── presentation/
│   │       ├── download_provider.dart  # DownloadQueueNotifier orchestrator
│   │       ├── download_screen.dart    # Progress UI with per-item list
│   │       └── download_item_tile.dart # Per-item tile with status + progress bar
│   ├── history/
│   │   ├── data/
│   │   │   └── history_dao.dart        # Drift DAO: watch sessions, cascade delete
│   │   └── presentation/
│   │       ├── history_provider.dart   # Stream provider for session list
│   │       ├── history_screen.dart     # History list with empty state
│   │       └── history_item_tile.dart  # Status chips (Done/Partial/Failed/Running/Paused)
│   └── settings/
│       ├── data/
│       │   └── settings_repository.dart# SharedPreferences wrapper
│       └── presentation/
│           ├── settings_provider.dart  # Settings state notifier
│           └── settings_screen.dart    # Settings UI with dialogs
└── shared/
    ├── models/
    └── widgets/
        ├── error_banner.dart           # Reusable error card with dismiss
        └── rate_limit_banner.dart      # Countdown timer for rate limit display
```

## Screens & Navigation

The app uses **go_router** with auth-aware redirects:

| Route | Screen | Access |
|-------|--------|--------|
| `/login` | Login form + 2FA dialog | Unauthenticated only |
| `/` | Home (profile lookup) | Authenticated only |
| `/download` | Download progress | Authenticated only |
| `/history` | Download history | Authenticated only |
| `/settings` | App settings | Authenticated only |

The `GoRouter` redirect checks `authNotifierProvider` state and uses a `ChangeNotifier` bridge to trigger re-evaluation when auth state changes.

## State Management — Riverpod

All providers use Riverpod 2.x with code generation (`@Riverpod` / `@riverpod` macros).

### Key Providers

| Provider | Type | Keep Alive | Purpose |
|----------|------|-----------|---------|
| `authNotifierProvider` | `Notifier<AuthState>` | Yes | Login/logout, session restore, 2FA |
| `dioProvider` | `Provider<Dio>` | Yes | HTTP client with session interceptor |
| `appDatabaseProvider` | `Provider<AppDatabase>` | Yes | Drift SQLite database |
| `secureStorageProvider` | `Provider<FlutterSecureStorage>` | Yes | Encrypted session token storage |
| `profileNotifierProvider` | `AsyncNotifier<ProfileInfoDto?>` | No | Profile lookup state |
| `contentTogglesProvider` | `Notifier<Map<ContentType, bool>>` | No | Content type selections |
| `downloadQueueNotifierProvider` | `Notifier<DownloadQueueState>` | No | Download orchestration |
| `historySessionsProvider` | `StreamProvider` | No | Live download history |
| `settingsNotifierProvider` | `Notifier<SettingsState>` | No | App settings |

### Code Generation

After modifying providers, DTOs, or database tables:

```bash
just codegen          # one-time build
just codegen-watch    # watch mode
```

Generated files: `*.g.dart` (Riverpod, JSON), `*.freezed.dart` (immutable classes), `*.drift.dart` (database).

## Core Patterns

### Result Type

All repository methods return `Result<T, AppError>` instead of throwing exceptions:

```dart
sealed class Result<T, E> { const Result(); }
final class Ok<T, E> extends Result<T, E> { ... }
final class Err<T, E> extends Result<T, E> { ... }
```

Usage with pattern matching:

```dart
final result = await repo.getProfile(username);
switch (result) {
  case Ok(value: final profile):
    // handle success
  case Err(error: final error):
    // handle error — exhaustive on AppError variants
}
```

### AppError Sealed Class

```dart
sealed class AppError {
  const AppError(this.message);
  final String message;
}

final class NetworkError extends AppError { ... }
final class UnauthorizedError extends AppError { ... }
final class NotFoundError extends AppError { ... }
final class RateLimitedError extends AppError { ... }  // has retryAfterSeconds
final class ServerError extends AppError { ... }
final class UnknownError extends AppError { ... }
```

`mapDioException(DioException)` maps HTTP status codes to the correct `AppError` variant.

### Auth State Machine

```dart
sealed class AuthState { ... }
final class AuthUnknown extends AuthState { ... }         // checking stored session
final class AuthAuthenticated extends AuthState { ... }   // has sessionToken + username
final class AuthNeedsTwoFactor extends AuthState { ... }  // pending 2FA
final class AuthUnauthenticated extends AuthState { ... } // not logged in
```

### Download Queue State Machine

```dart
sealed class DownloadQueueState { ... }
final class QueueIdle extends DownloadQueueState { ... }
final class QueueFetchingMetadata extends DownloadQueueState { ... }
final class QueueDownloading extends DownloadQueueState { ... }  // has tasks, progress, isPaused
final class QueueCompleted extends DownloadQueueState { ... }
final class QueueFailed extends DownloadQueueState { ... }
```

## Download System

The download flow:

1. User selects content types on home screen and taps "Download"
2. `DownloadQueueNotifier` fetches metadata (posts, reels, stories, highlights) from the API
3. Creates a `DownloadSession` in the drift database
4. For each media item: fetches CDN URL via `/media/{id}/download-url`, then downloads the file
5. Concurrent downloads controlled by a lightweight `_Semaphore` (configurable, default 3)
6. Files saved to `getExternalStorageDirectory()/SomeBulkDld/{username}/{type}/`
7. On completion, shows a local notification

### Rate Limit Handling

When the backend returns `429`, the download provider:

- Reads the `Retry-After` header
- Pauses the queue
- Shows a countdown banner on the home screen
- Resumes automatically when the cooldown expires

## Database Schema

Two tables managed by drift:

**`download_sessions`** — One row per bulk download action:

| Column | Type | Description |
|--------|------|-------------|
| `id` | integer (PK) | Auto-increment |
| `username` | text | Target Instagram user |
| `started_at` | datetime | When download started |
| `completed_at` | datetime? | When finished (null if in progress) |
| `status` | text | running, completed, partial, failed, paused |
| `total_items` | integer | Total media items |
| `completed_items` | integer | Successfully downloaded |
| `failed_items` | integer | Failed downloads |
| `total_bytes` | integer | Total downloaded bytes |
| `content_types` | text | Comma-separated types (posts, reels, etc.) |

**`download_jobs`** — One row per media file:

| Column | Type | Description |
|--------|------|-------------|
| `id` | integer (PK) | Auto-increment |
| `session_id` | integer (FK) | References download_sessions |
| `media_id` | text | Instagram media shortcode |
| `content_type` | text | posts, reels, stories, highlights |
| `media_type` | text | image, video, sidecar |
| `download_url` | text? | CDN URL |
| `filename` | text? | Suggested filename |
| `local_path` | text? | Saved file path |
| `status` | text | pending, fetchingUrl, downloading, completed, failed |
| `file_size` | integer | Downloaded bytes |
| `error_message` | text? | Error details if failed |
| `created_at` | datetime | When job was created |
