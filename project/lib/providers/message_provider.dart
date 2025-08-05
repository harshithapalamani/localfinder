import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/message_model.dart';

class MessageProvider with ChangeNotifier {
  List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> loadMessages() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString('messages') ?? '[]';
      _messages = (json.decode(messagesJson) as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList();
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(ChatMessage message) async {
    try {
      _messages.add(message);
      await _saveMessages();
      notifyListeners();
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  List<ChatMessage> getJobMessages(String jobId) {
    return _messages.where((m) => m.jobId == jobId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> markMessagesAsRead(String jobId, String userId) async {
    try {
      bool hasChanges = false;
      for (int i = 0; i < _messages.length; i++) {
        if (_messages[i].jobId == jobId && 
            _messages[i].senderId != userId && 
            !_messages[i].isRead) {
          _messages[i] = _messages[i].copyWith(isRead: true);
          hasChanges = true;
        }
      }
      
      if (hasChanges) {
        await _saveMessages();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  int getUnreadMessageCount(String jobId, String userId) {
    return _messages.where((m) => 
      m.jobId == jobId && 
      m.senderId != userId && 
      !m.isRead
    ).length;
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('messages', json.encode(_messages.map((m) => m.toJson()).toList()));
  }
}