# Rate Limiting

Rate limiting is critical for avoiding Instagram bans. The backend implements a multi-layered rate limiting strategy.

## Configuration

All values are configurable via environment variables (prefix `SBDL_`):

| Parameter | Default | Description |
|-----------|---------|-------------|
| `RATE_LIMIT_DELAY_SECONDS` | `5.0` | Minimum delay between requests per session |
| `RATE_LIMIT_MAX_PER_HOUR` | `200` | Maximum requests per hour per session |
| `RATE_LIMIT_BACKOFF_BASE` | `5.0` | Base delay for exponential backoff (seconds) |
| `RATE_LIMIT_BACKOFF_MAX` | `300.0` | Maximum backoff delay (5 minutes) |
| `RATE_LIMIT_COOLDOWN_SECONDS` | `600` | Cooldown duration on 429 (10 minutes) |
| `INSTAGRAM_REQUEST_TIMEOUT` | `30` | Timeout per Instagram request (seconds) |

## How It Works

### Per-Session Locking

Each session gets its own `asyncio.Lock`. This ensures that concurrent requests from the same session are serialized, preventing request bursts.

```
Session A: ──request──[5s delay]──request──[5s delay]──request──
Session B: ──request──[5s delay]──request──[5s delay]──request──
```

Sessions operate independently — one session's rate limit doesn't affect another.

### Minimum Delay

Every request waits at least `RATE_LIMIT_DELAY_SECONDS` (5s) since the last request for that session. This is enforced in `RateLimiter.acquire()`.

### Hourly Cap

The rate limiter tracks timestamps of all requests in a rolling 1-hour window. When the count reaches `RATE_LIMIT_MAX_PER_HOUR` (200), all further requests are blocked until older timestamps expire.

### Exponential Backoff

On connection errors (not 429s), the delay increases exponentially:

```
delay = min(BACKOFF_BASE * 2^(error_count - 1), BACKOFF_MAX)
```

| Consecutive Errors | Delay |
|-------------------|-------|
| 1 | 5s |
| 2 | 10s |
| 3 | 20s |
| 4 | 40s |
| 5 | 80s |
| 6 | 160s |
| 7+ | 300s (max) |

A successful request resets the error count to 0.

### 429 Response Pipeline

When Instagram returns a 429 (Too Many Requests), the following happens:

1. The `instagram.py` service raises `Instagram429Error`
2. The profile router catches it and calls `rate_limiter.record_429(session_id)`
3. The session enters a **cooldown** period (default 600 seconds / 10 minutes)
4. All further requests for that session raise `RateLimitedError` until cooldown expires
5. The router returns HTTP 429 with `Retry-After` header

```
Client request
    │
    ▼
RateLimiter.acquire()
    │
    ├─ In cooldown? → raise RateLimitedError → HTTP 429 + Retry-After
    │
    ├─ Hourly cap exceeded? → raise RateLimitedError → HTTP 429
    │
    └─ OK → proceed with delay
         │
         ▼
    Instagram API call (30s timeout)
         │
         ├─ Success → record_success() → reset error count
         │
         ├─ 429/timeout → record_429() → start 10min cooldown → HTTP 429
         │
         └─ Other error → record_error() → exponential backoff
```

### Request Timeout

Each instaloader call is wrapped in `asyncio.wait_for()` with a 30-second timeout. This prevents instaloader from retrying internally (which can block for 30+ minutes).

The `max_connection_attempts=1` setting on all instaloader `Instaloader()` instances ensures they don't retry on their own.

## Response Headers

Rate-limited endpoints return these headers on every response:

| Header | Value | Description |
|--------|-------|-------------|
| `X-RateLimit-Remaining` | integer | Requests remaining in current hour |
| `X-RateLimit-Reset` | float | Monotonic timestamp when the counter resets |

## Flutter-Side Handling

The Flutter app handles rate limiting at two levels:

### Download Provider

When a 429 is received during downloads:

1. Reads `Retry-After` header from the response
2. Pauses the download queue
3. Stores `rateLimitedUntil` timestamp in `QueueDownloading` state
4. Resumes automatically when cooldown expires

### Rate Limit Banner

The home screen shows a countdown banner when rate-limited:

```dart
final class RateLimitedError extends AppError {
  const RateLimitedError({
    String message = 'Rate limited — slow down',
    this.retryAfterSeconds,
  }) : super(message);

  final int? retryAfterSeconds;
}
```

The `RateLimitBanner` widget displays a countdown timer showing seconds remaining until the rate limit resets.

## Best Practices

!!! tip "Avoid Bans"
    - Don't run multiple sessions simultaneously for heavy scraping
    - Keep `RATE_LIMIT_DELAY_SECONDS` at 5s or higher
    - If you get repeated 429s, increase the cooldown period
    - Use the app during off-peak hours for large downloads
    - Don't exceed 200 requests/hour

!!! warning "Session Rotation"
    Instagram tracks activity per account. Using multiple accounts to bypass rate limits will likely result in all accounts being flagged.
