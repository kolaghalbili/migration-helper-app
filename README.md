# Borderline

A platform that connects migrants and newcomers with local volunteers ("helpers") who assist with everyday bureaucratic and practical tasks — banking, housing, SIM cards, legal documents, and language support.

## Architecture

- **Backend**: Django REST Framework + Django Channels (WebSocket support)
- **Frontend**: Flutter (targeting Flutter Web, runs in the browser)
- **Database**: PostgreSQL
- **Auth**: JWT via `djangorestframework-simplejwt`
- **Real-time chat**: Django Channels with an in-memory channel layer

## Project Structure

```
migration-helper-app/
├── backend/          # Django project
│   ├── users/        # User auth, registration, helper profiles
│   ├── chat/         # Real-time messaging via WebSockets
│   └── config/       # Django settings, routing, ASGI config
└── borderline_app/   # Flutter web app
    └── lib/
        ├── screens/  # UI screens (login, home, chat, inbox, onboarding)
        ├── services/ # API and auth service clients
        └── models/   # Data models
```

## Developer Guide

### Prerequisites

- Python 3.10+
- PostgreSQL running locally
- Flutter SDK 3.11+

### Backend Setup

```bash
cd backend

# Create and activate a virtual environment
python -m venv venv
source venv/bin/activate      # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create the database (PostgreSQL must be running)
# Default config expects: db=borderline_db, user=postgres, password=reza123321, port=5432
# Create the database manually or adjust config/settings.py before running migrations

createdb borderline_db        # or use pgAdmin

# Run migrations
python manage.py migrate

# Start the server
python manage.py runserver
```

The API will be available at `http://127.0.0.1:8000/api/`.

### Frontend Setup

```bash
cd borderline_app

# Install Flutter dependencies
flutter pub get

# Run in Chrome (web only — the app uses dart:html)
flutter run -d chrome
```

The app connects to `http://127.0.0.1:8000/api` by default. Make sure the backend is running before launching the frontend.

### Environment / Config

Database credentials and the Django secret key are currently hardcoded in [backend/config/settings.py](backend/config/settings.py). For local development this is fine; replace them with environment variables before deploying.
