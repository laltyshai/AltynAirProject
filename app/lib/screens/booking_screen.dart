import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import '../models/booking.dart';
import '../providers/booking_provider.dart';
import '../core/api/api_service.dart';

class BookingScreen extends StatefulWidget {
  final String flightId;
  final List<String> selectedSeats;

  const BookingScreen({
    super.key,
    required this.flightId,
    required this.selectedSeats,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Lists of controllers for multiple passengers
  late List<TextEditingController> _nameCtrls;
  late List<TextEditingController> _passportCtrls;
  late List<TextEditingController> _nationalityCtrls;
  late List<DateTime?> _dobs;
  
  String _paymentMethod = 'CARD';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    int count = widget.selectedSeats.length;
    _nameCtrls = List.generate(count, (_) => TextEditingController());
    _passportCtrls = List.generate(count, (_) => TextEditingController());
    _nationalityCtrls = List.generate(count, (_) => TextEditingController());
    _dobs = List.generate(count, (_) => null);
  }

  @override
  void dispose() {
    for (var c in _nameCtrls) c.dispose();
    for (var c in _passportCtrls) c.dispose();
    for (var c in _nationalityCtrls) c.dispose();
    super.dispose();
  }

  void _onConfirm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    
    // Check if any DOB is null
    if (_dobs.contains(null)) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Date of Birth for all passengers')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Build passengers list
      List<Map<String, dynamic>> passengers = [];
      for (int i = 0; i < widget.selectedSeats.length; i++) {
        passengers.add({
          'full_name': _nameCtrls[i].text,
          'passport_number': _passportCtrls[i].text,
          'nationality': _nationalityCtrls[i].text,
          'date_of_birth': _dobs[i]!.toIso8601String().split('T').first,
        });
      }

      final booking = await context.read<BookingProvider>().createBooking(
            flightId: widget.flightId,
            seatNumbers: widget.selectedSeats,
            passengers: passengers,
          );

      // STEP 2: Process Payment
      await ApiService().processPayment(booking.id, _paymentMethod);

      if (mounted) {
        context.read<BookingProvider>().fetchMyBookings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking Confirmed! Returning to Home...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        String message = e.toString().replaceAll('Exception: ', '');
        if (message.contains('Conflict') || message.contains('409') || message.contains('not available')) {
          message = "Oh no! One of these seats was just taken!";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 209, 224, 250), 
      appBar: AppBar(title: const Text('Passenger Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Review Selection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.flight),
                  title: Text('Flight ID: ${widget.flightId}'),
                  subtitle: Text('Seats: ${widget.selectedSeats.join(", ")}'),
                ),
              ),
              const SizedBox(height: 24),
              
              // Dynamic Passenger Forms
              ...List.generate(widget.selectedSeats.length, (index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                      'Passenger ${index + 1} (Seat ${widget.selectedSeats[index]})', 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrls[index],
                      decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passportCtrls[index],
                      decoration: const InputDecoration(labelText: 'Passport Number', border: OutlineInputBorder()),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nationalityCtrls[index],
                      decoration: const InputDecoration(labelText: 'Nationality', border: OutlineInputBorder()),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_dobs[index] == null 
                        ? 'Select Date of Birth' 
                        : "DOB: ${_dobs[index]!.day}.${_dobs[index]!.month}.${_dobs[index]!.year}"),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2000),
                          firstDate: DateTime(1920),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _dobs[index] = picked);
                      },
                    ),
                    const Divider(height: 40, thickness: 2),
                  ],
                );
              }),

              const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'CARD', child: Text('Credit/Debit Card')),
                  DropdownMenuItem(value: 'APPLE_PAY', child: Text('Apple Pay')),
                  DropdownMenuItem(value: 'GOOGLE_PAY', child: Text('Google Pay')),
                ],
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _onConfirm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('PAY & CONFIRM BOOKING', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
