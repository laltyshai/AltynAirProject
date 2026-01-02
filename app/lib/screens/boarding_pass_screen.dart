import 'package:flutter/material.dart';
// import '../core/api/api_service.dart';

class BoardingPassScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const BoardingPassScreen({super.key, required this.bookingData});

  @override
  State<BoardingPassScreen> createState() => _BoardingPassScreenState();
}

class _BoardingPassScreenState extends State<BoardingPassScreen> {
  bool _isCheckingIn = false;
  bool _checkedIn = false;
  String? _error;
  Map<String, dynamic>? _checkInData;

  Future<void> _performCheckIn() async {
    // Feature disabled as per user request
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Check-in system is currently under maintenance.'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      appBar: AppBar(
        title: const Text('Boarding Pass', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/logo.png', height: 24),
                    Text(widget.bookingData['flightId'] ?? 'KC101', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 32),
                
                // Passenger Info
                _PassRow(label: 'PASSENGER', value: widget.bookingData['passengerName'] ?? 'John Doe'),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _PassItem(label: 'DATE', value: '05 JAN 2026'),
                    _PassItem(label: 'GATE', value: _checkInData?['gate'] ?? 'TBD'),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _PassItem(label: 'SEAT', value: (widget.bookingData['seats'] as List?)?.join(", ") ?? '12A'),
                    _PassItem(label: 'BOARDING', value: _checkInData != null ? '14:00' : 'TBD'),
                  ],
                ),
                
                const SizedBox(height: 32),

                if (!_checkedIn) ...[
                  if (_error != null) 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12), textAlign: TextAlign.center),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isCheckingIn ? null : _performCheckIn,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
                      child: _isCheckingIn 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('ACTIVATE BOARDING PASS (CHECK-IN)'),
                    ),
                  ),
                ] else ...[
                  // QR Section (Only visible after check-in)
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_2, size: 70),
                        Text('PNR: ${widget.bookingData['pnr']}', style: const TextStyle(fontSize: 10, letterSpacing: 2)),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                const Text(
                  'Note: Check-in is available 24h to 1h before departure.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PassRow extends StatelessWidget {
  final String label;
  final String value;
  const _PassRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _PassItem extends StatelessWidget {
  final String label;
  final String value;
  const _PassItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
