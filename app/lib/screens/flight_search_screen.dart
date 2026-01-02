import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/flight_provider.dart';
import '../models/flight.dart';
import 'flight_details_screen.dart';

class FlightSearchScreen extends StatefulWidget {
  const FlightSearchScreen({super.key});

  @override
  State<FlightSearchScreen> createState() => _FlightSearchScreenState();
}

class _FlightSearchScreenState extends State<FlightSearchScreen> {
  String? _selectedOrigin;
  String? _selectedDestination;
  DateTime? _date;

  final List<Map<String, String>> _airports = [
    {'code': 'IST', 'name': 'Istanbul (IST)'},
    {'code': 'JFK', 'name': 'New York (JFK)'},
    {'code': 'LHR', 'name': 'London (LHR)'},
    {'code': 'CDG', 'name': 'Paris (CDG)'},
    {'code': 'DXB', 'name': 'Dubai (DXB)'},
    {'code': 'AMS', 'name': 'Amsterdam (AMS)'},
    {'code': 'ALA', 'name': 'Almaty (ALA)'},
    {'code': 'TSE', 'name': 'Astana (TSE)'},
  ];

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _search(BuildContext context) {
    if (_selectedOrigin == null ||
        _selectedDestination == null ||
        _date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields')),
      );
      return;
    }

    if (_selectedOrigin == _selectedDestination) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Origin and Destination must be different')),
      );
      return;
    }

    context.read<FlightProvider>().searchFlights(
          origin: _selectedOrigin!,
          destination: _selectedDestination!,
          date: _date!,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: const Color.fromARGB(255, 209, 224, 250), 
        appBar: AppBar(
          title: const Text('Search Flights'),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/logo.png', height: 32),
            ),
          ],
        ),
        body: Consumer<FlightProvider>(
          builder: (context, provider, _) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedOrigin,
                    decoration: const InputDecoration(labelText: 'From (Origin)'),
                    items: _airports.map((a) {
                      return DropdownMenuItem(
                        value: a['code'],
                        child: Text(a['name']!),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedOrigin = val),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedDestination,
                    decoration: const InputDecoration(labelText: 'To (Destination)'),
                    items: _airports.map((a) {
                      return DropdownMenuItem(
                        value: a['code'],
                        child: Text(a['name']!),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedDestination = val),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _date == null
                          ? 'Select Date'
                          : 'Departure Date: ${_date!.day}.${_date!.month}.${_date!.year}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _pickDate(context),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.loading ? null : () => _search(context),
                      child: provider.loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('SEARCH FLIGHTS'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  Expanded(
                    child: _buildResults(provider),
                  ),
                ],
              ),
            );
          },
        ),
    );
  }

  Widget _buildResults(FlightProvider provider) {
    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Text(
          provider.error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (provider.flights.isEmpty) {
      return const Center(child: Text('No flights found. Try different cities.'));
    }

    return ListView.builder(
      itemCount: provider.flights.length,
      itemBuilder: (context, index) {
        final flight = provider.flights[index];
        return _FlightTile(flight: flight);
      },
    );
  }
}

class _FlightTile extends StatelessWidget {
  final Flight flight;

  const _FlightTile({required this.flight});

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, "0")}:${dt.minute.toString().padLeft(2, "0")}';
  }

  @override
  Widget build(BuildContext context) {
    final duration = flight.arrivalTime.difference(flight.departureTime).inMinutes;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FlightDetailsScreen(flight: flight),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Flight ${flight.flightNumber}',
                    style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      flight.status.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatTime(flight.departureTime), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(flight.origin.code, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(Icons.flight_takeoff, size: 16, color: Colors.grey),
                        Container(height: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 8)),
                        Text(_formatDuration(duration), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_formatTime(flight.arrivalTime), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(flight.destination.code, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${flight.availableSeats} seats left', style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w500)),
                  Text('\$${flight.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
