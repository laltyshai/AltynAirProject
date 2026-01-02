import 'package:flutter/material.dart';
import '../models/flight.dart';
import '../core/api/api_service.dart';

class FlightDetailsScreen extends StatefulWidget {
  final Flight flight;

  const FlightDetailsScreen({
    super.key,
    required this.flight,
  });

  @override
  State<FlightDetailsScreen> createState() => _FlightDetailsScreenState();
}

class _FlightDetailsScreenState extends State<FlightDetailsScreen> {
  bool _isCheckingProfile = false;

  String formatDateTime(DateTime dt) {
    return '${dt.day}.${dt.month}.${dt.year} '
           '${dt.hour.toString().padLeft(2, '0')}:'
           '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.flight.arrivalTime.difference(widget.flight.departureTime).inMinutes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flight Details'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/logo.png', height: 32),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Flight Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'FLIGHT ${widget.flight.flightNumber}',
                style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            
            // Route Header
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.flight.origin.code, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    Text(widget.flight.origin.city, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.flight_takeoff, color: Colors.blue),
                      Container(height: 1, color: Colors.blue.shade100, margin: const EdgeInsets.symmetric(horizontal: 10)),
                      Text('$duration min', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(widget.flight.destination.code, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    Text(widget.flight.destination.city, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            
            _InfoRow(label: 'Departure Time', value: formatDateTime(widget.flight.departureTime)),
            _InfoRow(label: 'Arrival Time', value: formatDateTime(widget.flight.arrivalTime)),
            _InfoRow(label: 'Status', value: widget.flight.status.toUpperCase()),
            _InfoRow(label: 'Price', value: '\$${widget.flight.price.toStringAsFixed(2)}'),
            _InfoRow(label: 'Aircraft', value: 'Boeing 737-800'), // Mocked aircraft
            
            const SizedBox(height: 32),
            
            // Note about Profile
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Row(
                children: [
                   Icon(Icons.info_outline, color: Colors.amber, size: 20),
                   SizedBox(width: 8),
                   Expanded(
                    child: Text(
                      'Passenger profile must be completed before booking.',
                      style: TextStyle(fontSize: 12, color: Colors.brown),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCheckingProfile ? null : () async {
                  setState(() => _isCheckingProfile = true);
                  
                  // Requirement Check: Profile must be completed before booking
                  try {
                    final api = ApiService();
                    final profile = await api.getProfile();
                    
                    bool isComplete = profile != null &&
                      (profile['full_name']?.isNotEmpty ?? false) &&
                      (profile['phone']?.isNotEmpty ?? false) &&
                      (profile['passport_number']?.isNotEmpty ?? false) &&
                      (profile['nationality']?.isNotEmpty ?? false) &&
                      (profile['date_of_birth'] != null);

                    if (!isComplete) {
                      setState(() => _isCheckingProfile = false);
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Profile Incomplete'),
                            content: const Text('You must complete your profile (name, phone, passport, etc.) before you can book a flight.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('CLOSE'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/profile');
                                },
                                child: const Text('GO TO PROFILE'),
                              ),
                            ],
                          ),
                        );
                      }
                      return;
                    }

                    if (context.mounted) {
                      setState(() => _isCheckingProfile = false);
                      Navigator.pushNamed(
                        context,
                        '/select-seats',
                        arguments: widget.flight.id,
                      );
                    }
                  } catch (e) {
                    setState(() => _isCheckingProfile = false);
                    if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error checking profile: $e')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isCheckingProfile 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('SELECT SEATS & BOOK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
