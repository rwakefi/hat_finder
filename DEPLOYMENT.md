# Deployment guide — hat_finder backend

This document explains how to deploy the Python backend to Railway and how to
run it locally. For a general project overview see [README.md](./README.md).

---

## Repository layout (monorepo)

```
hat_finder/          ← repo root (Flutter frontend)
└── backend/         ← Python backend (this is what Railway deploys)
    ├── main.py
    └── requirements.txt
```

Railway is configured to treat `backend/` as the **root directory** for the
`hat_finder` service. This means Railway only sees the contents of `backend/`
during the build — it will find `requirements.txt` there and install
dependencies automatically via Railpack.

---

## Railway setup

### 1. Create the service

1. In the Railway dashboard, click **New Project → Deploy from GitHub repo**.
2. Select `rwakefi/hat_finder`.
3. When prompted for the **Root Directory**, enter `backend`.
   - This scopes the build context to the `backend/` folder so Railpack
     correctly detects Python and installs `requirements.txt`.

### 2. Attach a Postgres database

1. In the same Railway project, click **New → Database → Add PostgreSQL**.
2. Railway automatically injects `DATABASE_URL` into every service in the
   project. No manual copy-paste is needed.

### 3. Environment variables

| Variable | Where it comes from | Notes |
|---|---|---|
| `DATABASE_URL` | Auto-injected by Railway Postgres plugin | Full connection string |
| `PORT` | Auto-injected by Railway runtime | Server binds to this port |

No other environment variables are required for a basic deployment.

### 4. Build & deploy

Railway uses the **Railpack** builder. With `backend/` as the root directory:

- Railpack detects `requirements.txt` → installs `pg8000==1.30.3` via pip.
- The start command from `railway.toml` is used: `python main.py`.
- The server listens on `$PORT` (set automatically by Railway).

The `railway.toml` at the repo root documents these settings and is picked up
by Railway when the root directory is set to `backend/` — Railway resolves
`railway.toml` relative to the configured root directory, so place a copy
inside `backend/` if you need it scoped there, or rely on the dashboard
settings.

### 5. Health check

The service exposes `/` (static file handler fallback) which Railway uses as
the health-check path. The timeout is set to 30 seconds in `railway.toml`.

---

## Local development

### Prerequisites

- Python 3.11+
- PostgreSQL running locally (or a Railway dev environment URL)

### Steps

```bash
# 1. Clone the repo
git clone https://github.com/rwakefi/hat_finder.git
cd hat_finder/backend

# 2. (Optional) create a virtual environment
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Set required environment variables
export DATABASE_URL="postgresql://postgres:password@localhost:5432/hat_finder"
export PORT=8080              # optional, defaults to 8080

# 5. Start the server
python main.py
```

The server will:
1. Connect to Postgres and create the `found_hats` table if it doesn't exist.
2. Start listening on `http://localhost:8080`.

### Verify it's running

```bash
curl http://localhost:8080/api/hats
# → [] (empty array on a fresh database)
```

---

## Database schema

The backend auto-creates the following table on startup:

```sql
CREATE TABLE IF NOT EXISTS found_hats (
    id         SERIAL PRIMARY KEY,
    name       TEXT NOT NULL,
    brand      TEXT,
    price      TEXT,
    size       TEXT,
    url        TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

No migration tool is used — the `CREATE TABLE IF NOT EXISTS` guard makes the
schema idempotent across restarts.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `❌ DATABASE_URL not set!` on startup | Env var missing | Add `DATABASE_URL` in Railway service variables |
| `❌ Failed to connect to DB` | Wrong credentials or DB not ready | Check the Postgres plugin is in the same Railway project |
| Build fails with "no start command" | `railway.toml` not found | Ensure root directory is set to `backend` in Railway dashboard |
| Railpack picks up Flutter instead of Python | Root directory not set | Set root directory to `backend` — not the repo root |
