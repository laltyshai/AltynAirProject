import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../auth/auth_storage.dart';
import '../../models/flight.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await AuthStorage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  void _handleError(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      throw Exception(body['detail'] ?? res.body);
    } catch (_) {
      throw Exception(res.body);
    }
  }

  // --- AUTH ---
  Future<void> register(String email, String password) async {
    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/auth/register'),
      headers: await _headers(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (res.statusCode != 200) {
      _handleError(res);
    }
  }

  Future<void> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': email,
        'password': password,
      },
    );

    if (res.statusCode != 200) {
      _handleError(res);
    }

    final data = jsonDecode(res.body);
    await AuthStorage.saveToken(data['access_token']);
  }

  Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/auth/me'),
        headers: await _headers(auth: true),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching user info: $e");
      return null;
    }
  }

  // --- PROFILE ---
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/profile'),
        headers: await _headers(auth: true),
      );

      if (res.statusCode == 404) return null;
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      _handleError(res);
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<void> createOrUpdateProfile({
    required String fullName,
    required String phone,
    required String passportNumber,
    required String nationality,
    required DateTime dateOfBirth,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/profile'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'full_name': fullName,
        'phone': phone,
        'passport_number': passportNumber,
        'nationality': nationality,
        'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
      }),
    );

    if (res.statusCode != 200) {
      _handleError(res);
    }
  }

  // --- FLIGHTS ---
  Future<List<Flight>> searchFlights({
    required String origin,
    required String destination,
    required DateTime date,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/flights/search'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'origin': origin,
        'destination': destination,
        'departure_date': date.toIso8601String().split('T').first,
      }),
    );

    if (response.statusCode != 200) {
      _handleError(response);
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => Flight.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getFlightSeats(String flightId) async {
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/flights/$flightId/seats'),
      headers: await _headers(auth: true),
    );

    if (res.statusCode != 200) {
      _handleError(res);
    }
    return jsonDecode(res.body);
  }

  // --- BOOKINGS ---
  Future<Map<String, dynamic>> createBooking({
    required String flightId,
    required List<String> seatNumbers,
    required List<Map<String, dynamic>> passengers,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/bookings'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'flight_id': flightId,
        'seat_numbers': seatNumbers,
        'passengers': passengers,
      }),
    );

    if (res.statusCode != 200) {
      _handleError(res);
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> processPayment(String bookingId, String method) async {
    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/payments'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'booking_id': bookingId,
        'method': method,
      }),
    );

    if (res.statusCode != 200) {
      _handleError(res);
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> checkIn(String ticketId) async {
    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/check-in/$ticketId'),
      headers: await _headers(auth: true),
    );

    if (res.statusCode != 200) {
      _handleError(res);
    }
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getMyBookings() async {
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/bookings'),
      headers: await _headers(auth: true),
    );

    if (res.statusCode != 200) {
      _handleError(res);
    }
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getAnnouncements(String flightId) async {
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/announcements/$flightId'),
      headers: await _headers(auth: true),
    );

    if (res.statusCode != 200) {
      _handleError(res);
    }
    return jsonDecode(res.body);
  }

  // --- STAFF ---
  Future<List<dynamic>> getAllFlights() async {
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/admin/flights'),
      headers: await _headers(auth: true),
    );

    if (res.statusCode != 200) {
      _handleError(res);
    }
    return jsonDecode(res.body);
  }

  Future<void> updateFlightStatus(String flightId, String status) async {
    final res = await http.patch(
      Uri.parse('${AppConfig.baseUrl}/admin/flights/$flightId?status=$status'),
      headers: await _headers(auth: true),
    );

    if (res.statusCode != 200) {
      _handleError(res);
    }
  }

  // === STAFF / ADMIN METHODS ===

  Future<List<dynamic>> adminGetBookings(String flightId) async {
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/admin/bookings/flight/$flightId'),
      headers: await _headers(auth: true),
    );

    if (res.statusCode != 200) {
      _handleError(res);
    }
    return jsonDecode(res.body);
  }

  Future<void> adminCancelBooking(String bookingId) async {
    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/admin/bookings/$bookingId/cancel'),
      headers: await _headers(auth: true),
    );

    if (res.statusCode != 200) {
      _handleError(res);
    }
  }

  Future<void> adminCreateAnnouncement({
    required String flightId,
    required String title,
    required String message,
    required String type,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/admin/announcements'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'flight_id': flightId,
        'title': title,
        'message': message,
        'type': type,
      }),
    );

    if (res.statusCode != 200) {
      _handleError(res);
    }
  }

  Future<Map<String, dynamic>> adminGetBookingByPNR(String pnr) async {
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/bookings/$pnr'),
      headers: await _headers(auth: true),
    );

    if (res.statusCode != 200) {
      _handleError(res);
    }
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> adminGetAllAnnouncements() async {
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/admin/announcements'),
      headers: await _headers(auth: true),
    );

    if (res.statusCode != 200) {
      _handleError(res);
    }
    return jsonDecode(res.body);
  }
  Future<void> adminCreateFlight({
    required String flightNumber,
    required String originCode,
    required String destinationCode,
    required DateTime departureTime,
    required DateTime arrivalTime,
    required String airplaneId,
    required double price,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/admin/flights'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'flight_number': flightNumber,
        'origin_code': originCode,
        'destination_code': destinationCode,
        'departure_time': departureTime.toIso8601String(),
        'arrival_time': arrivalTime.toIso8601String(),
        'airplane_id': airplaneId,
        'price': price,
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      _handleError(res);
    }
  }
}
