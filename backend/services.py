from datetime import datetime, timedelta, date
from typing import List, Optional, Dict
# import uuid
from security import hash_password, verify_password


from models import (
    User,
    UserRole,
    PassengerProfile,
    PassengerDetails,
    Airport,
    Airplane,
    SeatTemplate,
    Flight,
    # SeatMap,
    # FlightSeat,
    SeatState,
    Booking,
    Ticket,
    BookingStatus,
    Payment,
    PaymentStatus,
    PaymentMethod,
    CheckIn,
    Announcement,
    AnnouncementType,
    FlightStatus,
    generate_id,
    generate_pnr,
    generate_ticket_number,
)

from repositories import Repositories


# repos = Repositories()




# =========================
# Base Exceptions
# =========================

class ServiceError(Exception):
    pass


class NotFound(ServiceError):
    pass


class PermissionDenied(ServiceError):
    pass


class ValidationError(ServiceError):
    pass


class Conflict(ServiceError):
    pass


# =========================
# AUTH / USERS
# =========================

class AuthService:


    def __init__(self, repos: Repositories):
        self.repos = repos

    def register_passenger(self, email, password):
        if self.repos.users.get_by_email(email):
            raise Conflict("User with this email already exists")

        user = User(
            id=generate_id(),
            email=email,
            hashed_password=hash_password(password),
            role=UserRole.PASSENGER,
        )
        self.repos.users.add(user)
        return user


    def create_staff(self, email: str, password: str) -> User:
        user = User(
            id=generate_id(),
            email=email,
            hashed_password=hash_password(password),
            role=UserRole.STAFF,
    )
        self.repos.users.add(user)
        return user


    # check password for security.
    def authenticate_user(self, email: str, password: str) -> User:
        user = self.repos.users.get_by_email(email)
        if not user:
            raise ValidationError("Invalid credentials")

        if not verify_password(password, user.hashed_password):
            raise ValidationError("Invalid credentials")

        return user



# =========================
# PASSENGER PROFILE
# =========================

class PassengerProfileService:
    def __init__(self, repos: Repositories):
        self.repos = repos

    def create_or_update(self, user: User, profile_data) -> PassengerProfile:
        """Create or update passenger profile"""
        if user.role != UserRole.PASSENGER:
            raise PermissionDenied("Only passengers have profiles")
        
        profile = PassengerProfile(
            full_name=profile_data.full_name,
            phone=profile_data.phone,
            passport_number=profile_data.passport_number,
            nationality=profile_data.nationality,
            date_of_birth=profile_data.date_of_birth,
            user_id=user.id,
        )
        
        self.repos.passenger_profiles.upsert(profile)
        return profile
    
    def get_profile(self, user: User) -> Optional[PassengerProfile]:
        """Get passenger profile"""
        if user.role != UserRole.PASSENGER:
            raise PermissionDenied("Only passengers have profiles")
        
        return self.repos.passenger_profiles.get_by_user(user.id)

    def update_profile(
        self,
        user: User,
        profile: PassengerProfile,
    ):
        if user.role != UserRole.PASSENGER:
            raise PermissionDenied("Only passengers have profiles")

        user.profile = profile
        self.repos.users.update(user)

    def ensure_completed(self, user: User):
        profile = self.repos.passenger_profiles.get_by_user(user.id)
        if not profile or not profile.is_complete():
            raise ValidationError("Passenger profile must be completed before booking")


# =========================
# AIRPORTS & FLIGHTS
# =========================

class AirportService:
    def __init__(self, repos: Repositories):
            self.repos = repos

    def list_airports(self) -> List[Airport]:
        return self.repos.airports.list_all()


class FlightService:
    def __init__(self, repos: Repositories):
        self.repos = repos
        
    def search_flights(
        self,
        origin_code: str,
        destination_code: str,
        departure_date: datetime,
    ) -> List[Flight]:
        target_date = departure_date if isinstance(departure_date, date) else departure_date.date()
        
        # Start and end of the target day for DateTime range query
        start_of_day = datetime.combine(target_date, datetime.min.time())
        end_of_day = datetime.combine(target_date, datetime.max.time())

        return self.repos.flights.find_by_route_and_date(
            origin_code, destination_code, start_of_day, end_of_day
        )

    def get_flight(self, flight_id: str) -> Flight:
        flight = self.repos.flights.get(flight_id)
        if not flight:
            raise NotFound("Flight not found")
        return flight
    
    def get_flight_details(self, flight_id: str) -> dict:
        """Get detailed flight information including seat map"""
        flight = self.get_flight(flight_id)
        
        return {
            "id": flight.id,
            "flight_number": flight.flight_number,
            "origin": flight.origin,
            "destination": flight.destination,
            "departure_time": flight.departure_time,
            "arrival_time": flight.arrival_time,
            "duration_minutes": flight.duration_minutes,
            "price": flight.price,
            "available_seats": flight.available_seats,
            "status": flight.status,
            "gate": flight.gate,
            "terminal": flight.terminal,
            "aircraft_model": flight.airplane.model,
            "seat_layout": flight.seat_layout,
            "seat_category_summary": flight.seat_category_summary,
        }


# =========================
# BOOKING & SEAT HOLD
# =========================

class BookingService:
    def __init__(self, repos: Repositories):
            self.repos = repos
    SEAT_HOLD_MINUTES = 10

    def create_booking(
        self,
        user: User,
        flight_id: str,
        passengers: List[PassengerDetails],
        seat_numbers: Optional[List[str]] = None,
    ) -> Booking:

        print(f"DEBUG: Starting create_booking for flight {flight_id}")
        # Optimize: cleanup holds for this specific flight before starting
        self.cleanup_expired_holds(flight_id)
        PassengerProfileService(self.repos).ensure_completed(user)

        flight = self.repos.flights.get(flight_id)
        if not flight:
            print(f"DEBUG: Flight {flight_id} not found")
            raise NotFound("Flight not found")
        
        now = datetime.utcnow()

        if flight.departure_time <= now:
            print(f"DEBUG: Flight {flight_id} already departed at {flight.departure_time}")
            raise ValidationError("Flight already departed")

        if not flight.can_be_booked():
            print(f"DEBUG: Flight {flight_id} status is {flight.status}")
            raise ValidationError("Flight cannot be booked")

        if seat_numbers and len(seat_numbers) != len(passengers):
            print(f"DEBUG: Count mismatch: {len(seat_numbers)} seats vs {len(passengers)} passengers")
            raise ValidationError("Passengers and seats count mismatch")

        booking = Booking(
            id=generate_id(),
            pnr=generate_pnr(),
            user_id=user.id,
            flight_id=flight.id,
            tickets=[],
        )

        hold_until = now + timedelta(minutes=self.SEAT_HOLD_MINUTES)
        print(f"DEBUG: Assigning {len(passengers)} tickets...")

        for idx, passenger in enumerate(passengers):
            seat_number = (
                seat_numbers[idx]
                if seat_numbers
                else self._auto_assign_seat(flight)
            )
            print(f"DEBUG: Ticket {idx}: seat {seat_number}")

            seat = flight.seat_map.seats.get(seat_number)
            if not seat:
                print(f"DEBUG: Seat {seat_number} not found in flight seat map")
                raise Conflict(f"Seat {seat_number} not found")
            
            if seat.state != SeatState.AVAILABLE:
                print(f"DEBUG: Seat {seat_number} state is {seat.state}, not AVAILABLE")
                raise Conflict(f"Seat {seat_number} not available")

            seat.state = SeatState.HELD
            seat.hold_until = hold_until

            ticket = Ticket(
                id=generate_id(),
                passenger=passenger,
                seat_number=seat_number,
                ticket_number=generate_ticket_number(),
            )
            booking.tickets.append(ticket)

        print("DEBUG: Saving booking to DB...")
        self.repos.bookings.add(booking)
        print("DEBUG: Updating flight seat states in DB...")
        self.repos.flights.update(flight)
        print(f"DEBUG: Booking {booking.pnr} completed successfully")
        return booking

    def _auto_assign_seat(self, flight: Flight) -> str:
        available = flight.seat_map.available_seats()
        if not available:
            raise Conflict("No available seats")
        return available[0]

    def cleanup_expired_holds(self, flight_id: Optional[str] = None):
        now = datetime.utcnow()
        print(f"DEBUG: Running cleanup_expired_holds for {'all flights' if not flight_id else f'flight {flight_id}'}")

        if flight_id:
            flight = self.repos.flights.get(flight_id)
            if flight:
                changed = False
                for seat in flight.seat_map.seats.values():
                    if seat.state == SeatState.HELD and seat.hold_until and seat.hold_until < now:
                        seat.state = SeatState.AVAILABLE
                        seat.hold_until = None
                        changed = True
                if changed:
                    self.repos.flights.update(flight)
            return

        for flight in self.repos.flights.list_all():
            changed = False
            for seat in flight.seat_map.seats.values():
                if seat.state == SeatState.HELD and seat.hold_until and seat.hold_until < now:
                    seat.state = SeatState.AVAILABLE
                    seat.hold_until = None
                    changed = True

            if changed:
                self.repos.flights.update(flight)
    

    def get_user_bookings(self, user_id: str) -> List[Booking]:
        """
        Passenger: View upcoming and past trips
        """
        return [
            booking
            for booking in self.repos.bookings.list_all()
            if booking.user_id == user_id
        ]

    def get_booking_details(self, pnr: str, user: User) -> Booking:
        """
        Passenger: View booking details by PNR
        """
        booking = self.repos.bookings.get_by_pnr(pnr)
        if not booking:
            raise NotFound("Booking not found")

        if booking.user_id != user.id and user.role != UserRole.STAFF:
            raise PermissionDenied("Access denied")

        return booking



# =========================
# PAYMENT
# =========================

# class PaymentService:
#     def __init__(self, repos: Repositories):
#             self.repos = repos
    
#     def process_payment(
#         self,
#         user: User,
#         booking_id: str,
#         method: PaymentMethod,
#     ) -> Payment:

#         booking = self.repos.bookings.get(booking_id)
#         if not booking:
#             raise NotFound("Booking not found")

#         if booking.user_id != user.id:
#             raise PermissionDenied("You do not own this booking")

#         existing = self.repos.payments.get_by_booking(booking_id)
#         if existing and existing.status == PaymentStatus.PAID:
#             return existing  # idempotent

#         payment = Payment(
#             id=generate_id(),
#             booking_id=booking_id,
#             amount=0.0,
#             method=method,
#             status=PaymentStatus.PAID,
#         )

#         booking.status = BookingStatus.CONFIRMED
#         self.repos.bookings.update(booking)
#         self.repos.payments.add(payment)

#         flight = self.repos.flights.get(booking.flight_id)
#         for ticket in booking.tickets:
#             seat = flight.seat_map.seats[ticket.seat_number]
#             seat.state = SeatState.BOOKED
#             seat.hold_until = None

#         self.repos.flights.update(flight)
#         return payment
class PaymentService:
    def __init__(self, repos: Repositories):
        self.repos = repos

    def process_payment(
        self,
        user: User,
        booking_id: str,
        method: PaymentMethod,
    ) -> Payment:
        try:
            print(f"DEBUG: PaymentService: Processing payment for booking {booking_id}, user {user.id}")

            booking = self.repos.bookings.get(booking_id)
            if not booking:
                print(f"DEBUG: Booking {booking_id} not found")
                raise NotFound("Booking not found")

            if booking.user_id != user.id:
                print(f"DEBUG: User {user.id} does not own booking {booking_id}")
                raise PermissionDenied("You do not own this booking")

            flight = self.repos.flights.get(booking.flight_id)
            if not flight:
                print(f"DEBUG: Flight {booking.flight_id} not found for booking {booking_id}")
                raise NotFound("Flight not found")

            existing = self.repos.payments.get_by_booking(booking_id)
            
            if existing:
                print(f"DEBUG: Existing payment found for booking {booking_id}, status: {existing.status}")
                if existing.status == PaymentStatus.PAID:
                    print("DEBUG: Payment already PAID, returning existing record (idempotent)")
                    return existing 
                
                # update existing record to PAID
                print("DEBUG: Updating existing PENDING/FAILED payment to PAID...")
                existing.status = PaymentStatus.PAID
                existing.method = method
                existing.amount = flight.price
                self.repos.payments.update(existing)
                payment = existing
            else:
                print("DEBUG: Creating new payment record...")
                payment = Payment(
                    id=generate_id(),
                    booking_id=booking_id,
                    amount=flight.price,
                    method=method,
                    status=PaymentStatus.PAID,
                )
                self.repos.payments.add(payment)

            print(f"DEBUG: Confirming booking {booking_id}...")
            booking.status = BookingStatus.CONFIRMED
            self.repos.bookings.update(booking)

            print(f"DEBUG: Finalizing {len(booking.tickets)} seat states to BOOKED...")
            for ticket in booking.tickets:
                seat = flight.seat_map.seats.get(ticket.seat_number)
                if seat:
                    seat.state = SeatState.BOOKED
                    seat.hold_until = None
                else:
                    print(f"DEBUG: WARNING: Seat {ticket.seat_number} not found in map for final booking!")

            self.repos.flights.update(flight)
            print(f"DEBUG: Payment and Booking {booking.pnr} confirmed successfully")
            return payment
        except Exception as e:
            if isinstance(e, (NotFound, PermissionDenied, ServiceError)):
                raise e
            print(f"ERROR: Payment processing failed: {e}")
            raise ServiceError(f"System Error during payment: {str(e)}")


# =========================
# CHECK-IN
# =========================

class CheckInService:
    def __init__(self, repos: Repositories):
        self.repos = repos
    def check_in(self, ticket_id: str, user: User) -> CheckIn:
        try:
            booking = self.repos.bookings.get_by_ticket_id(ticket_id)

            if not booking:
                 print(f"DEBUG: CheckIn: Ticket {ticket_id} not found or no booking linked")
                 raise NotFound("Ticket not found")
                 
            if booking.status != BookingStatus.CONFIRMED:
                print(f"DEBUG: CheckIn: Booking {booking.id} status is {booking.status}, expected CONFIRMED")
                raise ValidationError("Booking not confirmed")

            flight = self.repos.flights.get(booking.flight_id)
            now = datetime.utcnow()
            
            # Allow check-in purely for demo if within 24h window OR if flight is tomorrow/today
            # Debug log the times
            print(f"DEBUG: CheckIn: Flight {flight.flight_number} departs {flight.departure_time}, Now is {now}")

            # RELAXED RULE FOR DEMO: Allow if within 48h just to be safe for testing
            if not (flight.departure_time - timedelta(hours=48) <= now <= flight.departure_time + timedelta(hours=2)):
                 print(f"DEBUG: CheckIn window closed. Departure: {flight.departure_time}, Now: {now}")
                 raise ValidationError(f"Check-in unavailable. Flight departs {flight.departure_time}")

            # Check if executing check-in
            checkin = CheckIn(
                id=generate_id(),
                ticket_id=ticket_id,
                checked_in_at=now,
                boarding_time=flight.departure_time - timedelta(minutes=30),
                gate=flight.gate or "TBD",
                qr_code=f"{ticket_id}:{flight.id}",
            )

            self.repos.checkins.add(checkin)
            print(f"DEBUG: CheckIn successful for ticket {ticket_id}")
            return checkin
        except Exception as e:
            if isinstance(e, (NotFound, PermissionDenied, ServiceError, ValidationError)):
                raise e
            print(f"ERROR: Check-in failed: {e}")
            raise ServiceError(f"System Error during check-in: {str(e)}")


# =========================
# ANNOUNCEMENTS
# =========================

class AnnouncementService:
    def __init__(self, repos: Repositories):
        self.repos = repos
    def create_announcement(
        self,
        staff: User,
        flight_id: str,
        type_: AnnouncementType,
        title: str,
        message: str,
    ) -> Announcement:

        if staff.role != UserRole.STAFF:
            raise PermissionDenied("Staff only")

        ann = Announcement(
            id=generate_id(),
            flight_id=flight_id,
            type=type_,
            title=title,
            message=message,
        )
        self.repos.announcements.add(ann)
        return ann

    def list_for_flight(self, flight_id: str) -> List[Announcement]:
        return self.repos.announcements.list_for_flight(flight_id)

    def list_all(self, staff: User) -> List[Announcement]:
        if staff.role != UserRole.STAFF:
            raise PermissionDenied("Staff only")
        return self.repos.announcements.list_all()


# =========================
# STAFF / ADMIN
# =========================

class StaffService:
    def __init__(self, repos: Repositories):
        self.repos = repos
    def create_airplane(
        self,
        staff: User,
        model: str,
        seat_templates: Dict[str, SeatTemplate],
    ) -> Airplane:

        if staff.role != UserRole.STAFF:
            raise PermissionDenied("Staff only")

        airplane = Airplane(
            id=generate_id(),
            model=model,
            seat_templates=seat_templates,
        )
        self.repos.airplanes.add(airplane)
        return airplane

    def create_flight(
        self,
        staff: User,
        flight: Flight,
    ) -> Flight:

        if staff.role != UserRole.STAFF:
            raise PermissionDenied("Staff only")

        self.repos.flights.add(flight)
        return flight

    def cancel_booking(self, staff: User, booking_id: str):
        if staff.role != UserRole.STAFF:
            raise PermissionDenied("Staff only")

        booking = self.repos.bookings.get(booking_id)
        if not booking:
            raise NotFound("Booking not found")

        booking.status = BookingStatus.CANCELLED
        self.repos.bookings.update(booking)

    def update_flight(
        self,
        staff: User,
        flight_id: str,
        *,
        status: Optional[FlightStatus] = None,
        gate: Optional[str] = None,
        terminal: Optional[str] = None,
        departure_time: Optional[datetime] = None,
        arrival_time: Optional[datetime] = None,
    ) -> Flight:

        if staff.role != UserRole.STAFF:
            raise PermissionDenied("Staff only")

        flight = self.repos.flights.get(flight_id)
        if not flight:
            raise NotFound("Flight not found")

        if status is not None and status != flight.status:
            flight.status = status
            
            # AUTOMATIC ANNOUNCEMENT
            try:
                ann_type = AnnouncementType.INFO
                if status == FlightStatus.DELAYED:
                    ann_type = AnnouncementType.DELAY
                elif status == FlightStatus.CANCELLED:
                    ann_type = AnnouncementType.CANCELLATION
                elif status == FlightStatus.BOARDING:
                    ann_type = AnnouncementType.BOARDING
                elif status == FlightStatus.LANDED:
                    ann_type = AnnouncementType.INFO
                
                ann_message = f"Flight {flight.flight_number} is now {status.value}."
                if status == FlightStatus.DELAYED:
                    ann_message = f"Attention: Flight {flight.flight_number} has been delayed."
                elif status == FlightStatus.BOARDING:
                    ann_message = f"Now boarding Flight {flight.flight_number} at Gate {flight.gate or 'TBD'}."
                
                ann = Announcement(
                    id=generate_id(),
                    flight_id=flight.id,
                    type=ann_type,
                    title=f"Flight {status.value}",
                    message=ann_message,
                )
                self.repos.announcements.add(ann)
                print(f"DEBUG: Auto-created announcement for flight {flight.flight_number} status change to {status.value}")
            except Exception as e:
                print(f"ERROR: Failed to create auto-announcement: {e}")

        if gate is not None:
            flight.gate = gate
        if terminal is not None:
            flight.terminal = terminal
        if departure_time is not None:
            flight.departure_time = departure_time
        if arrival_time is not None:
            flight.arrival_time = arrival_time

        self.repos.flights.update(flight)
        return flight
    
    def get_bookings_by_flight(
        self,
        staff: User,
        flight_id: str,
    ) -> List[Booking]:

        if staff.role != UserRole.STAFF:
            raise PermissionDenied("Staff only")

        return [
            booking
            for booking in self.repos.bookings.list_all()
            if booking.flight_id == flight_id
        ]
    

    def get_booking_by_pnr(
        self,
        staff: User,
        pnr: str,
    ) -> Booking:

        if staff.role != UserRole.STAFF:
            raise PermissionDenied("Staff only")

        booking = self.repos.bookings.get_by_pnr(pnr)
        if not booking:
            raise NotFound("Booking not found")

        return booking
    

    def reassign_seat(
        self,
        staff: User,
        booking_id: str,
        ticket_id: str,
        new_seat_number: str,
    ) -> Booking:

        if staff.role != UserRole.STAFF:
            raise PermissionDenied("Staff only")

        booking = self.repos.bookings.get(booking_id)
        if not booking:
            raise NotFound("Booking not found")

        flight =self.repos.flights.get(booking.flight_id)

        ticket = next((t for t in booking.tickets if t.id == ticket_id), None)
        if not ticket:
            raise NotFound("Ticket not found")

        new_seat = flight.seat_map.seats.get(new_seat_number)
        if not new_seat:
            raise ValidationError("Seat does not exist")

        if new_seat.state == SeatState.BOOKED:
            raise Conflict("Seat already booked")

        # release old seat
        old_seat = flight.seat_map.seats[ticket.seat_number]
        old_seat.state = SeatState.AVAILABLE
        old_seat.hold_until = None

        # assign new seat
        new_seat.state = SeatState.BOOKED
        new_seat.hold_until = None

        ticket.seat_number = new_seat_number

        self.repos.flights.update(flight)
        self.repos.bookings.update(booking)

        return booking
