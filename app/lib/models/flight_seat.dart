enum SeatCategory { standard, extraLegroom }
enum SeatStatus { available, occupied, selected }

class FlightSeat {
  final String seatNumber;
  final SeatCategory category;
  SeatStatus status;

  FlightSeat({
    required this.seatNumber,
    required this.category,
    this.status = SeatStatus.available,
  });
}
