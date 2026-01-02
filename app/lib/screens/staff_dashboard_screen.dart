import '../core/api/api_service.dart';
import 'staff_booking_details_screen.dart';
import 'staff_announcement_screen.dart';
import 'all_announcements_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  final _api = ApiService();
  List<dynamic> _flights = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (!auth.isStaff) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access Denied: Authorized Staff Only'),
            backgroundColor: Colors.red,
          ),
        );
        // Use pushReplacement to avoid popping root route if checking fails
        Navigator.of(context).pushReplacementNamed('/'); 
        return;
      }
      _loadAllFlights();
    });
  }

  Future<void> _loadAllFlights() async {
    setState(() => _isLoading = true);
    try {
      _flights = await _api.getAllFlights();
    } catch (e) {
      debugPrint("Staff load error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int index, String newStatus) async {
    final flightId = _flights[index]['id'];
    try {
      await _api.updateFlightStatus(flightId, newStatus);
      setState(() {
        _flights[index]['status'] = newStatus;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Flight $flightId updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 209, 224, 250), 
      appBar: AppBar(
        title: const Text('Operational Dashboard'),
        // backgroundColor: Colors.black87, // Removed to match Home style (light)
        // foregroundColor: Colors.white,
        actions: [
      
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
          IconButton(onPressed: _loadAllFlights, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.shade800, // Matched Home Screen Blue
            width: double.infinity,
            child: Row(
              children: [
                Image.asset('assets/logo.png', height: 20, color: Colors.white), // White logo
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'AUTHORIZED STAFF ONLY - OPERATIONAL MODE',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white), // White text
                  ),
                ),
              ],
            ),
          ),
          // Search PNR removed as per user request
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              "CHOOSE THE FLIGHT",
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 1.2
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final refresh = await Navigator.pushNamed(context, '/staff/create-flight');
                      if (refresh == true) _loadAllFlights();
                    },
                    icon: const Icon(Icons.add_box),
                    label: const Text('CREATE NEW FLIGHT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllAnnouncementsScreen())),
                    icon: const Icon(Icons.list_alt),
                    label: const Text('VIEW ALL ANNOUNCEMENTS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _flights.length,
              itemBuilder: (context, index) {
                final f = _flights[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Flight ID: ${f['id']}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _statusChip(f['status']),
                          ],
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.flight_takeoff, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${f['origin']?['city']} → ${f['destination']?['city']}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.numbers, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('Flight No: ${f['flight_number']}', style: const TextStyle(color: Colors.black87)),
                        ],
                      ),
                      const Divider(height: 32),
                      const Text('OPERATIONAL MANAGEMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StaffBookingDetailsScreen(flightId: f['id']))),
                              icon: const Icon(Icons.people_outline, size: 18),
                              label: const Text('BOOKINGS', style: TextStyle(fontSize: 10)),
                              style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StaffAnnouncementScreen(flightId: f['id']))),
                              icon: const Icon(Icons.notification_add_outlined, size: 18),
                              label: const Text('ANNOUNCE', style: TextStyle(fontSize: 10)),
                              style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('UPDATE STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _actionBtn(index, 'SCHEDULED', Colors.blue),
                          _actionBtn(index, 'DELAYED', Colors.orange),
                          _actionBtn(index, 'CANCELLED', Colors.red),
                          _actionBtn(index, 'LANDED', Colors.green),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color = Colors.blue;
    if (status == 'DELAYED') color = Colors.orange;
    if (status == 'CANCELLED') color = Colors.red;
    if (status == 'LANDED') color = Colors.green;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  Widget _actionBtn(int index, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: OutlinedButton(
        onPressed: () => _updateStatus(index, status),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          side: BorderSide(color: color),
          foregroundColor: color,
        ),
        child: Text(status, style: const TextStyle(fontSize: 10)),
      ),
    );
  }
}
