import 'package:flutter/material.dart';
import '../core/api/api_service.dart';

class StaffAnnouncementScreen extends StatefulWidget {
  final String flightId;
  const StaffAnnouncementScreen({super.key, required this.flightId});

  @override
  State<StaffAnnouncementScreen> createState() => _StaffAnnouncementScreenState();
}

class _StaffAnnouncementScreenState extends State<StaffAnnouncementScreen> {
  final _api = ApiService();
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _type = 'INFO';
  bool _isSending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    if (_titleCtrl.text.isEmpty || _msgCtrl.text.isEmpty) return;
    
    setState(() => _isSending = true);
    try {
      await _api.adminCreateAnnouncement(
        flightId: widget.flightId,
        title: _titleCtrl.text,
        message: _msgCtrl.text,
        type: _type,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement published!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Announcement')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: 'INFO', child: Text('General Info')),
                  DropdownMenuItem(value: 'DELAY', child: Text('Delay')),
                  DropdownMenuItem(value: 'CANCELLATION', child: Text('Cancellation')),
                  DropdownMenuItem(value: 'GATE_CHANGE', child: Text('Gate Change')),
                  DropdownMenuItem(value: 'BOARDING', child: Text('Boarding')),
                ],
                onChanged: (v) => setState(() => _type = v!),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 16),
              TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 16),
              TextField(controller: _msgCtrl, decoration: const InputDecoration(labelText: 'Message'), maxLines: 3),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _onSend,
                  child: _isSending ? const CircularProgressIndicator() : const Text('SEND ANNOUNCEMENT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
