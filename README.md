<<<<<<< HEAD
# NyayaAI 🏛️

**AI-powered Citizen Grievance Management Platform**

> *"From Complaint to Resolution — Faster, Smarter, Transparent."*

Team ID: 219 | Problem Statement: SIH1516 | Theme: Smart Automation

---

## 🎯 Overview

NyayaAI is an intelligent grievance management system that empowers citizens to submit complaints through a mobile-first app and leverages Google Gemini AI to automatically classify, prioritize, and route them to the appropriate government department. Administrators can manage complaints, update statuses, and monitor real-time analytics — all from the same app.

## ✨ Features

### Citizen Features
- **Submit Grievances** with title, description, location, and optional photo evidence
- **AI-Powered Analysis** — Gemini AI automatically classifies category, issue type, priority, and department
- **Unique Ticket ID** (GRV-YYYY-XXXX) generated for every complaint
- **Track Complaints** by ticket ID with a visual status timeline
- **Dashboard** showing recent complaints with status/priority indicators

### Admin Features
- **Dashboard Analytics** with real-time stats (total, pending, in-progress, resolved, high-priority)
- **Interactive Charts** — pie charts for status/priority distribution, bar charts for category/department breakdown
- **Complaint Management** — view full details, update status, reassign departments
- **Evidence Viewing** — view submitted photo evidence with full-screen zoom

### Technical Features
- **Graceful Degradation** — AI fallback if Gemini is unavailable, image upload fallback if Cloudinary is unavailable
- **Responsive Design** — mobile-first Material 3 UI that works on phone, tablet, and web
- **Real-time Data** — all views reflect live MongoDB data

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter 3.41+ (Dart 3.11+), Material 3, Provider, fl_chart |
| **Backend** | Python 3.13+, FastAPI, Uvicorn, Pydantic, PyMongo |
| **Database** | MongoDB (local, `mongodb://localhost:27017`) |
| **AI Engine** | Google Gemini 2.0 Flash (via `google-genai` SDK) |
| **Image Storage** | Cloudinary (backend-mediated upload) |

---

## 🏗️ Architecture

```
┌──────────────┐    HTTP/REST    ┌──────────────┐    PyMongo    ┌──────────────┐
│  Flutter App  │ ──────────────▶│  FastAPI      │ ────────────▶│  MongoDB     │
│  (Web/Mobile) │ ◀──────────────│  Backend      │ ◀────────────│  (local)     │
└──────────────┘                 └──────┬───────┘              └──────────────┘
                                        │
                                   ┌────┴────┐
                                   │         │
                              ┌────▼───┐ ┌───▼────────┐
                              │ Gemini │ │ Cloudinary  │
                              │   AI   │ │  (images)   │
                              └────────┘ └────────────┘
```

---

## 📁 Folder Structure

```
nyayaai/
├── mobile/                          # Flutter app
│   ├── lib/
│   │   ├── main.dart                # App entry point, routing
│   │   ├── screens/                 # All app screens
│   │   │   ├── landing_screen.dart
│   │   │   ├── citizen_dashboard.dart
│   │   │   ├── submit_grievance_screen.dart
│   │   │   ├── grievance_result_screen.dart
│   │   │   ├── track_complaint_screen.dart
│   │   │   ├── admin_dashboard.dart
│   │   │   ├── admin_complaint_list.dart
│   │   │   └── admin_complaint_detail.dart
│   │   ├── services/
│   │   │   └── api_client.dart      # HTTP API client
│   │   ├── state/
│   │   │   └── app_state.dart       # Simple role management
│   │   └── utils/
│   │       └── theme.dart           # App theme, colors, helpers
│   ├── pubspec.yaml
│   └── .env.example
├── backend/
│   ├── app/
│   │   ├── routes/
│   │   │   ├── grievances.py        # CRUD endpoints
│   │   │   ├── dashboard.py         # Stats & health
│   │   │   ├── upload.py            # Image upload & AI analyze
│   │   │   └── seed.py              # Demo data seeder
│   │   ├── services/
│   │   │   ├── ai_service.py        # Gemini AI classification
│   │   │   └── upload_service.py    # Cloudinary upload
│   │   ├── database/
│   │   │   └── connection.py        # MongoDB connection
│   │   ├── schemas/
│   │   │   └── models.py            # Pydantic models
│   │   └── utils/
│   │       └── helpers.py           # Ticket ID generation
│   ├── main.py                      # FastAPI entry point
│   ├── requirements.txt
│   └── .env.example
├── .gitignore
└── README.md
```

---

## 📋 Prerequisites

- **Flutter SDK** >= 3.41.0 (with Dart >= 3.11.0)
- **Python** >= 3.10
- **MongoDB** >= 6.0 (running locally)
- **Git** >= 2.x
- **Google Chrome** (for Flutter Web development)

Optional:
- **Gemini API Key** (for AI classification; falls back to defaults without it)
- **Cloudinary Account** (for image upload; submissions work without it)

---

## 🚀 Setup & Run

### 1. MongoDB

Ensure MongoDB is running locally on `mongodb://localhost:27017`:

```bash
# Check if MongoDB is running
mongosh --eval "db.runCommand({ping:1})"
```

### 2. Backend Setup

```bash
cd backend

# Install dependencies
pip install -r requirements.txt

# Create .env from example
copy .env.example .env

# Edit .env and add your API keys (optional):
# GEMINI_API_KEY=your_gemini_api_key
# CLOUDINARY_CLOUD_NAME=your_cloud_name
# CLOUDINARY_API_KEY=your_api_key
# CLOUDINARY_API_SECRET=your_api_secret

# Start the server
python -m uvicorn main:app --host 0.0.0.0 --port 8000

# Seed demo data (in another terminal)
curl -X POST http://localhost:8000/api/seed
```

The API documentation is available at: http://localhost:8000/docs

### 3. Flutter App Setup

```bash
cd mobile

# Install dependencies
flutter pub get

# Run on Chrome (web)
flutter run -d chrome

# Or run on Android emulator
# (Change API_BASE_URL to http://10.0.2.2:8000 for Android emulator)
flutter run -d emulator-5554
```

#### Connecting to the Backend

| Target | Base URL |
|--------|----------|
| Flutter Web (same machine) | `http://localhost:8000` |
| Android Emulator | `http://10.0.2.2:8000` |
| Physical Android Device (same WiFi) | `http://<your-pc-ip>:8000` |
| iOS Simulator | `http://localhost:8000` |

The default is `http://localhost:8000` in `api_client.dart`. For Android emulator, change `_defaultBaseUrl` to `http://10.0.2.2:8000`.

---

## 🌐 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/health` | Health check |
| `POST` | `/api/grievances` | Create grievance (with AI analysis) |
| `GET` | `/api/grievances` | List grievances (with filters) |
| `GET` | `/api/grievances/{ticket_id}` | Get single grievance |
| `PUT` | `/api/grievances/{ticket_id}/status` | Update status |
| `PUT` | `/api/grievances/{ticket_id}/department` | Update department |
| `GET` | `/api/dashboard/stats` | Dashboard statistics |
| `POST` | `/api/ai/analyze` | Standalone AI analysis |
| `POST` | `/api/upload/image` | Upload image to Cloudinary |
| `POST` | `/api/seed` | Seed demo data |

---

## 🎬 Demo Flow

1. Open NyayaAI app landing screen
2. Choose **"Continue as Citizen"**
3. Tap **"Submit Grievance"**
4. Enter: *"There is a large pothole near the college entrance. It is dangerous for vehicles and has caused accidents."*
5. Optionally add a photo as evidence
6. Tap **"Analyze & Submit"** — AI returns Category, Issue Type, Priority, Department
7. System generates ticket **GRV-2026-XXXX** and shows success screen
8. Go back, choose **"Continue as Admin"**
9. View the new complaint in the admin complaint list
10. Open it, advance status: **Submitted → Assigned → In Progress → Resolved**
11. Return to citizen view, track the ticket ID, confirm it shows **Resolved**
12. Open **Admin Dashboard** to see charts and statistics

---

## 📊 Data Model

```json
{
  "ticket_id": "GRV-2026-0001",
  "title": "Large pothole near college",
  "description": "There is a large pothole...",
  "category": "Road & Infrastructure",
  "issue_type": "Pothole",
  "priority": "High",
  "department": "Municipal Corporation",
  "summary": "Dangerous pothole reported",
  "status": "Submitted",
  "location": "College Main Gate",
  "image": { "url": "...", "public_id": "..." },
  "created_at": "2026-08-13T...",
  "updated_at": "2026-08-13T..."
}
```

**Status Lifecycle:** Submitted → Assigned → In Progress → Resolved

**Priorities:** Low, Medium, High, Critical

---

## 🔐 Security

- No secrets committed to source code (all via `.env`, which is `.gitignore`d)
- Cloudinary API secret only used server-side
- MongoDB bound to localhost only
- Flutter client holds no secrets — only the backend base URL
- Demo auth (role picker) — structured for easy real-auth integration later

---

## 🔮 Future Scope

- **Multimodal Image Analysis** — Gemini vision for damage assessment from photos
- **Voice Submission** — Submit complaints via voice in local languages
- **Duplicate Detection** — AI-powered identification of similar/duplicate complaints
- **Geospatial Heatmaps** — Map-based visualization of complaint hotspots
- **Predictive Analytics** — Forecast complaint volumes and resource needs
- **Push Notifications** — Real-time status updates to citizens
- **Real Authentication** — OAuth/Google login with RBAC
- **SMS/Email Alerts** — Notification on status changes
- **Multi-language Support** — Full UI and AI analysis in regional languages
- **App Store Publishing** — Production deployment to Play Store and App Store

---

## 📄 Environment Variables

### Backend (`backend/.env`)

| Variable | Description | Required |
|----------|-------------|----------|
| `MONGODB_URI` | MongoDB connection string | Yes (default: `mongodb://localhost:27017`) |
| `MONGODB_DATABASE` | Database name | Yes (default: `nyayaai`) |
| `GEMINI_API_KEY` | Google Gemini API key | No (fallback used) |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary cloud name | No (upload disabled) |
| `CLOUDINARY_API_KEY` | Cloudinary API key | No (upload disabled) |
| `CLOUDINARY_API_SECRET` | Cloudinary API secret | No (upload disabled) |

### Mobile (`mobile/.env.example`)

| Variable | Description |
|----------|-------------|
| `API_BASE_URL` | Backend URL (default: `http://localhost:8000`) |

---

*Built with ❤️ for SIH 2026*
=======
﻿# Personal Finance AI (PFAI)

A comprehensive Personal Finance Assistant powered by AI. PFAI helps you track your transactions, manage budgets, set goals, and gives you intelligent insights into your spending habits using advanced AI and vector search technologies.

## Tech Stack

### Backend
- **Framework:** FastAPI
- **Database:** SQLite (via SQLAlchemy)
- **Migrations:** Alembic
- **Task Queue:** Celery + Redis
- **Vector Database:** Qdrant
- **AI Integration:** Google Generative AI (Gemini)
- **Data Processing:** Pandas, PDFPlumber

### Frontend
- **Framework:** Flutter (Web, Android, iOS)
- **Networking:** Dio
- **Routing:** go_router
- **Charts:** fl_chart
- **State Management:** Riverpod

## Project Structure

- \ackend/\: Contains the FastAPI application, background tasks, and AI integrations.
- \rontend/\: Contains the Flutter application providing a seamless UI across multiple platforms.

## Setup & Installation

### Backend Setup
1. Navigate to the backend directory:
   \\\ash
   cd backend
   \\\
2. Create and activate a virtual environment.
3. Install dependencies:
   \\\ash
   pip install -r requirements.txt
   \\\
4. Run migrations:
   \\\ash
   alembic upgrade head
   \\\
5. Start the server (Requires Redis for Celery):
   \\\ash
   uvicorn app.main:app --reload
   \\\

### Frontend Setup
1. Navigate to the frontend directory:
   \\\ash
   cd frontend
   \\\
2. Install dependencies:
   \\\ash
   flutter pub get
   \\\
3. Run the app (e.g., on Chrome):
   \\\ash
   flutter run -d chrome
   \\\

## Features
- **Upload Statements:** Upload CSV or PDF bank statements.
- **Smart Categorization:** Automatically categorize transactions using AI.
- **Interactive Dashboards:** View spending patterns via interactive charts.
- **AI Chat Assistant:** Ask questions about your finances and get AI-powered insights.
>>>>>>> ab733829f328ee5e1df603741ae05c3dfc92b7d8
