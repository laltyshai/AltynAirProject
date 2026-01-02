from datetime import datetime, date
from typing import List, Optional
from enum import Enum

from pydantic import BaseModel, EmailStr, Field
from pydantic import ConfigDict



# =========================
# ENUMS (API-level)
# =========================

class UserRole(str, Enum):
    PASSENGER = "PASSENGER"
    STAFF = "STAFF"


class FlightStatus(str, Enum):
    SCHEDULED = "SCHEDULED"
    BOARDING = "BOARDING"
    DELAYED = "DELAYED"
    CANCELLED = "CANCELLED"
    DEPARTED = "DEPARTED"
    LANDED = "LANDED"


class BookingStatus(str, Enum):
    CREATED = "CREATED"
    CONFIRMED = "CONFIRMED"
    CANCELLED = "CANCELLED"


class PaymentMethod(str, Enum):
    CARD = "CARD"
    APPLE_PAY = "APPLE_PAY"
    GOOGLE_PAY = "GOOGLE_PAY"


class AnnouncementType(str, Enum):
    DELAY = "DELAY"
    CANCELLATION = "CANCELLATION"
    GATE_CHANGE = "GATE_CHANGE"
    BOARDING = "BOARDING"
    INFO = "INFO"


class SeatCategory(str, Enum):
    STANDARD = "STANDARD"
    EXTRA_LEGROOM = "EXTRA_LEGROOM"


class PaymentStatus(str, Enum):
    PENDING = "PENDING"
    PAID = "PAID"
    FAILED = "FAILED"


# =========================
# AUTH
# =========================

class UserRegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)


class UserLoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserResponse(BaseModel):
    id: str
    email: EmailStr
    role: "UserRole"

    model_config = ConfigDict(from_attributes=True)


# =========================
# PASSENGER PROFILE
# =========================

class PassengerProfileCreate(BaseModel):
    full_name: str
    phone: str
    passport_number: str
    nationality: str
    date_of_birth: date


class PassengerProfileResponse(PassengerProfileCreate):
    pass


# =========================
# AIRPORTS
# =========================

class AirportResponse(BaseModel):
    code: str
    name: str
    city: str
    country: str

    model_config = ConfigDict(from_attributes=True)



# =========================
# FLIGHTS
# =========================

class FlightSearchRequest(BaseModel):
    origin: str
    destination: str
    departure_date: date


class FlightResponse(BaseModel):
    id: str
    flight_number: str
    origin: AirportResponse
    destination: AirportResponse
    departure_time: datetime
    arrival_time: datetime
    duration_minutes: int
    price: float
    available_seats: int
    status: FlightStatus

    model_config = ConfigDict(from_attributes=True)

class SeatCategorySummary(BaseModel):
    category: SeatCategory
    available: int
    total: int


class FlightDetailsResponse(FlightResponse):
    gate: Optional[str]
    terminal: Optional[str]
    aircraft_model: str
    seat_layout: str
    seat_category_summary: Optional[List[SeatCategorySummary]] = None
    model_config = ConfigDict(from_attributes=True)

class FlightCreateRequest(BaseModel):
    flight_number: str
    origin_code: str
    destination_code: str
    departure_time: datetime
    arrival_time: datetime
    airplane_id: str
    price: float


# =========================
# SEATS
# =========================

class SeatResponse(BaseModel):
    seat_number: str
    category: SeatCategory
    is_available: bool
    model_config = ConfigDict(from_attributes=True)

class SeatTemplateRequest(BaseModel):
    seat_number: str  # e.g. "12A"
    category: SeatCategory

class AirplaneCreateRequest(BaseModel):
    model: str
    seat_templates: dict[str, SeatTemplateRequest]


class SeatReassignRequest(BaseModel):
    booking_id: str
    ticket_id: str
    new_seat_number: str


# =========================
# BOOKINGS
# =========================

class PassengerDetailsRequest(BaseModel):
    full_name: str
    passport_number: str
    nationality: str
    date_of_birth: date


class BookingCreateRequest(BaseModel):
    flight_id: str
    passengers: List[PassengerDetailsRequest]
    seat_numbers: Optional[List[str]] = None


class TicketResponse(BaseModel):
    id: str
    ticket_number: str
    passenger_name: str
    seat_number: str

    model_config = ConfigDict(from_attributes=True)


class BookingResponse(BaseModel):
    id: str
    pnr: str
    status: BookingStatus
    flight_id: str
    flight_number: Optional[str] = None
    origin_city: Optional[str] = None
    dest_city: Optional[str] = None
    tickets: List[TicketResponse]
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

# =========================
# PAYMENTS
# =========================

class PaymentRequest(BaseModel):
    booking_id: str
    method: PaymentMethod


# class PaymentResponse(BaseModel):
#     id: str
#     booking_id: str
#     status: str
#     method: PaymentMethod

class PaymentResponse(BaseModel):
    id: str
    booking_id: str
    status: PaymentStatus
    method: PaymentMethod

    model_config = ConfigDict(from_attributes=True)


# =========================
# CHECK-IN
# =========================

class CheckInResponse(BaseModel):
    ticket_id: str
    boarding_time: datetime
    gate: str
    qr_code: str

    model_config = ConfigDict(from_attributes=True)

# =========================
# ANNOUNCEMENTS
# =========================

class AnnouncementResponse(BaseModel):
    id: str
    type: AnnouncementType
    title: str
    message: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class AnnouncementCreateRequest(BaseModel):
    flight_id: str
    type: AnnouncementType
    title: str
    message: str
