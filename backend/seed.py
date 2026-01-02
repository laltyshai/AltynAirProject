from datetime import datetime, timedelta
import random
from typing import Dict

from database import SessionLocal, engine
from db_models import Base
from repositories import Repositories
from models import (
    Airport,
    Airplane,
    SeatTemplate,
    SeatCategory,
    Flight,
    FlightStatus,
    SeatMap,
    FlightSeat,
    SeatState,
    User,
    UserRole,
    generate_id,
    Announcement,
    AnnouncementType,
)
from security import hash_password

def create_airports(repos: Repositories):
    print("Seeding Airports...")
    airports = [
        Airport(code="IST", name="Istanbul Airport", city="Istanbul", country="Turkey"),
        Airport(code="JFK", name="John F. Kennedy International Airport", city="New York", country="USA"),
        Airport(code="LHR", name="Heathrow Airport", city="London", country="UK"),
        Airport(code="CDG", name="Charles de Gaulle Airport", city="Paris", country="France"),
        Airport(code="DXB", name="Dubai International Airport", city="Dubai", country="UAE"),
        Airport(code="AMS", name="Schiphol Airport", city="Amsterdam", country="Netherlands"),
        Airport(code="ALA", name="Almaty International Airport", city="Almaty", country="Kazakhstan"),
        Airport(code="TSE", name="Nursultan Nazarbayev International Airport", city="Astana", country="Kazakhstan"),
    ]

    for airport in airports:
        if not repos.airports.get(airport.code):
            repos.airports.add(airport)
            print(f"  + Added {airport.code}")
        else:
            print(f"  . Skipped {airport.code} (exists)")

def create_airplanes(repos: Repositories):
    print("Seeding Airplanes...")
    
    # Boeing 737-800: ~160 seats
    # Rows 1-4: Business (2+2), Rows 5-30: Economy (3+3)
    b737_templates = {}
    
    # Business Class (Rows 1-4, AC - DF)
    for row in range(1, 5):
        for col in ["A", "C", "D", "F"]: # 2-2 config
            seat_num = f"{row}{col}"
            b737_templates[seat_num] = SeatTemplate(seat_number=seat_num, category=SeatCategory.EXTRA_LEGROOM)

    # Economy Class (Rows 5-30, ABC - DEF)
    for row in range(5, 31):
        for col in ["A", "B", "C", "D", "E", "F"]:
            seat_num = f"{row}{col}"
            b737_templates[seat_num] = SeatTemplate(seat_number=seat_num, category=SeatCategory.STANDARD)

    b737 = Airplane(
        id="plane_b737_001",
        model="Boeing 737-800",
        seat_templates=b737_templates
    )

    # Airbus A320: ~150 seats
    a320_templates = {}
    for row in range(1, 26):
        for col in ["A", "B", "C", "D", "E", "F"]:
            seat_num = f"{row}{col}"
            category = SeatCategory.EXTRA_LEGROOM if row <= 3 else SeatCategory.STANDARD
            a320_templates[seat_num] = SeatTemplate(seat_number=seat_num, category=category)

    a320 = Airplane(
        id="plane_a320_001",
        model="Airbus A320",
        seat_templates=a320_templates
    )

    planes = [b737, a320]

    for plane in planes:
        if not repos.airplanes.get(plane.id):
            repos.airplanes.add(plane)
            print(f"  + Added {plane.model}")
        else:
            print(f"  . Skipped {plane.model} (exists)")
    
    return [b737, a320]

def generate_seat_map(airplane: Airplane, occupied_chance: float = 0.0) -> SeatMap:
    seats: Dict[str, FlightSeat] = {}
    for tpl in airplane.seat_templates.values():
        state = SeatState.AVAILABLE
        
        # Guarenteed booking for Row 1
        if tpl.seat_number.startswith("1") and len(tpl.seat_number) == 2: # 1A, 1B etc.
             state = SeatState.BOOKED
        # Random booking for others
        elif random.random() < occupied_chance:
            state = SeatState.BOOKED
            
        seats[tpl.seat_number] = FlightSeat(
            seat_number=tpl.seat_number,
            category=tpl.category,
            state=state
        )
    return SeatMap(seats=seats)

def create_flights(repos: Repositories, airplanes):
    print("Seeding Flights...")
    
    airports = repos.airports.list_all()
    if not airports:
        print(" [WARNING] No airports found. Cannot seed flights.")
        return []

    flight_count = 0
    now = datetime.utcnow()
    
    # Target date: Jan 3rd, 2026 (tomorrow relative to the user's current time)
    target_date = datetime(2026, 1, 3)

    # GUARANTEE coverage for all routes on Jan 3rd
    print(f"  > Creating guaranteed flights for {target_date.date()}...")
    for origin in airports:
        for dest in airports:
            if origin.code == dest.code:
                continue
                
            airplane = random.choice(airplanes)
            flight_number = f"KC{random.randint(100, 999)}"
            
            # Simple morning flight for every route
            departure_time = target_date.replace(hour=10, minute=0, second=0, microsecond=0)
            arrival_time = departure_time + timedelta(hours=3)
            
            # 50% chance to have some seats pre-booked
            oc = random.uniform(0.1, 0.4) if random.random() > 0.5 else 0.0

            flight = Flight(
                id=generate_id(),
                flight_number=flight_number,
                origin=origin,
                destination=dest,
                departure_time=departure_time,
                arrival_time=arrival_time,
                airplane=airplane,
                price=round(random.uniform(150, 450), 2),
                status=FlightStatus.SCHEDULED,
                gate=f"{random.choice(['A', 'B', 'C'])}{random.randint(1, 10)}",
                terminal="1",
                seat_map=generate_seat_map(airplane, occupied_chance=oc)
            )
            repos.flights.add(flight)
            flight_count += 1

    # Plus some random flights for the next 7 days for variety
    for i in range(2, 9): 
        date_offset = now + timedelta(days=i)
        for _ in range(10):
            origin = random.choice(airports)
            dest = random.choice([a for a in airports if a.code != origin.code])
            airplane = random.choice(airplanes)
            flight_number = f"KC{random.randint(100, 999)}"
            departure_time = date_offset.replace(hour=random.randint(6, 22), minute=0)
            arrival_time = departure_time + timedelta(hours=3)
            
            # 50% chance to have some seats pre-booked
            oc = random.uniform(0.1, 0.4) if random.random() > 0.5 else 0.0

            flight = Flight(
                id=generate_id(),
                flight_number=flight_number,
                origin=origin,
                destination=dest,
                departure_time=departure_time,
                arrival_time=arrival_time,
                airplane=airplane,
                price=round(random.uniform(200, 600), 2),
                status=FlightStatus.SCHEDULED,
                gate=f"G{random.randint(1, 20)}",
                terminal="1",
                seat_map=generate_seat_map(airplane, occupied_chance=oc)
            )
            repos.flights.add(flight)
            flight_count += 1
            
    print(f"  + Added {flight_count} flights total")
    return repos.flights.list_all()

def create_announcements(repos: Repositories, flights):
    print("Seeding Announcements...")
    # Seed announcements for some flights
    sample_flights = random.sample(flights, min(len(flights), 20))
    for flight in sample_flights:
        types = [
            (AnnouncementType.GATE_CHANGE, "Gate Change", f"Gate for {flight.flight_number} changed to {flight.gate}"),
            (AnnouncementType.DELAY, "Minor Delay", f"Flight {flight.flight_number} is delayed by 15 mins."),
            (AnnouncementType.INFO, "Boarding Info", f"Boarding for {flight.flight_number} will start soon."),
        ]
        a_type, a_title, a_msg = random.choice(types)
        
        announcement = Announcement(
            id=generate_id(),
            flight_id=flight.id,
            type=a_type,
            title=a_title,
            message=a_msg,
            created_at=datetime.utcnow()
        )
        repos.announcements.add(announcement)
    print(f"  + Added {len(sample_flights)} announcements")

def create_users(repos: Repositories):
    print("Seeding Users...")
    
    # Staff
    staff_email = "admin@aits.com"
    if not repos.users.get_by_email(staff_email):
        staff = User(
            id=generate_id(),
            email=staff_email,
            hashed_password=hash_password("admin123"),
            role=UserRole.STAFF
        )
        repos.users.add(staff)
        print(f"  + Added Staff User: {staff_email}")
    else:
        print(f"  . Skipped Staff (exists)")

    # Passenger
    passenger_email = "user@example.com"
    if not repos.users.get_by_email(passenger_email):
        user = User(
            id=generate_id(),
            email=passenger_email,
            hashed_password=hash_password("user123"),
            role=UserRole.PASSENGER
        )
        repos.users.add(user)
        print(f"  + Added Passenger User: {passenger_email}")
    else:
        print(f"  . Skipped Passenger (exists)")

def seed():
    # Ensure tables exist
    print("Dropping legacy tables if needed...")
    from db_models import PaymentDB
    try:
        PaymentDB.__table__.drop(engine)
        print("  - Dropped payments table")
    except Exception:
        pass

    print("Creating tables if not exist...")
    Base.metadata.create_all(bind=engine)

    session = SessionLocal()
    repos = Repositories(session)
    
    # 🔴 Clear existing data to ensure a fresh start
    print("Clearing existing operational data...")
    from db_models import FlightDB, AnnouncementDB, BookingDB, PaymentDB, TicketDB, FlightSeatDB
    session.query(AnnouncementDB).delete()
    session.query(PaymentDB).delete()
    session.query(TicketDB).delete()
    session.query(BookingDB).delete()
    session.query(FlightSeatDB).delete()
    session.query(FlightDB).delete()
    session.commit()

    try:
        create_airports(repos)
        airplanes = create_airplanes(repos)
        flights = create_flights(repos, airplanes)
        create_announcements(repos, flights)
        create_users(repos)
        print("[SUCCESS] Seeding completed successfully!")
    except Exception as e:
        print(f"[ERROR] Error during seeding: {e}")
        session.rollback()
        raise
    finally:
        session.close()

if __name__ == "__main__":
    seed()
