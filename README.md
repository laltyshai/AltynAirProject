# AltynAirProject
# Altyn Air - Airline Booking & Operations System
my AITS entrance exam projects about Airlanes
https://youtube.com/shorts/N_eJijP9OiQ?si=5nhlo0iFeaDPulj-
here is the link to my videoTutorial on how to use this app.



A comprehensive mini airline platform featuring a **FastAPI backend** and a **Flutter mobile application**. This project mimics real-world airline systems like Turkish Airlines.

---

## 📺 Demonstration Video
**[Click here to watch the 3-minute project demo](YOUR_VIDEO_URL_HERE)**

---

## 🚀 Submission Components

### 1. Mobile Application (Flutter)
- **Folder**: `/app`
- **Key Features**: 
  - Multi-passenger booking & seat selection.
  - Interactive seat map with seat categories.
  - QR-coded boarding passes after check-in.
  - Notification system for real-time flight updates.
  - Role-based login (Passenger & Staff).

### 2. Backend API (FastAPI)
- **Folder**: `/backend`
- **Database**: SQLite (`airline.db`) included with pre-seeded data.
- **Key Features**:
  - JWT Authentication & RBAC.
  - Automated flight status transitions & announcement triggers.
  - 10-minute automated seat hold logic.
  - Idempotent payment processing.
  - Full OpenAPI/Swagger documentation at `/docs`.

---

## 🛠 Quick Start Guide

### Step 1: Run the Backend
1. Go to the backend directory: `cd backend`
2. Install dependencies: `pip install -r requirements.txt` (or manually install `fastapi`, `uvicorn`, `sqlalchemy`)
3. Run the server: `python main.py` or `uvicorn main:app --reload`
4. Verify: Open [http://localhost:8000/docs](http://localhost:8000/docs)

### Step 2: Configure & Run the App
1. Go to the app directory: `cd app`
2. Configure API connection in `lib/core/config/app_config.dart` (ensure IP matches your machine if using physical device).
3. Run: `flutter pub get` then `flutter run`

---

## 🔐 Credentials (Pre-seeded)

### Staff / Admin
- **Email**: `admin@aits.com`
- **Password**: `admin123`

### Test Passenger
- **Email**: `user@example.com`
- **Password**: `user123`

---

## 📂 Repository Structure
- `/app`: Source code for the Flutter mobile application.
- `/backend`: Source code for the FastAPI server and database.
- `README.md`: This overview file.

