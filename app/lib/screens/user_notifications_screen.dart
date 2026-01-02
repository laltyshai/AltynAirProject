import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../core/api/api_service.dart';
import 'package:intl/intl.dart';

class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({super.key});

  @override
  State<UserNotificationsScreen> createState() => _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final bookingProvider = context.read<BookingProvider>();
      // Ensure bookings are loaded
      if (bookingProvider.bookings.isEmpty) {
        await bookingProvider.fetchMyBookings();
      }

      final bookings = bookingProvider.bookings;
      
      // Get unique flight IDs to avoid duplicate calls
      final flightIds = bookings.map((b) => b.flightId).toSet().toList();
      
      List<Map<String, dynamic>> allAnnouncements = [];

      for (String flightId in flightIds) {
        try {
          final announcements = await ApiService().getAnnouncements(flightId);
          // Add flight context to each announcement
          final flightInfo = bookings.firstWhere((b) => b.flightId == flightId);
          
          for (var ann in announcements) {
            allAnnouncements.add({
              ...ann,
              'flight_number': flightInfo.flightNumber,
              'origin': flightInfo.originCity,
              'dest': flightInfo.destCity,
            });
          }
        } catch (e) {
          debugPrint("Error fetching announcements for flight $flightId: $e");
        }
      }

      // Sort by newest first (assuming created_at exists, else rely on order)
      // For now, we just reverse to show likely newest first if API returns chronological
      // But ideally backend sorts. Let's sort manually if date string is available.
      allAnnouncements.sort((a, b) {
        final tA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
        final tB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
        return tB.compareTo(tA);
      });

      if (mounted) {
        setState(() {
          _notifications = allAnnouncements;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notifications: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationCard(_notifications[index]);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Flight updates will appear here',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> data) {
    // Determine icon and color based on type
    final type = (data['type'] ?? 'INFO').toString().toUpperCase();
    
    IconData icon = Icons.info_outline;
    Color color = Colors.blue;
    Color bg = Colors.blue.shade50;

    if (type == 'DELAY') {
      icon = Icons.timer_off;
      color = Colors.orange;
      bg = Colors.orange.shade50;
    } else if (type == 'CANCELLATION') {
      icon = Icons.cancel;
      color = Colors.red;
      bg = Colors.red.shade50;
    } else if (type == 'BOARDING') {
      icon = Icons.flight_takeoff;
      color = Colors.green;
      bg = Colors.green.shade50;
    }

    final dateStr = data['created_at'] != null 
      ? DateFormat('MMM d, h:mm a').format(DateTime.parse(data['created_at']).toLocal())
      : '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Expanded(
                         child: Text(
                          data['title'] ?? 'Notification',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                                                 ),
                       ),
                       if (dateStr.isNotEmpty)
                         Text(
                           dateStr,
                           style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                         ),
                     ],
                   ),
                  const SizedBox(height: 4),
                  Text(
                    'Flight ${data['flight_number']} (${data['origin']} → ${data['dest']})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['message'] ?? '',
                    style: TextStyle(color: Colors.grey.shade800, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
