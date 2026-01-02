from datetime import datetime, date
from models import SeatState
from database import Base


from sqlalchemy import (
    Column,
    String,
    Integer,
    DateTime,
    Date,
    Float,
    Enum,
    ForeignKey,
    Boolean,
    JSON,
)
from sqlalchemy.orm import relationship

from models import (
    UserRole,
    BookingStatus,
    PaymentStatus,
    PaymentMethod,
    FlightStatus,
    SeatCategory,
    AnnouncementType,
)



# =========================
# USERS
# =========================

class UserDB(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True)
    email = Column(String, unique=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(Enum(UserRole), nullable=False)

    passenger_profile = relationship(
        "PassengerProfileDB",
        uselist=False,
        back_populates="user",
        cascade="all, delete-orphan",
    )

    bookings = relationship("BookingDB", back_populates="user")


class PassengerProfileDB(Base):
    __tablename__ = "passenger_profiles"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String, ForeignKey("users.id"), unique=True)

    full_name = Column(String, nullable=False)
    phone = Column(String, nullable=False)
    passport_number = Column(String, nullable=False)
    nationality = Column(String, nullable=False)
    date_of_birth = Column(Date, nullable=False)

    user = relationship("UserDB", back_populates="passenger_profile")


# =========================
# AIRPORTS & AIRPLANES
# =========================

class AirportDB(Base):
    __tablename__ = "airports"

    code = Column(String, primary_key=True)
    name = Column(String, nullable=False)
    city = Column(String, nullable=False)
    country = Column(String, nullable=False)


class AirplaneDB(Base):
    __tablename__ = "airplanes"

    id = Column(String, primary_key=True)
    model = Column(String, nullable=False)

    # seat_templates: Dict[str, SeatTemplate]
    seat_templates = Column(JSON, nullable=False)

    flights = relationship("FlightDB", back_populates="airplane")


# =========================
# FLIGHTS & SEATS
# =========================

class FlightDB(Base):
    __tablename__ = "flights"

    id = Column(String, primary_key=True)
    flight_number = Column(String, nullable=False)

    origin_code = Column(String, ForeignKey("airports.code"), index=True)
    destination_code = Column(String, ForeignKey("airports.code"), index=True)

    departure_time = Column(DateTime, nullable=False, index=True)
    arrival_time = Column(DateTime, nullable=False)

    price = Column(Float, nullable=False)
    status = Column(Enum(FlightStatus), nullable=False)

    gate = Column(String, nullable=True)
    terminal = Column(String, nullable=True)

    airplane_id = Column(String, ForeignKey("airplanes.id"))

    airplane = relationship("AirplaneDB", back_populates="flights")
    origin = relationship("AirportDB", foreign_keys=[origin_code])
    destination = relationship("AirportDB", foreign_keys=[destination_code])

    seats = relationship(
        "FlightSeatDB",
        back_populates="flight",
        cascade="all, delete-orphan",
    )


class FlightSeatDB(Base):
    __tablename__ = "flight_seats"

    id = Column(Integer, primary_key=True, autoincrement=True)
    flight_id = Column(String, ForeignKey("flights.id"), index=True)

    seat_number = Column(String, nullable=False)
    category = Column(Enum(SeatCategory), nullable=False)


    # is_available = Column(Boolean, default=True)
    state = Column(
        Enum(SeatState),
        default=SeatState.AVAILABLE,
        nullable=False,
    )

    hold_until = Column(
        DateTime,
        nullable=True,
    )


    flight = relationship("FlightDB", back_populates="seats")


# =========================
# BOOKINGS & TICKETS
# =========================

class BookingDB(Base):
    __tablename__ = "bookings"

    id = Column(String, primary_key=True)
    pnr = Column(String, unique=True, nullable=False)
    user_id = Column(String, ForeignKey("users.id"), index=True)
    flight_id = Column(String, ForeignKey("flights.id"), index=True)
    status = Column(Enum(BookingStatus), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("UserDB", back_populates="bookings")
    flight = relationship("FlightDB")
    tickets = relationship(
        "TicketDB",
        back_populates="booking",
        cascade="all, delete-orphan",
    )


class TicketDB(Base):
    __tablename__ = "tickets"

    id = Column(String, primary_key=True)
    booking_id = Column(String, ForeignKey("bookings.id"))

    passenger_full_name = Column(String, nullable=False)
    passenger_passport = Column(String, nullable=False)
    passenger_nationality = Column(String, nullable=False)
    passenger_birth_date = Column(Date, nullable=False)

    seat_number = Column(String, nullable=False)
    ticket_number = Column(String, unique=True, nullable=False)

    booking = relationship("BookingDB", back_populates="tickets")


# =========================
# PAYMENTS
# =========================

class PaymentDB(Base):
    __tablename__ = "payments"

    id = Column(String, primary_key=True)
    booking_id = Column(String, ForeignKey("bookings.id"), unique=True)
    
    amount = Column(Float, nullable=False)
    status = Column(Enum(PaymentStatus), nullable=False)
    method = Column(Enum(PaymentMethod), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


# =========================
# CHECK-IN
# =========================

class CheckInDB(Base):
    __tablename__ = "checkins"

    id = Column(String, primary_key=True)
    ticket_id = Column(String, ForeignKey("tickets.id"))
    checked_in_at = Column(DateTime, nullable=False)
    boarding_time = Column(DateTime, nullable=False)
    gate = Column(String, nullable=False)
    qr_code = Column(String, nullable=False)


# =========================
# ANNOUNCEMENTS
# =========================

class AnnouncementDB(Base):
    __tablename__ = "announcements"

    id = Column(String, primary_key=True)
    flight_id = Column(String, ForeignKey("flights.id"), index=True)

    type = Column(Enum(AnnouncementType), nullable=False)
    title = Column(String, nullable=False)
    message = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
