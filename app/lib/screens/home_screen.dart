import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../models/booking.dart';
import '../core/api/api_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _announcement = 'All systems operational. Flight information is live.';
  
  @override
  void initState() {
    super.initState();
    // Load bookings on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialLoad();
    });
  }

  Future<void> _initialLoad() async {
    await context.read<BookingProvider>().fetchMyBookings();
    _fetchRelevantAnnouncement();
  }

  Future<void> _fetchRelevantAnnouncement() async {
    final bookings = context.read<BookingProvider>().bookings;
    final confirmed = bookings.where((b) => b.status == 'CONFIRMED').toList();
    
    if (confirmed.isEmpty) return;

    List<Map<String, dynamic>> all = [];

    for (var b in confirmed) {
      try {
        final anns = await ApiService().getAnnouncements(b.flightNumber);
        all.addAll(anns.cast<Map<String, dynamic>>());
      } catch (e) {
        debugPrint("Error fetching announcements: $e");
      }
    }

    if (all.isNotEmpty) {
      // Sort by latest (assuming API returns chronological, we take the last one or sort manually)
      // Since API is simple, let's just take the last element added if we trust the order, 
      // or simplistic sort:
      // all.sort((a, b) => ...); 
      // For now, simple approach:
      final latest = all.last; 
      if (mounted) {
        setState(() {
          _announcement = "${latest['title']}: ${latest['message']}";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final bookings = bookingProvider.bookings;

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('AITS Airline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<BookingProvider>().fetchMyBookings();
          _fetchRelevantAnnouncement();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(context),
              _buildAnnouncementsSection(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('My Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (bookingProvider.isLoading)
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
              ),
              if (bookings.isEmpty && !bookingProvider.isLoading)
                _buildEmptyBookings()
              else
                _buildBookingsList(context, bookings),
              _buildStaffPortalLink(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/search'),
        icon: const Icon(Icons.add),
        label: const Text('NEW BOOKING'),
      ),
    );
  }


Widget _buildWelcomeHeader(BuildContext context) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.blue.shade800,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /// ⬅️ ЛЕВАЯ КОЛОНКА — ТЕКСТЫ + КНОПКА
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome to \nAltyn Air!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your gateway to the world.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade800,
                ),
                child: const Text('MY PROFILE'),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        /// ➡️ ПРАВАЯ КОЛОНКА — КАРТИНКА
        Image.asset(
          'assets/logo.png',
          height: 140,
          width: 140,
          fit: BoxFit.contain,
        ),
      ],
    ),
  );
}



  Widget _buildAnnouncementsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Flight Updates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/notifications'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50, 
                borderRadius: BorderRadius.circular(12), 
                border: Border.all(color: Colors.orange.shade100)
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _announcement,
                      style: const TextStyle(fontSize: 13, color: Colors.brown, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.orange),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

    Future<void> _retryPayment(BuildContext context, Booking booking) async {
      try {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Processing payment...")));
        await ApiService().processPayment(booking.id, 'CARD');
        
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Successful! Flight Confirmed."), backgroundColor: Colors.green));
           context.read<BookingProvider>().fetchMyBookings();
        }
      } catch (e) {
         if (context.mounted) {
            String msg = e.toString().replaceAll("Exception:", "").trim();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment Failed: $msg"), backgroundColor: Colors.red));
         }
      }
    }

  Widget _buildBookingsList(BuildContext context, List<Booking> bookings) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final b = bookings[index];
        final bool isConfirmed = b.status == 'CONFIRMED';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          elevation: 2,
          child: ExpansionTile(
            leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.flight, color: Colors.white, size: 20)),
            title: Text('${b.originCity} → ${b.destCity}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Flight: ${b.flightNumber} • PNR: ${b.pnr}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Passenger: ${b.passengerName}', style: const TextStyle(fontSize: 14)),
                        _buildStatusChip(b.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Seats: ${b.seatNumbers.join(", ")}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    const Divider(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isConfirmed 
                              ? () {
                                  Navigator.pushNamed(context, '/boarding-pass', arguments: {
                                    'pnr': b.pnr,
                                    'flightId': b.flightNumber,
                                    'passengerName': b.passengerName,
                                    'seats': b.seatNumbers,
                                    'ticketId': b.ticketIds.isNotEmpty ? b.ticketIds[0] : null,
                                  });
                                } 
                              : (b.status == 'CREATED' ? () => _retryPayment(context, b) : null),
                          icon: Icon(isConfirmed ? Icons.qr_code : (b.status == 'CREATED' ? Icons.payment : Icons.access_time)),
                          label: Text(isConfirmed 
                              ? 'CHECK-IN / BOARDING PASS' 
                              : (b.status == 'CREATED' ? 'PAY NOW (RETRY)' : 'CANCELLED')
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isConfirmed 
                                ? Colors.blue.shade800 
                                : (b.status == 'CREATED' ? Colors.orange.shade700 : Colors.grey),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],                ),
              ),            ],          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.blue;
    if (status == 'CONFIRMED') color = Colors.green;
    if (status == 'CANCELLED') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildEmptyBookings() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.airplane_ticket_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No trips found. Time to explore?', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffPortalLink(BuildContext context) {
    // Only show for STAFF
    final auth = context.watch<AuthProvider>();
    if (!auth.isStaff) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/staff'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
          child: const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.grey),
              SizedBox(width: 12),
              Text('STAFF PORTAL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              Spacer(),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
