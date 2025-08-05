import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/job_model.dart';

class JobProvider with ChangeNotifier {
  List<Job> _jobs = [];
  bool _isLoading = false;

  List<Job> get jobs => _jobs;
  bool get isLoading => _isLoading;

  List<Job> get availableJobs => _jobs.where((j) => j.status == JobStatus.open).toList();
  List<Job> get myJobs => _jobs.where((j) => j.assignedWorkerId != null).toList();

  Future<void> loadJobs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final jobsJson = prefs.getString('jobs') ?? '[]';
      _jobs = (json.decode(jobsJson) as List)
          .map((j) => Job.fromJson(j))
          .toList();
    } catch (e) {
      debugPrint('Error loading jobs: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addJob(Job job) async {
    try {
      _jobs.add(job);
      await _saveJobs();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding job: $e');
    }
  }

  Future<void> assignJob(String jobId, String workerId, String workerName) async {
    try {
      final jobIndex = _jobs.indexWhere((j) => j.id == jobId);
      if (jobIndex != -1) {
        _jobs[jobIndex] = _jobs[jobIndex].copyWith(
          status: JobStatus.assigned,
          assignedWorkerId: workerId,
          assignedWorkerName: workerName,
        );

        await _saveJobs();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error assigning job: $e');
    }
  }

  Future<void> updateJobStatus(String jobId, JobStatus status) async {
    try {
      final jobIndex = _jobs.indexWhere((j) => j.id == jobId);
      if (jobIndex != -1) {
        _jobs[jobIndex] = _jobs[jobIndex].copyWith(status: status);
        await _saveJobs();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating job status: $e');
    }
  }

  Future<void> _saveJobs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jobs', json.encode(_jobs.map((j) => j.toJson()).toList()));
  }

  List<Job> getJobsForWorker(String workerId) {
    return _jobs.where((j) => j.assignedWorkerId == workerId).toList();
  }

  List<Job> getJobsByEmployer(String employerId) {
    return _jobs.where((j) => j.employerId == employerId).toList();
  }
}