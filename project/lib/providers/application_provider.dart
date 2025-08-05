import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/application_model.dart';

class ApplicationProvider with ChangeNotifier {
  List<JobApplication> _applications = [];
  bool _isLoading = false;

  List<JobApplication> get applications => _applications;
  bool get isLoading => _isLoading;

  Future<void> loadApplications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final applicationsJson = prefs.getString('applications') ?? '[]';
      _applications = (json.decode(applicationsJson) as List)
          .map((a) => JobApplication.fromJson(a))
          .toList();
    } catch (e) {
      debugPrint('Error loading applications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addApplication(JobApplication application) async {
    try {
      _applications.add(application);
      await _saveApplications();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding application: $e');
    }
  }

  Future<void> updateApplicationStatus(String applicationId, ApplicationStatus status, {String? responseMessage}) async {
    try {
      final index = _applications.indexWhere((a) => a.id == applicationId);
      if (index != -1) {
        _applications[index] = _applications[index].copyWith(
          status: status,
          responseMessage: responseMessage,
          respondedAt: DateTime.now(),
        );
        await _saveApplications();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating application status: $e');
    }
  }

  List<JobApplication> getApplicationsForJob(String jobId) {
    return _applications.where((a) => a.jobId == jobId).toList();
  }

  List<JobApplication> getApplicationsForWorker(String workerId) {
    return _applications.where((a) => a.workerId == workerId).toList();
  }

  bool hasWorkerApplied(String jobId, String workerId) {
    return _applications.any((a) => a.jobId == jobId && a.workerId == workerId);
  }

  Future<void> _saveApplications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('applications', json.encode(_applications.map((a) => a.toJson()).toList()));
  }
}