enum ApplicationStatus { pending, accepted, rejected }

class JobApplication {
  final String id;
  final String jobId;
  final String workerId;
  final String workerName;
  final String message;
  final DateTime appliedAt;
  final ApplicationStatus status;
  final String? responseMessage;
  final DateTime? respondedAt;

  JobApplication({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.workerName,
    required this.message,
    required this.appliedAt,
    required this.status,
    this.responseMessage,
    this.respondedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'workerId': workerId,
      'workerName': workerName,
      'message': message,
      'appliedAt': appliedAt.toIso8601String(),
      'status': status.name,
      'responseMessage': responseMessage,
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    return JobApplication(
      id: json['id'],
      jobId: json['jobId'],
      workerId: json['workerId'],
      workerName: json['workerName'],
      message: json['message'],
      appliedAt: DateTime.parse(json['appliedAt']),
      status: ApplicationStatus.values.firstWhere((e) => e.name == json['status']),
      responseMessage: json['responseMessage'],
      respondedAt: json['respondedAt'] != null ? DateTime.parse(json['respondedAt']) : null,
    );
  }

  JobApplication copyWith({
    String? id,
    String? jobId,
    String? workerId,
    String? workerName,
    String? message,
    DateTime? appliedAt,
    ApplicationStatus? status,
    String? responseMessage,
    DateTime? respondedAt,
  }) {
    return JobApplication(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      message: message ?? this.message,
      appliedAt: appliedAt ?? this.appliedAt,
      status: status ?? this.status,
      responseMessage: responseMessage ?? this.responseMessage,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}