# Borderline — Land Softer.

A community platform that pairs newcomers and migrants with local helpers who've been through the same process. Newcomers get guided help with banking, housing, SIM cards, paperwork, and more. Helpers build reputation and can earn from their experience.

---

## Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Web + Mobile) |
| Backend | Django 4.2 + Django REST Framework |
| Auth | JWT via `djangorestframework-simplejwt` |
| Real-time chat | Django Channels 4 + Daphne (WebSocket) |
| Database | PostgreSQL |
| Maps | OpenStreetMap via `flutter_map` (no API key needed) |
| Media storage | Django file serving + `Pillow` |

---

## Project Structure

```
migration-helper-app/
├── backend/
│   ├── config/
│   │   ├── settings.py
│   │   ├── urls.py
│   │   └── asgi.py             # WebSocket entry point
│   ├── users/                  # Auth, profiles, reviews, help requests
│   │   ├── models.py           # User, UserImage, Review, HelpRequest
│   │   ├── serializers.py
│   │   ├── views.py
│   │   └── urls.py
│   ├── chat/                   # Real-time messaging
│   │   ├── models.py           # Conversation, Message
│   │   ├── consumers.py        # WebSocket consumer
│   │   └── routing.py
│   └── manage.py
│
└── borderline_app/
    └── lib/
        ├── data/
        │   └── world_data.dart      # 195 countries, 500+ cities, 80+ languages (offline)
        ├── models/
        │   └── helper_model.dart    # Helper, Review, HelpRequest, Specialty, ProfileImage
        ├── screens/
        │   ├── login_screen.dart
        │   ├── register_screen.dart      # 4-step onboarding flow
        │   ├── home_screen.dart          # Helper discovery + search
        │   ├── helper_detail_screen.dart # Profile, reviews, request & chat actions
        │   ├── request_help_screen.dart  # Category picker + package selection
        │   ├── rate_screen.dart          # Post-session star rating
        │   ├── edit_profile_screen.dart  # Edit profile + manage photos
        │   ├── chat_screen.dart
        │   ├── inbox_screen.dart
        │   └── profile_screen.dart
        ├── services/
        │   ├── auth_service.dart    # All REST API calls
        │   ├── api_service.dart     # Helper list
        │   ├── chat_service.dart    # Conversation management
        │   └── location_service.dart
        └── widgets/
            ├── country_city_picker.dart  # Typeahead location picker
            ├── language_selector.dart    # Multi-select chip input
            ├── map_location_picker.dart  # OSM tap-to-pin map
            └── profile_image_picker.dart # 3-slot photo upload
```

---

## Prerequisites

- Python 3.10+
- PostgreSQL running locally
- Flutter SDK 3.11+

---

## Backend Setup

```bash
cd backend

python -m venv venv
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

pip install -r requirements.txt
```

Create the database (default config expects `borderline_db` on localhost):

```sql
CREATE DATABASE borderline_db;
```

Run migrations and start the server:

```bash
python manage.py migrate
python manage.py createsuperuser   # optional — gives access to /admin
python manage.py runserver
```

Daphne (installed as part of `requirements.txt`) takes over `runserver` and serves both HTTP and WebSocket on `http://127.0.0.1:8000`.

---

## Flutter Setup

```bash
cd borderline_app
flutter pub get
flutter run -d chrome     # web
flutter run               # mobile
```

The app connects to `http://127.0.0.1:8000` by default. To change this, update `baseUrl` in [lib/services/auth_service.dart](borderline_app/lib/services/auth_service.dart) and [lib/services/api_service.dart](borderline_app/lib/services/api_service.dart).

---

## API Reference

### Auth
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/auth/register/` | Register with email, password, role, nationality, city, languages, bio |
| POST | `/api/auth/login/` | Login → JWT access + refresh tokens |
| POST | `/api/auth/refresh/` | Refresh access token |

### Current User
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/users/me/` | Get own full profile |
| PATCH | `/api/users/me/` | Update profile (bio, languages, hourly_rate, specialty_ids, …) |
| PATCH | `/api/users/me/location/` | Update GPS coordinates + tracking flag |
| GET / POST | `/api/users/me/images/` | List or upload profile images (max 3) |
| DELETE | `/api/users/me/images/<id>/` | Remove a profile image |
| PATCH | `/api/users/me/images/<id>/set-primary/` | Set as primary photo |

### Discovery
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/helpers/` | List helpers — supports `?city=` and `?search=` |
| GET | `/api/helpers/<id>/` | Helper detail |
| GET | `/api/users/nearby/` | Nearby users by GPS — params: `lat`, `lng`, `radius`, `role` |
| GET | `/api/users/<id>/` | Public profile for any user |

### Reviews
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/users/<id>/reviews/` | All reviews for a user |
| GET | `/api/users/<id>/review/` | Check whether the current user has already reviewed |
| POST | `/api/users/<id>/review/` | Submit a review (`rating`, `tags`, `note`) |

Rating average and total review count on the helper's profile are updated automatically after each submission.

### Help Requests
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/requests/` | Own requests (newcomer) or received requests (helper) |
| POST | `/api/requests/` | Create a request (`category`, `sub_topics`, `description`, `package`, optional `helper`) |
| PATCH | `/api/requests/<id>/status/` | Update status: `accepted` / `declined` / `done` / `cancelled` |

### Chat
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/conversations/` | List all conversations |
| POST | `/api/conversations/` | Get or create a conversation with a user |
| GET | `/api/conversations/<id>/messages/` | Load message history |
| WS | `ws://127.0.0.1:8000/ws/chat/<id>/` | Live WebSocket connection |

---

## Features

### Newcomers
- 4-step registration: role → background (nationality + languages + bio) → destination → photos
- Browse and search helpers by name, city, or specialty
- Submit a structured help request with category picker and package selection (2hr / half-day / first week / custom)
- Real-time chat via WebSocket
- Leave a star rating + tags + written review after a session

### Helpers
- GPS live location or manual map pin (OpenStreetMap, no API key)
- Profile with bio, specialties, languages, hourly rate, and up to 3 photos
- Receive and respond to structured help requests
- Rating and review count updated in real time

### Both
- Edit profile at any time: name, bio, nationality, location, languages, hourly rate, photos
- Typeahead autocomplete with 195 countries, 500+ cities, and 80+ languages — fully offline, no external API
- Self-chat and self-review are blocked at both backend and frontend

---

## Configuration

All settings live in [backend/config/settings.py](backend/config/settings.py):

| Setting | Default | Notes |
|---|---|---|
| `SECRET_KEY` | insecure placeholder | **Change before any deployment** |
| `DEBUG` | `True` | Set to `False` in production |
| `DATABASES` | PostgreSQL on localhost | Update `NAME`, `USER`, `PASSWORD` |
| `CORS_ALLOW_ALL_ORIGINS` | `True` | Restrict to your domain in production |
| `CHANNEL_LAYERS` | In-memory | Replace with `channels_redis` for multi-process production |
| `MEDIA_ROOT` | `backend/media/` | Where uploaded profile images are stored |

---

## Roadmap

Planned features from the wireframe spec (`idea-migrate-helper.pdf`):

- **Next** — Nationality scope preference (same nationality / open to all / language match) — the key differentiator from Couchsurfing
- **Next** — Advanced search filters (price range, min rating, verified only, language)
- **Next** — Helper dashboard (request inbox with accept/decline, reputation stats)
- **Later** — Full-screen map view with helper pins
- **Later** — Quick-match / Tinder-style swipe mode
- **Later** — Helper verification checklist + badge system (banking pro, housing wiz, …)
- **Later** — Payments (Stripe, escrow release, earnings dashboard, community pool)
- **Later** — Community city feed (needs, offers, meetups, Q&A, circles)
- **Later** — Push notifications
