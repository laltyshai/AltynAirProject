import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import 'package:intl/intl.dart';

class StaffCreateFlightScreen extends StatefulWidget {
  const StaffCreateFlightScreen({super.key});

  @override
  State<StaffCreateFlightScreen> createState() => _StaffCreateFlightScreenState();
}

class _StaffCreateFlightScreenState extends State<StaffCreateFlightScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  final _flightNumberController = TextEditingController();
  final _priceController = TextEditingController();

  String? _originCode;
  String? _destinationCode;
  String? _airplaneId;

  DateTime? _departureDate;
  TimeOfDay? _departureTime;
  DateTime? _arrivalDate;
  TimeOfDay? _arrivalTime;

  bool _isLoading = false;

  final List<Map<String, String>> _airports = [
    {'code': 'ALA', 'city': 'Almaty'},
    {'code': 'TSE', 'city': 'Astana'},
    {'code': 'IST', 'city': 'Istanbul'},
    {'code': 'JFK', 'city': 'New York'},
    {'code': 'LHR', 'city': 'London'},
    {'code': 'CDG', 'city': 'Paris'},
    {'code': 'DXB', 'city': 'Dubai'},
    {'code': 'AMS', 'city': 'Amsterdam'},
  ];

  final List<Map<String, String>> _airplanes = [
    {'id': 'plane_b737_001', 'model': 'Boeing 737-800'},
    {'id': 'plane_a320_001', 'model': 'Airbus A320'},
  ];

  @override
  void dispose() {
    _flightNumberController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isDeparture) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      if (isDeparture) {
        _departureDate = date;
        _departureTime = time;
      } else {
        _arrivalDate = date;
        _arrivalTime = time;
      }
    });
  }

  DateTime? _combine(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final dep = _combine(_departureDate, _departureTime);
    final arr = _combine(_arrivalDate, _arrivalTime);

    if (dep == null || arr == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Date and Time')));
      return;
    }

    if (arr.isBefore(dep)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Arrival must be after departure')));
      return;
    }

    if (_originCode == null || _destinationCode == null || _airplaneId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select airports and airplane')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _api.adminCreateFlight(
        flightNumber: _flightNumberController.text.toUpperCase(),
        originCode: _originCode!,
        destinationCode: _destinationCode!,
        departureTime: dep,
        arrivalTime: arr,
        airplaneId: _airplaneId!,
        price: double.parse(_priceController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flight created successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Flight')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _flightNumberController,
                    decoration: const InputDecoration(labelText: 'Flight Number (e.g. KC123)', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Origin Airport', border: OutlineInputBorder()),
                    items: _airports.map((a) => DropdownMenuItem(value: a['code'], child: Text('${a['city']} (${a['code']})'))).toList(),
                    onChanged: (v) => setState(() => _originCode = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Destination Airport', border: OutlineInputBorder()),
                    items: _airports.map((a) => DropdownMenuItem(value: a['code'], child: Text('${a['city']} (${a['code']})'))).toList(),
                    onChanged: (v) => setState(() => _destinationCode = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Airplane Model', border: OutlineInputBorder()),
                    items: _airplanes.map((a) => DropdownMenuItem(value: a['id'], child: Text(a['model']!))).toList(),
                    onChanged: (v) => setState(() => _airplaneId = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDateTime(true),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_departureDate == null ? 'Set Departure' : DateFormat('MMM d, HH:mm').format(_combine(_departureDate, _departureTime)!)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDateTime(false),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_arrivalDate == null ? 'Set Arrival' : DateFormat('MMM d, HH:mm').format(_combine(_arrivalDate, _arrivalTime)!)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Base Price (USD)', border: OutlineInputBorder(), prefixText: ''),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
                      child: const Text('CREATE FLIGHT', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
