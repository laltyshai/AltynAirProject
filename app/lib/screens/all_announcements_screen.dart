import 'package:flutter/material.dart';
import '../core/api/api_service.dart';

class AllAnnouncementsScreen extends StatefulWidget {
  const AllAnnouncementsScreen({super.key});

  @override
  State<AllAnnouncementsScreen> createState() => _AllAnnouncementsScreenState();
}

class _AllAnnouncementsScreenState extends State<AllAnnouncementsScreen> {
  final _api = ApiService();
  List<dynamic> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      final data = await _api.adminGetAllAnnouncements();
      setState(() {
        _announcements = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 209, 224, 250),
      appBar: AppBar(title: const Text('All Announcements')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
              ? const Center(child: Text('No announcements found', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _announcements.length,
                  itemBuilder: (context, index) {
                    final item = _announcements[index];
                    final date = DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now();
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Chip(
                                  label: Text(item['type'] ?? 'INFO', style: const TextStyle(fontSize: 10, color: Colors.white)),
                                  backgroundColor: Colors.blueGrey,
                                  visualDensity: VisualDensity.compact,
                                ),
                                Text(
                                  "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2,'0')}",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text("Flight: ${item['flight_id']}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                            const SizedBox(height: 4),
                            Text(item['title'] ?? 'No Title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(item['message'] ?? '', style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
