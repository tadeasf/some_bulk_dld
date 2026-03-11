when trying to lookup profile using flutter client:

% uv run uvicorn src.some_bulk_dld_backend.main:app --reload --host 0.0.0.0 --port 8000                                           (main)
INFO:     Will watch for changes in these directories: ['/home/tadeasf/Documents/coding-projects/some_bulk_dld/fastapi_backend']
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [220316] using WatchFiles
INFO:     Started server process [220322]
INFO:     Waiting for application startup.
Loaded session from sessions/9693a304-5d7f-4777-9c00-eee07b84bc9a.session.
2026-03-11 04:23:51,029 some_bulk_dld_backend.services.instagram INFO Restored session 9693a304-5d7f-4777-9c00-eee07b84bc9a for user whostoletedsusername
2026-03-11 04:23:51,029 src.some_bulk_dld_backend.main INFO Restored 1 existing sessions
INFO:     Application startup complete.
^[[1;5DSaved session to sessions/947c5bdd-afd0-4c29-aa23-00741aef1f98.session.
INFO:     127.0.0.1:57046 - "POST /auth/login HTTP/1.1" 200 OK
2026-03-11 04:27:27,221 some_bulk_dld_backend.services.instagram WARNING Instagram 429 detected: JSON Query to api/v1/users/web_profile_info/?username=stuffyoushould_read: 429 Too Many Requests when accessing https://i.instagram.com/api/v1/users/web_profile_info/?username=stuffyoushould_read
2026-03-11 04:27:27,221 some_bulk_dld_backend.services.rate_limiter WARNING Session 947c5bdd-afd0-4c29-aa23-00741aef1f98 entering 600s cooldown
2026-03-11 04:27:27,221 some_bulk_dld_backend.routers.profile WARNING Instagram 429 for session 947c5bdd-afd0-4c29-aa23-00741aef1f98 — cooldown 600s
INFO:     127.0.0.1:43022 - "GET /profile/stuffyoushould_read HTTP/1.1" 429 Too Many Requests

we get this from the backend and get rate limited for 10 minutes immediately...

