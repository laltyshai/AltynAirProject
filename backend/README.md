# Airline Booking & Operations System - Backend

FastAPI-based backend for an airline booking and operations management system with SQLite database.

## Features

- ✅ **JWT Authentication** - Secure token-based authentication
- ✅ **Role-Based Access Control** - Passenger and Staff roles
- ✅ **Flight Management** - Search, view, and manage flights
- ✅ **Booking System** - Create bookings with seat selection
- ✅ **Seat Hold Mechanism** - 10-minute hold on selected seats
- ✅ **Mock Payments** - CARD, APPLE_PAY, GOOGLE_PAY support
- ✅ **Check-In System** - 24-48 hour check-in window
- ✅ **Announcements** - Automated triggers on flight status change
- ✅ **Admin Features** - Create flights, manage bookings, aircraft, and override seats
- ✅ **Staff Dashboard** - Full operational control via API and Mobile UI

## Technology Stack

- **Python**: 3.10+
- **Framework**: FastAPI
- **Database**: SQLite
- **ORM**: SQLAlchemy
- **Authentication**: JWT (python-jose)
- **API Documentation**: OpenAPI/Swagger (auto-generated)

## Project Structure

```
Fastapi/
├── main.py                     # FastAPI application & API endpoints
├── services.py                 # Business logic layer
├── models.py                   # Domain models (dataclasses)
├── db_models.py                # SQLAlchemy database models
├── schemas.py                  # Pydantic request/response schemas
├── repositories.py             # Repository interface
├── sqlite_repositories.py      # SQLite repository implementations
├── database.py                 # Database configuration
├── security.py                 # Password hashing utilities
├── seed.py                     # Database seeding script
└── airline.db                  # SQLite database file
```

## Setup Instructions

### Prerequisites

- Python 3.10 or higher
- pip (Python package installer)

### Installation

1. **Clone or navigate to the project directory**:
   ```bash
   cd Fastapi
   ```

2. **Install dependencies**:
   ```bash
   pip install fastapi uvicorn sqlalchemy python-jose[cryptography] passlib[bcrypt] python-multipart
   ```

3. **Initialize the database** (creates tables and seed data):
   ```bash
   python seed.py
   ```

   This will create:
   - 8 airports (IST, JFK, LHR, CDG, DXB, AMS, ALA, TSE)
   - 2 aircraft models (Boeing 737-800, Airbus A320)
   - ~14 flights over the next 7 days
   - Admin and passenger test users

## Running the Backend

### Development Mode (with auto-reload):
```bash
python main.py
```

### Development Mode (Recommended for testing with devices):
```bash
python -m uvicorn main:app --reload --host 0.0.0.0
```

OR (Localhost only)

```bash
uvicorn main:app --reload
```

- **`--host 0.0.0.0`**: This makes the server accessible to other devices on your network (like your phone or an emulator running on a different virtual network).
- **Localhost Access**: http://localhost:8000
- **Network Access**: http://YOUR_PC_IP:8000 (Check using `ipconfig` or `ifconfig`)

### API Documentation

Once running, access the interactive API documentation at:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Admin Credentials

**Staff Account**:
- Email: `admin@aits.com`
- Password: `admin123`

**Test Passenger**:
- Email: `user@example.com`
- Password: `user123`

**Test Passenger**:
- Email: `goldenmoonalt.com`
- Password: `21062007`

## API Endpoints Overview

### Authentication
```
POST   /auth/register           # Register new passenger
POST   /auth/login              # Login (returns JWT token)
```

### Passenger Profile
```
POST   /profile                # Create/update profile
GET    /profile                # Get current user's profile
```

### Airports & Flights
```
GET    /airports               # List all airports
POST   /flights/search         # Search flights
GET    /flights/{id}           # Get flight details
GET    /flights/{id}/seats     # Get seat map
```

### Bookings
```
POST   /bookings               # Create booking
GET    /bookings               # Get user's bookings
GET    /bookings/{pnr}         # Get booking by PNR
```

### Payments
```
POST   /payments               # Process payment
```

### Check-In
```
POST   /check-in/{ticket_id}   # Check in for flight
```

### Announcements
```
GET    /announcements/{flight_id}  # Get flight announcements
```

### Admin Endpoints (Staff only)
```
POST   /admin/airplanes            # Create airplane
POST   /admin/flights              # Create flight
PATCH  /admin/flights/{id}         # Update flight
POST   /admin/announcements        # Create announcement
POST   /admin/bookings/{id}/cancel # Cancel booking
GET    /admin/bookings/flight/{id} # Get bookings by flight
POST   /admin/bookings/reassign-seat # Reassign seat
```

## Database Choice

**SQLite** is used for this project because:
- ✅ No separate database server required
- ✅ Easy setup and portability
- ✅ Perfect for development and exam submissions
- ✅ File-based storage (`airline.db`)

The system uses SQLAlchemy ORM, making it easy to switch to PostgreSQL or MySQL if needed.

## Data Models

### Core Entities
- **User** - Authentication and role management
- **PassengerProfile** - Passenger details (required before booking)
- **Airport** - Airport information
- **Airplane** - Aircraft with seat templates
- **Flight** - Flight schedules and seat maps
- **Booking** - Booking with PNR code
- **Ticket** - Individual passenger tickets
- **Payment** - Payment records
- **CheckIn** - Check-in and boarding passes
- **Announcement** - Flight announcements

## Business Rules

### Profile Completion
- Passengers must complete their profile before booking
- Profile includes: name, phone, passport, nationality, date of birth

### Seat Hold
- Selected seats are held for 10 minutes
- Automatically released if payment not completed
- Race condition prevention implemented

### Check-In Window
- Allowed from 24 hours to 1 hour before departure
- Only confirmed bookings can check in
- Generates boarding pass with QR code

### Booking Status Flow
```
CREATED → (payment) → CONFIRMED → (check-in) → Ready to Board
         ↓
      CANCELLED
```

### Payment Idempotency
- Multiple payment requests for the same booking return the existing payment
- Prevents double-charging

## Testing the API

### Using Swagger UI (Recommended):
1. Go to http://localhost:8000/docs
2. Click "Authorize" and login to get a token
3. Try different endpoints interactively

### Using curl:

**Register**:
```bash
curl -X POST "http://localhost:8000/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

**Login**:
```bash
curl -X POST "http://localhost:8000/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=test@example.com&password=test123"
```

**Search Flights** (with token):
```bash
curl -X POST "http://localhost:8000/flights/search" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"origin":"IST","destination":"LHR","departure_date":"2026-01-05"}'
```

## Troubleshooting

### Database Issues
If you encounter database errors:
```bash
# Delete the database and reseed
del airline.db
python seed.py
```

### Port Already in Use
If port 8000 is busy:
```bash
uvicorn main:app --reload --port 8001
```

### Import Errors
Make sure all dependencies are installed:
```bash
pip install -r requirements.txt
```

## Architecture Notes

### Clean Architecture Layers:
1. **API Layer** (`main.py`) - HTTP endpoints, auth, validation
2. **Service Layer** (`services.py`) - Business logic
3. **Repository Layer** (`sqlite_repositories.py`) - Data access
4. **Domain Layer** (`models.py`) - Core business entities

### Dependency Injection:
- Repositories injected via FastAPI's Depends()
- Database sessions managed per request
- Clean separation of concerns

## Next Steps

To deploy this backend:
1. Change `SECRET_KEY` in `main.py` to a secure random value
2. Configure environment variables for production
3. Use PostgreSQL for production database
4. Deploy to cloud (Heroku, AWS, Google Cloud, etc.)
5. Set up HTTPS/TLS certificates

## Contact & Support

For issues with this exam project, check the Swagger docs at `/docs` for detailed API information.

---

**Last Updated**: January 2026  
**Version**: 1.0.0
