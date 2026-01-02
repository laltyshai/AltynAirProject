import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../models/flight.dart';

class FlightProvider extends ChangeNotifier {
  final _api = ApiService();
  
  List<Flight> _flights = [];
  List<Flight> get flights => _flights;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Future<void> searchFlights({
    required String origin,
    required String destination,
    required DateTime date,
  }) async {
    _loading = true;
    _error = null;
    _flights = [];
    notifyListeners();

    try {
      _flights = await _api.searchFlights(
        origin: origin,
        destination: destination,
        date: date,
      );
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _flights = [];
    _error = null;
    notifyListeners();
  }
}
