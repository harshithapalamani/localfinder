enum JobStatus { open, assigned, inProgress, completed, cancelled }
enum JobPriority { low, medium, high, urgent }

class Job {
  final String id;
  final String title;
  final String description;
  final String employerId;
  final String employerName;
  final List<String> requiredSkills;
  final double? payment;
  final String location;
  final JobStatus status;
  final JobPriority priority;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String? assignedWorkerId;
  final String? assignedWorkerName;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.employerId,
    required this.employerName,
    required this.requiredSkills,
    this.payment,
    required this.location,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.dueDate,
    this.assignedWorkerId,
    this.assignedWorkerName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'employerId': employerId,
      'employerName': employerName,
      'requiredSkills': requiredSkills,
      'payment': payment,
      'location': location,
      'status': status.name,
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'assignedWorkerId': assignedWorkerId,
      'assignedWorkerName': assignedWorkerName,
    };
  }

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      employerId: json['employerId'],
      employerName: json['employerName'],
      requiredSkills: List<String>.from(json['requiredSkills']),
      payment: json['payment']?.toDouble(),
      location: json['location'],
      status: JobStatus.values.firstWhere((e) => e.name == json['status']),
      priority: JobPriority.values.firstWhere((e) => e.name == json['priority']),
      createdAt: DateTime.parse(json['createdAt']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      assignedWorkerId: json['assignedWorkerId'],
      assignedWorkerName: json['assignedWorkerName'],
    );
  }

  Job copyWith({
    String? id,
    String? title,
    String? description,
    String? employerId,
    String? employerName,
    List<String>? requiredSkills,
    double? payment,
    String? location,
    JobStatus? status,
    JobPriority? priority,
    DateTime? createdAt,
    DateTime? dueDate,
    String? assignedWorkerId,
    String? assignedWorkerName,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      employerId: employerId ?? this.employerId,
      employerName: employerName ?? this.employerName,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      payment: payment ?? this.payment,
      location: location ?? this.location,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      assignedWorkerId: assignedWorkerId ?? this.assignedWorkerId,
      assignedWorkerName: assignedWorkerName ?? this.assignedWorkerName,
    );
  }
}