import 'package:flutter/material.dart';
import '../../core/api/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passportCtrl = TextEditingController();
  final _nationalityCtrl = TextEditingController();
  DateTime? _dateOfBirth;
  bool _loading = false;
  bool _fetching = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final api = ApiService();
      final profile = await api.getProfile();
      if (profile != null) {
        setState(() {
          _fullNameCtrl.text = profile['full_name'] ?? '';
          _phoneCtrl.text = profile['phone'] ?? '';
          _passportCtrl.text = profile['passport_number'] ?? '';
          _nationalityCtrl.text = profile['nationality'] ?? '';
          if (profile['date_of_birth'] != null) {
            _dateOfBirth = DateTime.parse(profile['date_of_birth']);
          }
        });
      }
    } catch (e) {
      debugPrint("Profile load error: $e");
    } finally {
      setState(() => _fetching = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and pick a birth date')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final api = ApiService();
      await api.createOrUpdateProfile(
        fullName: _fullNameCtrl.text,
        phone: _phoneCtrl.text,
        passportNumber: _passportCtrl.text,
        nationality: _nationalityCtrl.text,
        dateOfBirth: _dateOfBirth!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fetching) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
       backgroundColor: const Color.fromARGB(255, 209, 224, 250), 
      appBar: AppBar(title: const Text('My Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _fullNameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passportCtrl,
              decoration: const InputDecoration(labelText: 'Passport Number'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nationalityCtrl,
              decoration: const InputDecoration(labelText: 'Nationality'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(_dateOfBirth == null
                  ? 'Select Date of Birth'
                  : "Born: ${_dateOfBirth!.toIso8601String().split('T').first}"),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dateOfBirth ?? DateTime(2000),
                  firstDate: DateTime(1920),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _dateOfBirth = date);
                }
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _saveProfile,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('SAVE PROFILE'),
            ),
          ],
        ),
      ),
    );
  }
}
