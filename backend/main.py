# from fastapi import FastAPI
# from sqlalchemy import *
# app = FastAPI()

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from repositories import Repositories

from database import engine, get_db
from db_models import Base


from datetime import datetime, timedelta
from typing import List

from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from jose import jwt, JWTError

from schemas import (
    UserRegisterRequest,
    UserLoginRequest,
    TokenResponse,
    PassengerProfileCreate,
    PassengerProfileResponse,
    AirportResponse,
    FlightSearchRequest,
    FlightResponse,
    FlightDetailsResponse,
    BookingCreateRequest,
    BookingResponse,
    PaymentRequest,
    PaymentResponse,
    CheckInResponse,
    AnnouncementResponse,
    AirplaneCreateRequest,
    FlightCreateRequest,
    AnnouncementCreateRequest,
    AnnouncementCreateRequest,
    SeatReassignRequest,
    UserResponse,
)

from models import (
    Airplane,
    SeatTemplate,
    Flight,
    UserRole,
    Airport,
    FlightStatus,
    SeatState,
    generate_id
)


from services import (
    AuthService,
    PassengerProfileService,
    FlightService,
    BookingService,
    PaymentService,
    CheckInService,
    AnnouncementService,
    StaffService,
    AirportService
)

# Create all tables

Base.metadata.create_all(bind=engine)
def get_repos(db = Depends(get_db)):
    return Repositories(db)



# =========================
# APP & REPOS
# =========================

app = FastAPI(title="Airline Booking & Operations System")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)


@app.get("/")
def hello():
    return {"message": "Hello, World!"}



# =========================
# JWT CONFIG
# =========================

SECRET_KEY = "CHANGE_ME"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def get_current_user(token: str = Depends(oauth2_scheme), repos: Repositories = Depends(get_repos)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail="Invalid token")
        user = repos.users.get(user_id)
        if not user:
            raise HTTPException(status_code=401, detail="User not found")
        return user
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")


def require_staff(user=Depends(get_current_user)):
    if user.role != UserRole.STAFF:
        raise HTTPException(status_code=403, detail="Staff only")
    return user

# =========================
# ERROR HANDLERS
# =========================
from fastapi import Request
from fastapi.responses import JSONResponse
from services import ServiceError, ValidationError, NotFound, Conflict, PermissionDenied

@app.exception_handler(ServiceError)
async def service_error_handler(request: Request, exc: ServiceError):
    status_code = 400
    if isinstance(exc, NotFound):
        status_code = 404
    elif isinstance(exc, Conflict):
        status_code = 409
    elif isinstance(exc, PermissionDenied):
        status_code = 403
    elif isinstance(exc, ValidationError):
        status_code = 400
        
    return JSONResponse(
        status_code=status_code,
        content={"detail": str(exc)},
    )

# =========================
# AUTH
# =========================

@app.post("/auth/register")
def register(data: UserRegisterRequest, repos: Repositories = Depends(get_repos)):
    print(f"DEBUG: Registration request for {data.email}")
    service = AuthService(repos)
    service.register_passenger(data.email, data.password)
    return {"status": "registered"}


@app.post("/auth/login", response_model=TokenResponse)
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    repos: Repositories = Depends(get_repos)
):
    service = AuthService(repos)
    # form_data.username will contain the email
    user = service.authenticate_user(form_data.username, form_data.password)
    token = create_access_token({"sub": user.id, "role": user.role})
    return TokenResponse(access_token=token)


@app.get("/auth/me", response_model=UserResponse)
def read_users_me(user=Depends(get_current_user)):
    return user


# =========================
# PASSENGER PROFILE
# =========================


@app.post("/profile")
def create_profile(
    data: PassengerProfileCreate,
    user=Depends(get_current_user),
    repos: Repositories = Depends(get_repos),
):
    service = PassengerProfileService(repos)
    service.create_or_update(user, data)
    return {"status": "profile updated"}


@app.get("/profile", response_model=PassengerProfileResponse)
def get_profile(
    user=Depends(get_current_user),
    repos: Repositories = Depends(get_repos),
):
    service = PassengerProfileService(repos)
    profile = service.get_profile(user)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    return profile


# =========================
# AIRPORTS & FLIGHTS
# =========================

@app.get("/airports")
def list_airports(
    repos: Repositories = Depends(get_repos)
):
    service = AirportService(repos)
    return service.list_airports()



@app.post("/flights/search", response_model=List[FlightResponse])
def search_flights(data: FlightSearchRequest, repos: Repositories = Depends(get_repos)):
    print(f"DEBUG: Searching flights: {data.origin} -> {data.destination} on {data.departure_date}")
    flight_service = FlightService(repos)
    results = flight_service.search_flights(
        data.origin, data.destination, data.departure_date
    )
    print(f"DEBUG: Found {len(results)} results")
    return results


@app.get("/flights/{flight_id}", response_model=FlightDetailsResponse)
def flight_details(flight_id: str, repos: Repositories = Depends(get_repos)):
    flight_service = FlightService(repos)
    return flight_service.get_flight_details(flight_id)


@app.get("/flights/{flight_id}/seats")
def get_flight_seats(flight_id: str, repos: Repositories = Depends(get_repos)):
    """Get seat map for a flight"""
    print(f"DEBUG: Fetching seats for flight {flight_id}")
    booking_service = BookingService(repos)
    booking_service.cleanup_expired_holds()
    
    flight_service = FlightService(repos)
    flight = flight_service.get_flight(flight_id)
    
    seats = []
    for seat_number, seat in flight.seat_map.seats.items():
        seats.append({
            "seat_number": seat_number,
            "category": seat.category,
            "is_available": seat.state == SeatState.AVAILABLE,
        })
    
    print(f"DEBUG: Found {len(seats)} seats for flight {flight_id}")
    return {
        "flight_id": flight_id,
        "seats": seats,
        "layout": flight.seat_layout,
    }

# =========================
# BOOKINGS
# =========================

@app.post("/bookings", response_model=BookingResponse)
def create_booking(
    data: BookingCreateRequest,
    user=Depends(get_current_user), repos: Repositories = Depends(get_repos)
):
    print(f"DEBUG: Creating booking for flight {data.flight_id}, user {user.id}")
    try:
        booking_service = BookingService(repos)
        booking_service.cleanup_expired_holds()
        booking = booking_service.create_booking(
            user=user,
            flight_id=data.flight_id,
            passengers=data.passengers,
            seat_numbers=data.seat_numbers,
        )
        print(f"DEBUG: Booking created successfully: {booking.pnr}")
        return booking
    except Exception as e:
        print(f"DEBUG: Error creating booking: {e}")
        import traceback
        traceback.print_exc()
        raise e


@app.get("/bookings", response_model=List[BookingResponse])
def my_bookings(user=Depends(get_current_user), repos: Repositories = Depends(get_repos)
):
    booking_service = BookingService(repos)
    return booking_service.get_user_bookings(user.id)


@app.get("/bookings/{pnr}", response_model=BookingResponse)
def booking_details(pnr: str, user=Depends(get_current_user), repos: Repositories = Depends(get_repos)
):
    booking_service = BookingService(repos)
    return booking_service.get_booking_details(pnr, user)

# =========================
# PAYMENTS
# =========================

# @app.post("/payments", response_model=PaymentResponse)
# def pay(data: PaymentRequest, repos: Repositories = Depends(get_repos)
# ):
#     payment_service = PaymentService(repos)
#     return payment_service.process_payment(
#         booking_id=data.booking_id,
#         method=data.method,
#     )
@app.post("/payments", response_model=PaymentResponse)
def pay(
    data: PaymentRequest,
    user=Depends(get_current_user),              # ← ОБЯЗАТЕЛЬНО
    repos: Repositories = Depends(get_repos),
):
    print(f"DEBUG: Processing payment for booking {data.booking_id}, user {user.id}")
    try:
        payment_service = PaymentService(repos)
        payment = payment_service.process_payment(
            user=user,                               # ← передаём user
            booking_id=data.booking_id,
            method=data.method,
        )
        print(f"DEBUG: Payment processed successfully for booking {data.booking_id}")
        return payment
    except Exception as e:
        print(f"DEBUG: Error processing payment: {e}")
        import traceback
        traceback.print_exc()
        raise e


# =========================
# CHECK-IN
# =========================

@app.post("/check-in/{ticket_id}", response_model=CheckInResponse)
def check_in(ticket_id: str, user=Depends(get_current_user), repos: Repositories = Depends(get_repos)):
    checkin_service = CheckInService(repos)
    return checkin_service.check_in(ticket_id, user)

# =========================
# ANNOUNCEMENTS
# =========================

@app.get("/announcements/{flight_id}", response_model=List[AnnouncementResponse])
def announcements(flight_id: str, user=Depends(get_current_user), repos: Repositories = Depends(get_repos)):
    announcement_service = AnnouncementService(repos)
    return announcement_service.list_for_flight(flight_id)

# =========================
# STAFF / ADMIN
# =========================

# @app.post("/admin/airplanes")
# def create_airplane(data: dict, staff=Depends(require_staff)):
#     return staff_service.create_airplane(staff, **data)

@app.post("/admin/airplanes")
def create_airplane(
    data: AirplaneCreateRequest,
    staff=Depends(require_staff), repos: Repositories = Depends(get_repos)
):
    seat_templates = {
        key: SeatTemplate(
            seat_number=tpl.seat_number,
            category=tpl.category,
        )
        for key, tpl in data.seat_templates.items()
    }
    staff_service = StaffService(repos)
    airplane = staff_service.create_airplane(
        staff=staff,
        model=data.model,
        seat_templates=seat_templates,
    )
    return airplane


# @app.post("/admin/flights")
# def create_flight(data: dict, staff=Depends(require_staff)):
#     return staff_service.create_flight(staff, data["flight"])
@app.post("/admin/flights")
def create_flight(
    data: FlightCreateRequest,
    staff=Depends(require_staff), repos: Repositories = Depends(get_repos)
):
    origin = repos.airports.get(data.origin_code)
    destination = repos.airports.get(data.destination_code)
    airplane = repos.airplanes.get(data.airplane_id)

    if not origin or not destination or not airplane:
        raise HTTPException(status_code=404, detail="Related entity not found")

    flight = Flight(
        id=generate_id(),
        flight_number=data.flight_number,
        origin=origin,
        destination=destination,
        departure_time=data.departure_time,
        arrival_time=data.arrival_time,
        airplane=airplane,
        price=data.price,
    )
    staff_service = StaffService(repos)
    return staff_service.create_flight(staff, flight)


@app.get("/admin/flights", response_model=List[FlightResponse])
def list_flights(staff=Depends(require_staff), repos: Repositories = Depends(get_repos)):
    return repos.flights.list_all()


@app.patch("/admin/flights/{flight_id}")
def update_flight(
    flight_id: str,
    status: FlightStatus | None = None,
    gate: str | None = None,
    terminal: str | None = None,
    staff=Depends(require_staff), repos: Repositories = Depends(get_repos)
):
    staff_service = StaffService(repos)
    return staff_service.update_flight(
        staff,
        flight_id,
        status=status,
        gate=gate,
        terminal=terminal,
    )

@app.post("/admin/bookings/{booking_id}/cancel")
def cancel_booking(
    booking_id: str,
    staff=Depends(require_staff), repos: Repositories = Depends(get_repos)
):
    staff_service = StaffService(repos)
    staff_service.cancel_booking(staff, booking_id)
    return {"status": "cancelled"}

@app.get("/admin/bookings/flight/{flight_id}", response_model=List[BookingResponse])
def bookings_by_flight(flight_id: str, staff=Depends(require_staff), repos: Repositories = Depends(get_repos)):
    staff_service = StaffService(repos)
    return staff_service.get_bookings_by_flight(staff, flight_id)

@app.post("/admin/bookings/reassign-seat")
def reassign_seat(
    data: SeatReassignRequest,
    staff=Depends(require_staff), repos: Repositories = Depends(get_repos)
):
    staff_service = StaffService(repos)
    return staff_service.reassign_seat(
        staff=staff,
        booking_id=data.booking_id,
        ticket_id=data.ticket_id,
        new_seat_number=data.new_seat_number,
    )



@app.post("/admin/announcements")
def create_announcement(
    data: AnnouncementCreateRequest,
    staff=Depends(require_staff), repos: Repositories = Depends(get_repos)
):
    staff_service = AnnouncementService(repos)
    return staff_service.create_announcement(
        staff=staff,
        flight_id=data.flight_id,
        type_=data.type,
        title=data.title,
        message=data.message,
    )


@app.get("/admin/announcements", response_model=List[AnnouncementResponse])
def list_all_announcements(
    staff=Depends(require_staff), repos: Repositories = Depends(get_repos)
):
    service = AnnouncementService(repos)
    return service.list_all(staff)



if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", reload=True)