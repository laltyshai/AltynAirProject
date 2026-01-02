import 'airport.dart';

class Flight {
  final String id;
  final String flightNumber;
  final Airport origin;
  final Airport destination;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final double price;
  final int availableSeats;
  final String status;

  Flight({
    required this.id,
    required this.flightNumber,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    required this.availableSeats,
    required this.status,
  });

  factory Flight.fromJson(Map<String, dynamic> json) {
    return Flight(
      id: json['id'],
      flightNumber: json['flight_number'],
      origin: Airport.fromJson(json['origin']),
      destination: Airport.fromJson(json['destination']),
      departureTime: DateTime.parse(json['departure_time']),
      arrivalTime: DateTime.parse(json['arrival_time']),
      price: (json['price'] as num).toDouble(),
      availableSeats: json['available_seats'],
      status: json['status'],
    );
  }
}
