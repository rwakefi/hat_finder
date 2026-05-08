# hat_finder

A Flutter + Python monorepo for finding and saving western hats.

## Repository structure

```
hat_finder/
├── backend/               # Python HTTP backend (Railway service)
│   ├── main.py            #   Entry point — HTTP server on $PORT
│   └── requirements.txt   #   Python dependencies (pg8000)
├── android/               # Flutter Android target
├── ios/                   # Flutter iOS target
├── assets/                # Shared image assets
├── pubspec.yaml           # Flutter package manifest
└── railway.toml           # Railway build/deploy config (backend)
```

The **Flutter frontend** lives at the repo root and targets Android and iOS.  
The **Python backend** lives in `backend/` and is deployed to Railway as a standalone service.

---

## Flutter frontend

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.5.0
- Dart SDK ≥ 3.5.0

### Run locally

```bash
flutter pub get
flutter run          # pick a connected device or emulator
```

### Dependencies

| Package | Purpose |
|---|---|
| `http` | REST calls to the Python backend |
| `url_launcher` | Open hat URLs in the browser |
| `google_fonts` | Custom typography |
| `cupertino_icons` | iOS-style icon set |

---

## Python backend

See [DEPLOYMENT.md](./DEPLOYMENT.md) for full Railway deployment instructions.

### Prerequisites

- Python 3.11+
- A PostgreSQL database (Railway Postgres plugin or any Postgres instance)

### Run locally

```bash
cd backend
pip install -r requirements.txt
DATABASE_URL="postgresql://user:pass@localhost:5432/hat_finder" python main.py
```

The server starts on port `8080` by default. Override with the `PORT` environment variable.

### API endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/hats` | Return all saved hats (JSON array) |
| `POST` | `/api/save_hat` | Save a new hat record |

#### `POST /api/save_hat` payload

```json
{
  "name":  "Gus",
  "brand": "Stetson",
  "price": "$350",
  "size":  "7 1/4",
  "url":   "https://example.com/hat"
}
```

### Environment variables

| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | ✅ | Full Postgres connection string |
| `PORT` | ❌ | HTTP listen port (default: `8080`) |

### Dependencies (`backend/requirements.txt`)

| Package | Version | Purpose |
|---|---|---|
| `pg8000` | 1.30.3 | Pure-Python PostgreSQL driver |

---

## Getting started with Flutter

A few resources if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)
- [Online documentation](https://docs.flutter.dev/) — tutorials, samples, and API reference
