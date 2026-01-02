from datetime import datetime
from sqlalchemy.orm import Session

from db_models import (
    UserDB,
    PassengerProfileDB,
    AirportDB,
    AirplaneDB,
    FlightDB,
    FlightSeatDB,
    BookingDB,
    TicketDB,
    PaymentDB,
    CheckInDB,
    AnnouncementDB,
)
from models import (
    User,
    PassengerProfile,
    Airport,
    Airplane,
    SeatTemplate,
    PassengerDetails, 
    Flight,
    FlightSeat,
    SeatMap,
    Booking,
    Ticket,
    Payment,
    CheckIn,
    Announcement,
)
from typing import List, Optional

class BaseSQLiteRepository:
    def __init__(self, session: Session):
        self.session = session
# =========================
# USER REPOSITORY
class UserSQLiteRepository(BaseSQLiteRepository):

    def get(self, user_id: str) -> Optional[User]:
        row = self.session.get(UserDB, user_id)
        if not row:
            return None
        return User(
            id=row.id,
            email=row.email,
            hashed_password=row.hashed_password,
            role=row.role,
        )

    def get_by_email(self, email: str) -> Optional[User]:
        row = self.session.query(UserDB).filter_by(email=email).first()
        if not row:
            return None
        return User(
            id=row.id,
            email=row.email,
            hashed_password=row.hashed_password,
            role=row.role,
        )

    def add(self, user: User):
        self.session.add(
            UserDB(
                id=user.id,
                email=user.email,
                hashed_password=user.hashed_password,
                role=user.role,
            )
        )
        self.session.commit()
    def list_all(self) -> List[User]:
        return [
            User(
                id=r.id,
                email=r.email,
                hashed_password=r.hashed_password,
                role=r.role,
            )
            for r in self.session.query(UserDB).all()
        ]

class PassengerProfileSQLiteRepository(BaseSQLiteRepository):

    def get_by_user(self, user_id: str) -> Optional[PassengerProfile]:
        row = self.session.query(PassengerProfileDB).filter_by(user_id=user_id).first()
        if not row:
            return None
        return PassengerProfile(
            full_name=row.full_name,
            phone=row.phone,
            passport_number=row.passport_number,
            nationality=row.nationality,
            date_of_birth=row.date_of_birth,
            user_id=row.user_id,
        )

    def upsert(self, profile: PassengerProfile):
        row = self.session.query(PassengerProfileDB).filter_by(user_id=profile.user_id).first()
        if row:
            row.full_name = profile.full_name
            row.phone = profile.phone
            row.passport_number = profile.passport_number
            row.nationality = profile.nationality
            row.date_of_birth = profile.date_of_birth
        else:
            self.session.add(
                PassengerProfileDB(
                    user_id=profile.user_id,
                    full_name=profile.full_name,
                    phone=profile.phone,
                    passport_number=profile.passport_number,
                    nationality=profile.nationality,
                    date_of_birth=profile.date_of_birth,
                )
            )
        self.session.commit()
# =========================
# AIRPORT REPOSITORY

class AirportSQLiteRepository(BaseSQLiteRepository):

    def get(self, code: str) -> Optional[Airport]:
        row = self.session.get(AirportDB, code)
        if not row:
            return None
        return Airport(code=row.code, name=row.name, city=row.city, country=row.country)

    def list_all(self) -> List[Airport]:
        return [
            Airport(code=r.code, name=r.name, city=r.city, country=r.country)
            for r in self.session.query(AirportDB).all()
        ]

    def add(self, airport: Airport):
        self.session.add(
            AirportDB(
                code=airport.code,
                name=airport.name,
                city=airport.city,
                country=airport.country,
            )
        )
        self.session.commit()
# ========================= 
# AIRPLANE REPOSITORY
class AirplaneSQLiteRepository(BaseSQLiteRepository):

    def get(self, airplane_id: str) -> Optional[Airplane]:
        row = self.session.get(AirplaneDB, airplane_id)
        if not row:
            return None

        seat_templates = {
            k: SeatTemplate(**v)
            for k, v in row.seat_templates.items()
        }

        return Airplane(
            id=row.id,
            model=row.model,
            seat_templates=seat_templates,
        )

    def add(self, airplane: Airplane):
        self.session.add(
            AirplaneDB(
                id=airplane.id,
                model=airplane.model,
                seat_templates={
                    k: {"seat_number": v.seat_number, "category": v.category}
                    for k, v in airplane.seat_templates.items()
                },
            )
        )
        self.session.commit()
    def list_all(self) -> List[Airplane]:
        return [
            Airplane(
                id=r.id,
                model=r.model,
                seat_templates={
                    k: SeatTemplate(**v)
                    for k, v in r.seat_templates.items()
                },
            )
            for r in self.session.query(AirplaneDB).all()
        ]

class FlightSQLiteRepository(BaseSQLiteRepository):

    def get(self, flight_id: str) -> Optional[Flight]:
        row = self.session.get(FlightDB, flight_id)
        if not row:
            return None

        seat_map = SeatMap({
            s.seat_number: FlightSeat(
                seat_number=s.seat_number,
                category=s.category,
                state=s.state,
                hold_until=s.hold_until,
            )
            for s in row.seats
        })

        return Flight(
            id=row.id,
            flight_number=row.flight_number,
            origin=Airport(row.origin.code, row.origin.name, row.origin.city, row.origin.country),
            destination=Airport(row.destination.code, row.destination.name, row.destination.city, row.destination.country),
            departure_time=row.departure_time,
            arrival_time=row.arrival_time,
            airplane=Airplane(
                id=row.airplane.id,
                model=row.airplane.model,
                seat_templates={},  # seat templates not needed here
            ),
            price=row.price,
            status=row.status,
            gate=row.gate,
            terminal=row.terminal,
            seat_map=seat_map,
        )
        
    def add(self, flight: Flight):
        flight_db = FlightDB(
            id=flight.id,
            flight_number=flight.flight_number,
            origin_code=flight.origin.code,
            destination_code=flight.destination.code,
            departure_time=flight.departure_time,
            arrival_time=flight.arrival_time,
            price=flight.price,
            status=flight.status,
            gate=flight.gate,
            terminal=flight.terminal,
            airplane_id=flight.airplane.id,
        )

        # 🔴 КРИТИЧЕСКОЕ: сохраняем seats
        for seat in flight.seat_map.seats.values():
            flight_db.seats.append(
                FlightSeatDB(
                    seat_number=seat.seat_number,
                    category=seat.category,
                    state=seat.state,
                    hold_until=seat.hold_until,
                )
            )
        self.session.add(flight_db)
        self.session.commit()

    def update(self, flight: Flight):
        flight_db = self.session.get(FlightDB, flight.id)
        if not flight_db:
            return

        # обновляем поля рейса
        flight_db.status = flight.status
        flight_db.gate = flight.gate
        flight_db.terminal = flight.terminal
        flight_db.departure_time = flight.departure_time
        flight_db.arrival_time = flight.arrival_time

        # 🔴 КРИТИЧЕСКОЕ: обновляем seat states
        db_seats = {s.seat_number: s for s in flight_db.seats}

        for seat in flight.seat_map.seats.values():
            if seat.seat_number in db_seats:
                db_seat = db_seats[seat.seat_number]
                db_seat.state = seat.state
                db_seat.hold_until = seat.hold_until
        self.session.commit()

    def list_all(self) -> List[Flight]:
        rows = self.session.query(FlightDB).all()
        return [self.get(r.id) for r in rows]

    def find_by_route_and_date(
        self, origin_code: str, destination_code: str, start: datetime, end: datetime
    ) -> List[Flight]:
        rows = (
            self.session.query(FlightDB)
            .filter_by(origin_code=origin_code, destination_code=destination_code)
            .filter(FlightDB.departure_time.between(start, end))
            .all()
        )
        return [self.get(r.id) for r in rows]

class BookingSQLiteRepository(BaseSQLiteRepository):
    def _to_domain(self, row: BookingDB) -> Booking:
        flight = self.session.get(FlightDB, row.flight_id)
        
        domain_booking = Booking(
            id=row.id,
            pnr=row.pnr,
            user_id=row.user_id,
            flight_id=row.flight_id,
            status=row.status,
            created_at=row.created_at,
            tickets=[
                Ticket(
                    id=t.id,
                    passenger=PassengerDetails(
                        full_name=t.passenger_full_name,
                        passport_number=t.passenger_passport,
                        nationality=t.passenger_nationality,
                        date_of_birth=t.passenger_birth_date,
                    ),
                    seat_number=t.seat_number,
                    ticket_number=t.ticket_number,
                )
                for t in row.tickets
            ],
        )
        
        if flight:
            # Dynamically add attributes for Pydantic mapping
            setattr(domain_booking, 'flight_number', flight.flight_number)
            setattr(domain_booking, 'origin_city', flight.origin.city)
            setattr(domain_booking, 'dest_city', flight.destination.city)
            
        return domain_booking

    def get(self, booking_id: str) -> Optional[Booking]:
        row = self.session.get(BookingDB, booking_id)
        if not row:
            return None

        return self._to_domain(row)

    def get_by_pnr(self, pnr: str) -> Optional[Booking]:
        row = self.session.query(BookingDB).filter_by(pnr=pnr).first()
        if not row:
            return None
        return self._to_domain(row)

    def list_all(self) -> List[Booking]:
        return [self._to_domain(r) for r in self.session.query(BookingDB).all()]

    def add(self, booking: Booking):
        print(f"DEBUG: Repository: Adding BookingDB {booking.pnr}")
        self.session.add(
            BookingDB(
                id=booking.id,
                pnr=booking.pnr,
                user_id=booking.user_id,
                flight_id=booking.flight_id,
                status=booking.status,
            )
        )
        for ticket in booking.tickets:
            print(f"DEBUG: Repository: Adding TicketDB for {ticket.passenger_name}")
            self._add_ticket(ticket, booking.id)
        
        print("DEBUG: Repository: Committing booking and tickets...")
        self.session.commit()

    def update(self, booking: Booking):
        row = self.session.get(BookingDB, booking.id)
        row.status = booking.status
        self.session.commit()

    def get_by_ticket_id(self, ticket_id: str) -> Optional[Booking]:
        row = (
            self.session.query(BookingDB)
            .join(TicketDB)
            .filter(TicketDB.id == ticket_id)
            .first()
        )
        if not row:
            return None

        return self._to_domain(row)


    # ---------- helpers ----------

    def _add_ticket(self, ticket: Ticket, booking_id: str):
        self.session.add(
            TicketDB(
                id=ticket.id,
                booking_id=booking_id,
                passenger_full_name=ticket.passenger.full_name,
                passenger_passport=ticket.passenger.passport_number,
                passenger_nationality=ticket.passenger.nationality,
                passenger_birth_date=ticket.passenger.date_of_birth,
                seat_number=ticket.seat_number,
                ticket_number=ticket.ticket_number,
        ))
        # self.session.commit() -- Removed for atomicity

        
class PaymentSQLiteRepository(BaseSQLiteRepository):

    def get_by_booking(self, booking_id: str) -> Optional[Payment]:
        row = self.session.query(PaymentDB).filter_by(booking_id=booking_id).first()
        if not row:
            return None

        return Payment(
            id=row.id,
            booking_id=row.booking_id,
            amount=row.amount,
            status=row.status,
            method=row.method,
            created_at=row.created_at,  # Added created_at
        )

    def add(self, payment: Payment):
        self.session.add(
            PaymentDB(
                id=payment.id,
                booking_id=payment.booking_id,
                amount=payment.amount,
                status=payment.status,
                method=payment.method,
                created_at=payment.created_at, # Added created_at
            )
        )
        self.session.commit()

    def update(self, payment: Payment):
        row = self.session.get(PaymentDB, payment.id)
        if row:
            row.status = payment.status
            row.method = payment.method
            row.amount = payment.amount
            # row.created_at should not be updated usually
            self.session.commit()

class CheckInSQLiteRepository(BaseSQLiteRepository):

    def get_by_ticket(self, ticket_id: str) -> Optional[CheckIn]:
        row = self.session.query(CheckInDB).filter_by(ticket_id=ticket_id).first()
        if not row:
            return None

        return CheckIn(
            id=row.id,
            ticket_id=row.ticket_id,
            checked_in_at=row.checked_in_at,
            boarding_time=row.boarding_time,
            gate=row.gate,
            qr_code=row.qr_code,
        )

    def add(self, checkin: CheckIn):
        self.session.add(
            CheckInDB(
                id=checkin.id,
                ticket_id=checkin.ticket_id,
                checked_in_at=checkin.checked_in_at,
                boarding_time=checkin.boarding_time,
                gate=checkin.gate,
                qr_code=checkin.qr_code,
            )
        )
        self.session.commit()

class AnnouncementSQLiteRepository(BaseSQLiteRepository):

    def list_for_flight(self, flight_id: str) -> List[Announcement]:
        rows = self.session.query(AnnouncementDB).filter_by(flight_id=flight_id).all()

        return [
            Announcement(
                id=r.id,
                flight_id=r.flight_id,
                type=r.type,
                title=r.title,
                message=r.message,
                created_at=r.created_at,
            )
            for r in rows
        ]

    def list_all(self) -> List[Announcement]:
        rows = self.session.query(AnnouncementDB).order_by(AnnouncementDB.created_at.desc()).all()
        return [
            Announcement(
                id=r.id,
                flight_id=r.flight_id,
                type=r.type,
                title=r.title,
                message=r.message,
                created_at=r.created_at,
            )
            for r in rows
        ]

    def add(self, announcement: Announcement):
        self.session.add(
            AnnouncementDB(
                id=announcement.id,
                flight_id=announcement.flight_id,
                type=announcement.type,
                title=announcement.title,
                message=announcement.message,
            )
        )
        self.session.commit()
