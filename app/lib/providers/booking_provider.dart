import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../models/booking.dart';

class BookingProvider extends ChangeNotifier {
  final _api = ApiService();
  
  List<Booking> _bookings = [];
  List<Booking> get bookings => List.unmodifiable(_bookings);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchMyBookings() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final data = await _api.getMyBookings();
      _bookings = data.map((b) => Booking(
        id: b['id'],
        flightId: b['flight_id'],
        pnr: b['pnr'],
        passengerName: (b['tickets'] as List).isNotEmpty 
            ? (b['tickets'] as List).map((t) => t['passenger_name'].toString()).join(', ')
            : 'N/A',
        seatNumbers: (b['tickets'] as List?)?.map((t) => t['seat_number'].toString()).toList() ?? [],
        ticketIds: (b['tickets'] as List?)?.map((t) => t['id'].toString()).toList() ?? [],
        flightNumber: b['flight_number'] ?? 'N/A',
        originCity: b['origin_city'] ?? 'N/A',
        destCity: b['dest_city'] ?? 'N/A',
        status: b['status'] ?? 'CREATED',
        bookingDate: b['created_at'] != null ? DateTime.parse(b['created_at']) : null,
      )).toList();
    } catch (e) {
      debugPrint("Fetch bookings error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Booking> createBooking({
    required String flightId,
    required List<String> seatNumbers,
    required List<Map<String, dynamic>> passengers,
  }) async {
    final result = await _api.createBooking(
      flightId: flightId,
      seatNumbers: seatNumbers,
      passengers: passengers,
    );
    
    final newBooking = Booking(
      id: result['id'],
      flightId: result['flight_id'],
      pnr: result['pnr'],
      passengerName: passengers.isNotEmpty 
          ? passengers.map((p) => p['full_name']).join(', ') 
          : 'Unknown',
      seatNumbers: seatNumbers,
      ticketIds: (result['tickets'] as List?)?.map((t) => t['id'].toString()).toList() ?? [],
      flightNumber: result['flight_number'] ?? 'N/A',
      originCity: result['origin_city'] ?? 'N/A',
      destCity: result['dest_city'] ?? 'N/A',
      status: result['status'] ?? 'CREATED',
      bookingDate: DateTime.now(),
    );
    
    _bookings.insert(0, newBooking);
    notifyListeners();
    return newBooking;
  }
}
