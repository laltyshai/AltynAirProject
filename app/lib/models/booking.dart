class Booking {
  final String id;
  final String flightId;
  final String pnr;
  final String passengerName;
  final List<String> seatNumbers;
  final List<String> ticketIds;
  final String flightNumber;
  final String originCity;
  final String destCity;
  final String status;
  final DateTime? bookingDate;

  Booking({
    required this.id,
    required this.flightId,
    required this.pnr,
    required this.passengerName,
    required this.seatNumbers,
    required this.ticketIds,
    required this.flightNumber,
    required this.originCity,
    required this.destCity,
    required this.status,
    this.bookingDate,
  });
}
