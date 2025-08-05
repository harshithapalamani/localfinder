import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  List<User> _users = [];
  List<User> _pendingUsers = [];
  bool _isLoading = false;

  List<User> get users => _users;
  List<User> get pendingUsers => _pendingUsers;
  bool get isLoading => _isLoading;

  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users') ?? '[]';
      _users = (json.decode(usersJson) as List)
          .map((u) => User.fromJson(u))
          .toList();

      _pendingUsers = _users.where((u) => u.status == UserStatus.pending).toList();
    } catch (e) {
      debugPrint('Error loading users: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> approveUser(String userId) async {
    try {
      final userIndex = _users.indexWhere((u) => u.id == userId);
      if (userIndex != -1) {
        _users[userIndex] = _users[userIndex].copyWith(
          status: UserStatus.approved,
          approvedAt: DateTime.now(),
        );

        await _saveUsers();
        await loadUsers();
      }
    } catch (e) {
      debugPrint('Error approving user: $e');
    }
  }

  Future<void> rejectUser(String userId) async {
    try {
      final userIndex = _users.indexWhere((u) => u.id == userId);
      if (userIndex != -1) {
        _users[userIndex] = _users[userIndex].copyWith(
          status: UserStatus.rejected,
        );

        await _saveUsers();
        await loadUsers();
      }
    } catch (e) {
      debugPrint('Error rejecting user: $e');
    }
  }

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('users', json.encode(_users.map((u) => u.toJson()).toList()));
  }

  List<User> getWorkersBySkill(String skill) {
    return _users
        .where((u) => 
          u.role == UserRole.worker && 
          u.status == UserStatus.approved &&
          u.skills.contains(skill))
        .toList();
  }
}