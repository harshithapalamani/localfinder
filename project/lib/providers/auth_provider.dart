import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  Future<void> initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      
      if (userJson != null) {
        _currentUser = User.fromJson(json.decode(userJson));
        _isAuthenticated = true;
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users') ?? '[]';
      final passwordsJson = prefs.getString('passwords') ?? '{}';
      
      final users = (json.decode(usersJson) as List)
          .map((u) => User.fromJson(u))
          .toList();
      final passwords = json.decode(passwordsJson) as Map<String, dynamic>;

      final user = users.firstWhere(
        (u) => u.email == email,
        orElse: () => throw Exception('User not found'),
      );

      // Check password
      final storedPassword = passwords[user.id];
      if (storedPassword != password) {
        throw Exception('Invalid password');
      }

      // Allow login for all users (including pending) so they can check status
      _currentUser = user;
      _isAuthenticated = true;
      await prefs.setString('current_user', json.encode(user.toJson()));
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> register(User user, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users') ?? '[]';
      final passwordsJson = prefs.getString('passwords') ?? '{}';
      
      final users = (json.decode(usersJson) as List)
          .map((u) => User.fromJson(u))
          .toList();
      final passwords = json.decode(passwordsJson) as Map<String, dynamic>;

      // Check if user already exists
      if (users.any((u) => u.email == user.email)) {
        throw Exception('User already exists');
      }

      // Add user and password
      users.add(user);
      passwords[user.id] = password;
      
      await prefs.setString('users', json.encode(users.map((u) => u.toJson()).toList()));
      await prefs.setString('passwords', json.encode(passwords));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Registration error: $e');
      return false;
    }
  }

  Future<void> updateCurrentUser(User user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', json.encode(user.toJson()));
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> createDefaultAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users') ?? '[]';
    final passwordsJson = prefs.getString('passwords') ?? '{}';
    
    final users = (json.decode(usersJson) as List)
        .map((u) => User.fromJson(u))
        .toList();
    final passwords = json.decode(passwordsJson) as Map<String, dynamic>;

    if (!users.any((u) => u.role == UserRole.admin)) {
      final admin = User(
        id: 'admin-001',
        name: 'Village Head',
        email: 'admin@village.com',
        phone: '+1234567890',
        village: 'Main Village',
        role: UserRole.admin,
        status: UserStatus.approved,
        skills: ['Administration', 'Management'],
        description: 'Village Head and Administrator',
        createdAt: DateTime.now(),
        approvedAt: DateTime.now(),
      );

      users.add(admin);
      passwords[admin.id] = 'admin123';
      
      await prefs.setString('users', json.encode(users.map((u) => u.toJson()).toList()));
      await prefs.setString('passwords', json.encode(passwords));
    }
  }
}