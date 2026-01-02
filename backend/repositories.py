

from sqlalchemy.orm import Session

from sqlite_repositories import (
    UserSQLiteRepository,
    PassengerProfileSQLiteRepository,
    AirportSQLiteRepository,
    AirplaneSQLiteRepository,
    FlightSQLiteRepository,
    BookingSQLiteRepository,
    PaymentSQLiteRepository,
    CheckInSQLiteRepository,
    AnnouncementSQLiteRepository,
)

class Repositories:
    def __init__(self, session: Session):
        self.users = UserSQLiteRepository(session)
        self.passenger_profiles = PassengerProfileSQLiteRepository(session)
        self.airports = AirportSQLiteRepository(session)
        self.airplanes = AirplaneSQLiteRepository(session)
        self.flights = FlightSQLiteRepository(session)
        self.bookings = BookingSQLiteRepository(session)
        self.payments = PaymentSQLiteRepository(session)
        self.checkins = CheckInSQLiteRepository(session)
        self.announcements = AnnouncementSQLiteRepository(session)
