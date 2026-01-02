from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from db_models import Base, BookingDB, TicketDB

# Connect to DB
engine = create_engine("sqlite:///airline.db")
Session = sessionmaker(bind=engine)
session = Session()

print("\n=== BOOKINGS ===")
bookings = session.query(BookingDB).all()
for b in bookings:
    print(f"Booking: {b.pnr}, Status: {b.status}, Created: {b.created_at}")
    # Inspect tickets manually
    tickets = session.query(TicketDB).filter_by(booking_id=b.id).all()
    print(f"  Tickets (Count: {len(tickets)}):")
    for t in tickets:
        print(f"    - {t.passenger_full_name} (Seat {t.seat_number})")
