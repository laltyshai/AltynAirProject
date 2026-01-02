import 'package:flutter/material.dart';
import '../core/api/api_service.dart';

class StaffBookingDetailsScreen extends StatefulWidget {
  final String flightId;
  const StaffBookingDetailsScreen({super.key, required this.flightId});

  @override
  State<StaffBookingDetailsScreen> createState() => _StaffBookingDetailsScreenState();
}

class _StaffBookingDetailsScreenState extends State<StaffBookingDetailsScreen> {
  final _api = ApiService();
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      _bookings = await _api.adminGetBookings(widget.flightId);
    } catch (e) {
      debugPrint("Load bookings error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      await _api.adminCancelBooking(bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking cancelled')));
        _loadBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cancel failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bookings: ${widget.flightId}')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _bookings.length,
            itemBuilder: (context, index) {
              final b = _bookings[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('PNR: ${b['pnr']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(b['status']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              b['status'],
                              style: TextStyle(color: _getStatusColor(b['status']), fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text('Passenger: ${b['tickets']?[0]?['passenger']?['full_name'] ?? 'N/A'}', style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Text('Tickets: ${b['tickets']?.length ?? 0}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      if (b['status'] == 'CONFIRMED' || b['status'] == 'CREATED') ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _cancelBooking(b['id']),
                            icon: const Icon(Icons.cancel, size: 18),
                            label: const Text('CANCEL BOOKING'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CONFIRMED': return Colors.green;
      case 'CANCELLED': return Colors.red;
      case 'CREATED': return Colors.blue;
      default: return Colors.grey;
    }
  }
}
