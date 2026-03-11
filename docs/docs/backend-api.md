# Backend API

The FastAPI backend runs on `http://localhost:8000` by default. Interactive API docs are available at `/docs` (Swagger UI) and `/redoc`.

## Health Check

```
GET /
```

**Response:**

```json
{ "status": "ok", "version": "0.1.0" }
```

---

## Authentication

### Login

```
POST /auth/login
```

Creates an instaloader session and returns a session token.

**Request Body:**

```json
{
  "username": "instagram_user",
  "password": "secret"
}
```

| Field | Type | Constraints |
|-------|------|-------------|
| `username` | string | min 1 char |
| `password` | string | min 1 char |

**Response (200):**

```json
{
  "session_token": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "username": "instagram_user",
  "needs_2fa": false,
  "message": "Login successful"
}
```

If `needs_2fa` is `true`, proceed with the 2FA endpoint before making other API calls.

**Errors:**

| Code | Meaning |
|------|---------|
| 401 | Invalid credentials |
| 503 | Connection error (Instagram unreachable) |

---

### Complete 2FA

```
POST /auth/login/2fa
```

Completes login with a two-factor authentication code.

**Request Body:**

```json
{
  "session_token": "a1b2c3d4-...",
  "code": "123456"
}
```

| Field | Type | Constraints |
|-------|------|-------------|
| `session_token` | string | Token from login response |
| `code` | string | Exactly 6 characters |

**Response (200):** Same as login response with `needs_2fa: false`.

**Errors:**

| Code | Meaning |
|------|---------|
| 400 | Invalid or expired session token |
| 401 | Invalid 2FA code |
| 503 | Connection error |

---

### Logout

```
POST /auth/logout
```

Invalidates the session and deletes the session file.

**Request Body:**

```json
{
  "session_token": "a1b2c3d4-..."
}
```

**Response:** `204 No Content`

---

### Check Session Status

```
GET /auth/status?session_token=a1b2c3d4-...
```

**Response (200):**

```json
{
  "valid": true,
  "username": "instagram_user",
  "expires_in_seconds": 82800
}
```

| Field | Type | Description |
|-------|------|-------------|
| `valid` | boolean | Whether the session is still usable |
| `username` | string or null | Username if valid |
| `expires_in_seconds` | integer or null | Seconds until 24h expiry |

---

## Profile & Media

All profile endpoints require the `X-Session-Token` header and are rate-limited. Rate limit info is returned in response headers.

### Response Headers

| Header | Description |
|--------|-------------|
| `X-RateLimit-Remaining` | Requests remaining in the current hour |
| `X-RateLimit-Reset` | Monotonic timestamp when the counter resets |

### Get Profile Info

```
GET /profile/{username}
```

**Response (200):**

```json
{
  "username": "example_user",
  "full_name": "Example User",
  "biography": "Hello world",
  "profile_pic_url": "https://...",
  "follower_count": 1234,
  "following_count": 567,
  "media_count": 89,
  "is_private": false,
  "is_verified": true,
  "external_url": "https://example.com"
}
```

---

### Get Posts

```
GET /profile/{username}/posts?limit=50&cursor=abc123
```

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `limit` | integer | 50 | Max items to return |
| `cursor` | string | null | Pagination cursor from previous response |

**Response (200):**

```json
{
  "items": [
    {
      "media_id": "CxYz123",
      "media_type": "image",
      "url": "https://...",
      "caption": "Photo caption",
      "like_count": 42,
      "comment_count": 5,
      "timestamp": "2024-01-15T12:00:00Z",
      "is_video": false,
      "video_url": null
    }
  ],
  "cursor": "next_page_token",
  "has_next": true,
  "total_count": 89
}
```

`media_type` is one of: `image`, `video`, `sidecar` (carousel).

---

### Get Reels

```
GET /profile/{username}/reels?limit=50&cursor=abc123
```

Same parameters and response format as posts. All items will have `is_video: true`.

---

### Get Stories

```
GET /profile/{username}/stories
```

Returns currently active stories (expire within 24 hours).

**Response (200):**

```json
[
  {
    "media_id": "story_123",
    "media_type": "video",
    "url": "https://...",
    "timestamp": "2024-01-15T10:00:00Z",
    "is_video": true,
    "video_url": "https://...",
    "expiry": "2024-01-16T10:00:00Z"
  }
]
```

---

### Get Highlights

```
GET /profile/{username}/highlights
```

**Response (200):**

```json
[
  {
    "highlight_id": "hl_abc",
    "title": "Travel",
    "cover_url": "https://...",
    "items": [
      {
        "media_id": "item_1",
        "media_type": "image",
        "url": "https://...",
        "timestamp": "2024-01-10T08:00:00Z",
        "is_video": false,
        "video_url": null,
        "expiry": null
      }
    ],
    "item_count": 15
  }
]
```

---

### Get Download URL

```
GET /media/{media_id}/download-url
```

Returns the direct CDN URL for full-resolution media.

**Response (200):**

```json
{
  "media_id": "CxYz123",
  "download_url": "https://scontent-...",
  "media_type": "image",
  "filename": "CxYz123.jpg"
}
```

---

## Error Responses

All errors follow this format:

```json
{
  "detail": "Human-readable error message",
  "error_code": "OPTIONAL_CODE"
}
```

### Common Error Codes

| HTTP Code | When | Detail |
|-----------|------|--------|
| 401 | Invalid/expired session | `"Invalid or expired session"` |
| 404 | Profile or media not found | `"Profile not found: {username}"` |
| 429 | Rate limited | `"Rate limited — retry after {n} seconds"` |
| 503 | Instagram connection error | `"Connection error — Instagram may be blocking requests"` |

The `429` response includes a `Retry-After` header with the cooldown duration in seconds.

## Pydantic Model Reference

### Auth Models

| Model | Fields |
|-------|--------|
| `LoginRequest` | `username: str`, `password: str` |
| `LoginResponse` | `session_token: str`, `username: str`, `needs_2fa: bool`, `message: str` |
| `TwoFactorRequest` | `session_token: str`, `code: str` (6 chars) |
| `LogoutRequest` | `session_token: str` |
| `SessionStatus` | `valid: bool`, `username: str?`, `expires_in_seconds: int?` |
| `ErrorResponse` | `detail: str`, `error_code: str?` |

### Profile Models

| Model | Fields |
|-------|--------|
| `ProfileInfo` | `username`, `full_name`, `biography`, `profile_pic_url`, `follower_count`, `following_count`, `media_count`, `is_private`, `is_verified`, `external_url` |
| `MediaItem` | `media_id`, `media_type`, `url`, `caption`, `like_count`, `comment_count`, `timestamp`, `is_video`, `video_url` |
| `PaginatedMedia` | `items: list[MediaItem]`, `cursor: str?`, `has_next: bool`, `total_count: int?` |
| `StoryItem` | `media_id`, `media_type`, `url`, `timestamp`, `is_video`, `video_url`, `expiry` |
| `HighlightGroup` | `highlight_id`, `title`, `cover_url`, `items: list[StoryItem]`, `item_count` |
| `DownloadUrl` | `media_id`, `download_url`, `media_type`, `filename` |
