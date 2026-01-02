import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/auth/auth_storage.dart';

class AuthProvider extends ChangeNotifier {
  final _api = ApiService();
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _role; // Store user role (PASSENGER or STAFF)
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isStaff => _role == 'STAFF'; // Helper to check permission
  String? get error => _error;

  Future<void> init() async {
    final token = await AuthStorage.getToken();
    if (token != null) {
      _isAuthenticated = true;
      // Background fetch of role to ensure up-to-date permissions
      _fetchRole(); 
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _api.login(email, password);
      _isAuthenticated = true;
      await _fetchRole(); // Fetch role immediately after login
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _api.register(email, password);
      // Automatically login after registration
      await _api.login(email, password);
      _isAuthenticated = true;
      await _fetchRole();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchRole() async {
    try {
      final user = await _api.getUserInfo();
      if (user != null && user.containsKey('role')) {
        _role = user['role'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Failed to fetch role: $e");
    }
  }

  Future<void> logout() async {
    await AuthStorage.clear();
    _isAuthenticated = false;
    _role = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
