from __future__ import annotations
from collections import defaultdict
import re
from dataclasses import dataclass, field
from datetime import datetime, date, timedelta
from enum import Enum
from typing import List, Dict, Optional
import uuid


# =========================
# ENUMS
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


class PaymentStatus(str, Enum):
    PENDING = "PENDING"
    PAID = "PAID"
    FAILED = "FAILED"


class PaymentMethod(str, Enum):
    CARD = "CARD"
    APPLE_PAY = "APPLE_PAY"
    GOOGLE_PAY = "GOOGLE_PAY"


class SeatCategory(str, Enum):
    STANDARD = "STANDARD"
    EXTRA_LEGROOM = "EXTRA_LEGROOM"


class SeatState(str, Enum):
    AVAILABLE = "AVAILABLE"
    HELD = "HELD"
    BOOKED = "BOOKED"


class AnnouncementType(str, Enum):
    DELAY = "DELAY"
    CANCELLATION = "CANCELLATION"
    GATE_CHANGE = "GATE_CHANGE"
    BOARDING = "BOARDING"
    INFO = "INFO"


# =========================
# USER & PROFILE
# =========================

@dataclass
class PassengerProfile:
    full_name: str
    phone: str
    passport_number: str
    nationality: str
    date_of_birth: date
    user_id: Optional[str] = None

    def is_complete(self) -> bool:
        return all([
            self.full_name,
            self.phone,
            self.passport_number,
            self.nationality,
            self.date_of_birth
        ])


@dataclass
class User:
    id: str
    email: str
    hashed_password: str
    role: UserRole
    profile: Optional[PassengerProfile] = None


# =========================
# AIRPORT & AIRPLANE
# =========================

@dataclass
class Airport:
    code: str
    name: str
    city: str
    country: str


@dataclass
class SeatTemplate:
    seat_number: str
    category: SeatCategory


@dataclass
class Airplane:
    id: str
    model: str
    seat_templates: Dict[str, SeatTemplate]
    # immutable template (shared across flights)


# =========================
# FLIGHT & SEAT MAP
# =========================

@dataclass
class FlightSeat:
    seat_number: str
    category: SeatCategory
    state: SeatState = SeatState.AVAILABLE
    hold_until: Optional[datetime] = None



@dataclass
class SeatMap:
    seats: Dict[str, FlightSeat] = field(default_factory=dict)


    def available_seats(self) -> List[str]:
        now = datetime.utcnow()
        result = []

        for seat in self.seats.values():
            if seat.state == SeatState.AVAILABLE:
                result.append(seat.seat_number)
            elif seat.state == SeatState.HELD and seat.hold_until and seat.hold_until < now:
                seat.state = SeatState.AVAILABLE
                seat.hold_until = None
                result.append(seat.seat_number)

        return result


@dataclass
class Flight:
    id: str
    flight_number: str
    origin: Airport
    destination: Airport
    departure_time: datetime
    arrival_time: datetime
    airplane: Airplane
    price: float
    status: FlightStatus = FlightStatus.SCHEDULED
    gate: Optional[str] = None
    terminal: Optional[str] = None
    seat_map: SeatMap = field(default_factory=SeatMap)

    def duration(self) -> timedelta:
        return self.arrival_time - self.departure_time

    def can_be_booked(self) -> bool:
        return self.status not in {FlightStatus.CANCELLED, FlightStatus.DEPARTED}
    
    @property
    def available_seats(self) -> int:
        return len(self.seat_map.available_seats())

    @property
    def duration_minutes(self) -> int:
        return int(self.duration().total_seconds() // 60)
    
    # @property
    # def seat_layout(self) -> str:
    #     """
    #     Example output: '3-3', '2-4-2'
    #     """
    #     rows: dict[int, int] = defaultdict(int)

    #     for template in self.airplane.seat_templates.values():
    #         rows[template.row] += len(template.seats)

    #     return "-".join(str(count) for _, count in sorted(rows.items()))

    @property
    def seat_layout(self) -> str:
        """
        Example output: '3-3', '2-4-2'
        SeatTemplate = single seat (e.g. '12A'), row derived via regex.
        """
        row_to_letters = defaultdict(list)

        for seat_number in self.seat_map.seats.keys():
            m = re.match(r"(\d+)([A-Z])", seat_number)
            if not m:
                continue
            row = int(m.group(1))
            letter = m.group(2)
            row_to_letters[row].append(letter)

        if not row_to_letters:
            return ""

        first_row = sorted(row_to_letters.keys())[0]
        letters = sorted(row_to_letters[first_row])

        groups = []
        current = [letters[0]]
        for prev, curr in zip(letters, letters[1:]):
            if ord(curr) - ord(prev) == 1:
                current.append(curr)
            else:
                groups.append(current)
                current = [curr]
        groups.append(current)

        return "-".join(str(len(g)) for g in groups)
    

    @property
    def seat_category_summary(self) -> list[dict]:
        summary = {}

        for seat in self.seat_map.seats.values():
            category = seat.category

            if category not in summary:
                summary[category] = {"category": category, "total": 0, "available": 0}

            summary[category]["total"] += 1
            if seat.state == SeatState.AVAILABLE:
                summary[category]["available"] += 1

        return list(summary.values())




# =========================
# BOOKING & TICKETS
# =========================
@dataclass
class PassengerDetails:
    full_name: str
    passport_number: str
    nationality: str
    date_of_birth: date

@dataclass
class Ticket:
    id: str
    passenger: PassengerDetails
    seat_number: str
    ticket_number: str

    @property
    def passenger_name(self) -> str:
        return self.passenger.full_name


@dataclass
class Booking:
    id: str
    pnr: str
    user_id: str
    flight_id: str
    tickets: List[Ticket]
    status: BookingStatus = BookingStatus.CREATED
    created_at: datetime = field(default_factory=datetime.utcnow)


# =========================
# PAYMENT
# =========================

@dataclass
class Payment:
    id: str
    booking_id: str
    amount: float
    method: PaymentMethod
    status: PaymentStatus = PaymentStatus.PENDING
    created_at: datetime = field(default_factory=datetime.utcnow)


# =========================
# CHECK-IN
# =========================

@dataclass
class CheckIn:
    id: str
    ticket_id: str
    checked_in_at: datetime
    boarding_time: datetime
    gate: str
    qr_code: str


# =========================
# ANNOUNCEMENTS
# =========================

@dataclass
class Announcement:
    id: str
    flight_id: str
    type: AnnouncementType
    title: str
    message: str
    created_at: datetime = field(default_factory=datetime.utcnow)


# =========================
# HELPERS
# =========================

def generate_id() -> str:
    return str(uuid.uuid4())


def generate_pnr() -> str:
    return uuid.uuid4().hex[:6].upper()


def generate_ticket_number() -> str:
    return uuid.uuid4().hex.upper()
