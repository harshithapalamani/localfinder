import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/application_provider.dart';
import '../../providers/rating_provider.dart';
import '../../models/job_model.dart';
import '../../models/application_model.dart';
import '../../models/rating_model.dart';
import '../auth/login_screen.dart';
import '../shared/job_chat_screen.dart';

class EmployerDashboard extends StatefulWidget {
  const EmployerDashboard({super.key});

  @override
  State<EmployerDashboard> createState() => _EmployerDashboardState();
}

class _EmployerDashboardState extends State<EmployerDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JobProvider>(context, listen: false).loadJobs();
      Provider.of<UserProvider>(context, listen: false).loadUsers();
      Provider.of<ApplicationProvider>(context, listen: false).loadApplications();
      Provider.of<RatingProvider>(context, listen: false).loadRatings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Panel'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildMyJobsTab(),
          _buildPostJobTab(),
          _buildJobHistoryTab(),
          _buildWorkersTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'My Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Post Job',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Workers',
          ),
        ],
      ),
    );
  }

  Widget _buildMyJobsTab() {
    return Consumer2<JobProvider, ApplicationProvider>(
      builder: (context, jobProvider, applicationProvider, child) {
        final user = Provider.of<AuthProvider>(context).currentUser!;
        final myJobs = jobProvider.getJobsByEmployer(user.id)
            .where((job) => job.status != JobStatus.completed)
            .toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'My Active Jobs',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${myJobs.length} jobs',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: myJobs.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No active jobs',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'Post your first job to get started',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: myJobs.length,
                      itemBuilder: (context, index) {
                        final job = myJobs[index];
                        final applications = applicationProvider.getApplicationsForJob(job.id);
                        return _buildJobCard(job, applications);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildJobCard(Job job, List<JobApplication> applications) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(job.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              job.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            if (job.assignedWorkerName != null) ...[
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Assigned to: ${job.assignedWorkerName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  job.location,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                if (job.payment != null) ...[
                  const Icon(Icons.monetization_on, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '\$${job.payment!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: job.requiredSkills.map((skill) {
                return Chip(
                  label: Text(skill),
                  backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
                  labelStyle: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (job.status == JobStatus.open && applications.isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _viewApplications(job, applications),
                      icon: const Icon(Icons.visibility),
                      label: Text('View Applications (${applications.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (job.status == JobStatus.open && applications.isEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _assignJob(job),
                      icon: const Icon(Icons.assignment_ind),
                      label: const Text('Assign Worker'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (job.status == JobStatus.assigned || job.status == JobStatus.inProgress) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openJobChat(job),
                      icon: const Icon(Icons.chat),
                      label: const Text('Chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (job.status == JobStatus.inProgress)
                    ElevatedButton.icon(
                      onPressed: () => _markJobCompleted(job),
                      icon: const Icon(Icons.check),
                      label: const Text('Mark Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(JobStatus status) {
    Color color;
    switch (status) {
      case JobStatus.open:
        color = Colors.blue;
        break;
      case JobStatus.assigned:
        color = Colors.orange;
        break;
      case JobStatus.inProgress:
        color = Colors.purple;
        break;
      case JobStatus.completed:
        color = Colors.green;
        break;
      case JobStatus.cancelled:
        color = Colors.red;
        break;
    }

    return Chip(
      label: Text(
        status.name.toUpperCase(),
        style: const TextStyle(fontSize: 10),
      ),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
    );
  }

  Widget _buildPostJobTab() {
    return const _PostJobForm();
  }

  Widget _buildJobHistoryTab() {
    return Consumer2<JobProvider, RatingProvider>(
      builder: (context, jobProvider, ratingProvider, child) {
        final user = Provider.of<AuthProvider>(context).currentUser!;
        final completedJobs = jobProvider.getJobsByEmployer(user.id)
            .where((job) => job.status == JobStatus.completed)
            .toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Job History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${completedJobs.length} completed',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: completedJobs.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No completed jobs yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: completedJobs.length,
                      itemBuilder: (context, index) {
                        final job = completedJobs[index];
                        final hasRated = ratingProvider.hasJobBeenRated(job.id);
                        return _buildCompletedJobCard(job, hasRated);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompletedJobCard(Job job, bool hasRated) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Chip(
                  label: Text(
                    'COMPLETED',
                    style: TextStyle(fontSize: 10),
                  ),
                  backgroundColor: Colors.green,
                  labelStyle: TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Worker: ${job.assignedWorkerName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              job.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (job.payment != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.monetization_on, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '\$${job.payment!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openJobChat(job),
                    icon: const Icon(Icons.chat),
                    label: const Text('View Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!hasRated)
                  ElevatedButton.icon(
                    onPressed: () => _rateWorker(job),
                    icon: const Icon(Icons.star),
                    label: const Text('Rate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  const Chip(
                    label: Text('Rated'),
                    backgroundColor: Colors.amber,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkersTab() {
    return Consumer2<UserProvider, RatingProvider>(
      builder: (context, userProvider, ratingProvider, child) {
        final workers = userProvider.users
            .where((u) => u.role.name == 'worker' && u.status.name == 'approved')
            .toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Available Workers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${workers.length} workers',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: workers.length,
                itemBuilder: (context, index) {
                  final worker = workers[index];
                  final averageRating = ratingProvider.getWorkerAverageRating(worker.id);
                  final ratingCount = ratingProvider.getWorkerRatings(worker.id).length;
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF4CAF50),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(worker.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${worker.village} • ${worker.phone}'),
                          const SizedBox(height: 4),
                          if (ratingCount > 0) ...[
                            Row(
                              children: [
                                ...List.generate(5, (index) {
                                  return Icon(
                                    index < averageRating.round()
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 16,
                                  );
                                }),
                                const SizedBox(width: 4),
                                Text(
                                  '${averageRating.toStringAsFixed(1)} ($ratingCount)',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],
                          Wrap(
                            spacing: 4,
                            children: worker.skills.take(3).map((skill) {
                              return Chip(
                                label: Text(skill),
                                backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
                                labelStyle: const TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontSize: 10,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _viewApplications(Job job, List<JobApplication> applications) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Applications for ${job.title}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final application = applications[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              application.workerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          _buildApplicationStatusChip(application.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Applied: ${_formatDate(application.appliedAt)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(application.message),
                      if (application.status == ApplicationStatus.pending) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _respondToApplication(application, false),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _respondToApplication(application, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Accept'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationStatusChip(ApplicationStatus status) {
    Color color;
    switch (status) {
      case ApplicationStatus.pending:
        color = Colors.orange;
        break;
      case ApplicationStatus.accepted:
        color = Colors.green;
        break;
      case ApplicationStatus.rejected:
        color = Colors.red;
        break;
    }

    return Chip(
      label: Text(
        status.name.toUpperCase(),
        style: const TextStyle(fontSize: 10),
      ),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
    );
  }

  Future<void> _respondToApplication(JobApplication application, bool accept) async {
    final messageController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(accept ? 'Accept Application' : 'Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              accept 
                  ? 'Accept ${application.workerName}\'s application?'
                  : 'Reject ${application.workerName}\'s application?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                labelText: 'Response message (optional)',
                hintText: accept 
                    ? 'Welcome! Looking forward to working with you.'
                    : 'Thank you for your interest.',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: accept ? const Color(0xFF4CAF50) : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(accept ? 'Accept' : 'Reject'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final applicationProvider = Provider.of<ApplicationProvider>(context, listen: false);
      
      await applicationProvider.updateApplicationStatus(
        application.id,
        accept ? ApplicationStatus.accepted : ApplicationStatus.rejected,
        responseMessage: messageController.text.trim().isEmpty 
            ? null 
            : messageController.text.trim(),
      );

      if (accept) {
        // Assign the job to the worker
        final jobProvider = Provider.of<JobProvider>(context, listen: false);
        await jobProvider.assignJob(
          application.jobId,
          application.workerId,
          application.workerName,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(); // Close the applications dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept 
                  ? 'Application accepted and job assigned'
                  : 'Application rejected',
            ),
            backgroundColor: accept ? const Color(0xFF4CAF50) : Colors.red,
          ),
        );
      }
    }
    
    messageController.dispose();
  }

  Future<void> _assignJob(Job job) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final availableWorkers = userProvider.users
        .where((u) => 
          u.role.name == 'worker' && 
          u.status.name == 'approved' &&
          u.skills.any((skill) => job.requiredSkills.contains(skill)))
        .toList();

    if (availableWorkers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No suitable workers available for this job'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedWorker = await showDialog<dynamic>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Worker'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableWorkers.length,
            itemBuilder: (context, index) {
              final worker = availableWorkers[index];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF4CAF50),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(worker.name),
                subtitle: Text(worker.skills.join(', ')),
                onTap: () => Navigator.of(context).pop(worker),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedWorker != null && mounted) {
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      await jobProvider.assignJob(job.id, selectedWorker.id, selectedWorker.name);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job assigned to ${selectedWorker.name}'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    }
  }

  Future<void> _markJobCompleted(Job job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Job as Completed'),
        content: Text('Mark "${job.title}" as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      await jobProvider.updateJobStatus(job.id, JobStatus.completed);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job marked as completed'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    }
  }

  Future<void> _rateWorker(Job job) async {
    int rating = 5;
    final reviewController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Rate ${job.assignedWorkerName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How would you rate this worker?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => setState(() => rating = index + 1),
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                decoration: const InputDecoration(
                  labelText: 'Review (optional)',
                  hintText: 'Share your experience...',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit Rating'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser!;
      final ratingProvider = Provider.of<RatingProvider>(context, listen: false);
      
      final newRating = Rating(
        id: const Uuid().v4(),
        jobId: job.id,
        customerId: user.id,
        workerId: job.assignedWorkerId!,
        rating: rating,
        review: reviewController.text.trim().isEmpty ? null : reviewController.text.trim(),
        createdAt: DateTime.now(),
      );

      await ratingProvider.addRating(newRating);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating submitted successfully'),
            backgroundColor: Colors.amber,
          ),
        );
      }
    }
    
    reviewController.dispose();
  }

  void _openJobChat(Job job) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JobChatScreen(job: job),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _PostJobForm extends StatefulWidget {
  const _PostJobForm();

  @override
  State<_PostJobForm> createState() => _PostJobFormState();
}

class _PostJobFormState extends State<_PostJobForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _paymentController = TextEditingController();
  
  final List<String> _selectedSkills = [];
  JobPriority _selectedPriority = JobPriority.medium;
  
  final List<String> _availableSkills = [
    'Plumbing',
    'Electrical Work',
    'Carpentry',
    'Masonry',
    'Painting',
    'Gardening',
    'Cleaning',
    'Cooking',
    'Tailoring',
    'Mechanical Work',
    'Farm Work',
    'Construction',
    'Repair Work',
    'Delivery',
    'Teaching',
    'Healthcare',
    'IT Support',
    'Photography',
    'Event Planning',
    'Pet Care',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  Future<void> _postJob() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSkills.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one required skill'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final user = Provider.of<AuthProvider>(context, listen: false).currentUser!;
      final jobProvider = Provider.of<JobProvider>(context, listen: false);

      final job = Job(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        employerId: user.id,
        employerName: user.name,
        requiredSkills: _selectedSkills,
        payment: _paymentController.text.isNotEmpty
            ? double.tryParse(_paymentController.text)
            : null,
        location: _locationController.text.trim(),
        status: JobStatus.open,
        priority: _selectedPriority,
        createdAt: DateTime.now(),
      );

      await jobProvider.addJob(job);

      if (mounted) {
        _titleController.clear();
        _descriptionController.clear();
        _locationController.clear();
        _paymentController.clear();
        setState(() {
          _selectedSkills.clear();
          _selectedPriority = JobPriority.medium;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job posted successfully'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Post a New Job',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Job Title',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a job title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Job Description',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a job description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the job location';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _paymentController,
              decoration: const InputDecoration(
                labelText: 'Payment (Optional)',
                prefixIcon: Icon(Icons.monetization_on),
                hintText: 'Enter amount in \$',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text(
              'Priority Level',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<JobPriority>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.priority_high),
              ),
              items: JobPriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(priority.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPriority = value);
                }
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Required Skills',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableSkills.map((skill) {
                final isSelected = _selectedSkills.contains(skill);
                return FilterChip(
                  label: Text(skill),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSkills.add(skill);
                      } else {
                        _selectedSkills.remove(skill);
                      }
                    });
                  },
                  selectedColor: const Color(0xFF4CAF50).withOpacity(0.3),
                  checkmarkColor: const Color(0xFF2E7D32),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _postJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Post Job',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}