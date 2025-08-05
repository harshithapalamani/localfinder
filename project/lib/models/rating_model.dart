class Rating {
  final String id;
  final String jobId;
  final String customerId;
  final String workerId;
  final int rating; // 1-5 stars
  final String? review;
  final DateTime createdAt;

  Rating({
    required this.id,
    required this.jobId,
    required this.customerId,
    required this.workerId,
    required this.rating,
    this.review,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'customerId': customerId,
      'workerId': workerId,
      'rating': rating,
      'review': review,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'],
      jobId: json['jobId'],
      customerId: json['customerId'],
      workerId: json['workerId'],
      rating: json['rating'],
      review: json['review'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}