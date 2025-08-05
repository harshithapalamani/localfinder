import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/application_provider.dart';
import '../../providers/rating_provider.dart';
import '../../models/job_model.dart';
import '../../models/application_model.dart';
import '../auth/login_screen.dart';
import '../shared/job_chat_screen.dart';

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JobProvider>(context, listen: false).loadJobs();
      Provider.of<ApplicationProvider>(context, listen: false).loadApplications();
      Provider.of<RatingProvider>(context, listen: false).loadRatings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${user.name}'),
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
          _buildAvailableJobsTab(),
          _buildMyApplicationsTab(),
          _buildMyJobsTab(),
          _buildProfileTab(),
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
            icon: Icon(Icons.work_outline),
            label: 'Available Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.send),
            label: 'Applications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'My Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableJobsTab() {
    return Consumer2<JobProvider, ApplicationProvider>(
      builder: (context, jobProvider, applicationProvider, child) {
        final user = Provider.of<AuthProvider>(context).currentUser!;
        final availableJobs = jobProvider.availableJobs.where((job) {
          return job.requiredSkills.any((skill) => user.skills.contains(skill));
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Available Jobs',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${availableJobs.length} jobs',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: availableJobs.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.work_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No jobs available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'Check back later for new opportunities',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: availableJobs.length,
                      itemBuilder: (context, index) {
                        final job = availableJobs[index];
                        final hasApplied = applicationProvider.hasWorkerApplied(job.id, user.id);
                        return _buildAvailableJobCard(job, hasApplied);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMyApplicationsTab() {
    return Consumer<ApplicationProvider>(
      builder: (context, applicationProvider, child) {
        final user = Provider.of<AuthProvider>(context).currentUser!;
        final myApplications = applicationProvider.getApplicationsForWorker(user.id);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'My Applications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${myApplications.length} applications',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: myApplications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.send_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No applications yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'Apply for jobs to see them here',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: myApplications.length,
                      itemBuilder: (context, index) {
                        final application = myApplications[index];
                        return _buildApplicationCard(application);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMyJobsTab() {
    return Consumer<JobProvider>(
      builder: (context, jobProvider, child) {
        final user = Provider.of<AuthProvider>(context).currentUser!;
        final myJobs = jobProvider.getJobsForWorker(user.id);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'My Jobs',
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
                            Icons.assignment_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No jobs assigned yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'Jobs will appear here once assigned',
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
                        return _buildMyJobCard(job);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvailableJobCard(Job job, bool hasApplied) {
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
                _buildPriorityChip(job.priority),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              job.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  job.employerName,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  job.location,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: hasApplied ? null : () => _applyForJob(job),
                icon: Icon(hasApplied ? Icons.check : Icons.send),
                label: Text(hasApplied ? 'Applied' : 'Apply for Job'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasApplied ? Colors.grey : const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(JobApplication application) {
    return Consumer<JobProvider>(
      builder: (context, jobProvider, child) {
        final job = jobProvider.jobs.firstWhere(
          (j) => j.id == application.jobId,
          orElse: () => Job(
            id: '',
            title: 'Job Not Found',
            description: '',
            employerId: '',
            employerName: '',
            requiredSkills: [],
            location: '',
            status: JobStatus.cancelled,
            priority: JobPriority.low,
            createdAt: DateTime.now(),
          ),
        );

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
                    _buildApplicationStatusChip(application.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Applied: ${_formatDate(application.appliedAt)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Message: ${application.message}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                if (application.responseMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: application.status == ApplicationStatus.accepted
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Response:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: application.status == ApplicationStatus.accepted
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(application.responseMessage!),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyJobCard(Job job) {
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
                _buildJobStatusChip(job.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              job.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  job.employerName,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  job.location,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
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
                if (job.status == JobStatus.assigned)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _startJob(job),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Start Job'),
                    ),
                  ),
                if (job.status == JobStatus.inProgress) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _completeJob(job),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Complete'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (job.status == JobStatus.assigned || job.status == JobStatus.inProgress)
                  IconButton(
                    onPressed: () => _openJobChat(job),
                    icon: const Icon(Icons.chat),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(JobPriority priority) {
    Color color;
    switch (priority) {
      case JobPriority.urgent:
        color = Colors.red;
        break;
      case JobPriority.high:
        color = Colors.orange;
        break;
      case JobPriority.medium:
        color = Colors.blue;
        break;
      case JobPriority.low:
        color = Colors.green;
        break;
    }

    return Chip(
      label: Text(
        priority.name.toUpperCase(),
        style: const TextStyle(fontSize: 10),
      ),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
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

  Widget _buildJobStatusChip(JobStatus status) {
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

  Future<void> _applyForJob(Job job) async {
    final messageController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Apply for ${job.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Send a message to ${job.employerName}:'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Your message',
                hintText: 'Why are you the right person for this job?',
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
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser!;
      final applicationProvider = Provider.of<ApplicationProvider>(context, listen: false);
      
      final application = JobApplication(
        id: const Uuid().v4(),
        jobId: job.id,
        workerId: user.id,
        workerName: user.name,
        message: messageController.text.trim().isEmpty 
            ? 'I would like to apply for this job.' 
            : messageController.text.trim(),
        appliedAt: DateTime.now(),
        status: ApplicationStatus.pending,
      );

      await applicationProvider.addApplication(application);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application sent successfully'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    }
    
    messageController.dispose();
  }

  Future<void> _startJob(Job job) async {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    await jobProvider.updateJobStatus(job.id, JobStatus.inProgress);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job started successfully'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
  }

  Future<void> _completeJob(Job job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Job'),
        content: Text('Are you sure you want to mark "${job.title}" as completed?'),
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
            content: Text('Job completed successfully'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    }
  }

  void _openJobChat(Job job) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JobChatScreen(job: job),
      ),
    );
  }

  Widget _buildProfileTab() {
    final user = Provider.of<AuthProvider>(context).currentUser!;
    
    return Consumer<RatingProvider>(
      builder: (context, ratingProvider, child) {
        final workerRatings = ratingProvider.getWorkerRatings(user.id);
        final averageRating = ratingProvider.getWorkerAverageRating(user.id);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Color(0xFF4CAF50),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (workerRatings.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ...List.generate(5, (index) {
                              return Icon(
                                index < averageRating.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 24,
                              );
                            }),
                            const SizedBox(width: 8),
                            Text(
                              '${averageRating.toStringAsFixed(1)} (${workerRatings.length} reviews)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          'No ratings yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Profile Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildProfileRow('Phone', user.phone),
                      _buildProfileRow('Village', user.village),
                      _buildProfileRow('Status', user.status.name.toUpperCase()),
                      if (user.description != null && user.description!.isNotEmpty)
                        _buildProfileRow('Description', user.description!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'My Skills',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.skills.map((skill) {
                      return Chip(
                        label: Text(skill),
                        backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
                        labelStyle: const TextStyle(
                          color: Color(0xFF2E7D32),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (workerRatings.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Recent Reviews',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 12),
                ...workerRatings.take(5).map((rating) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < rating.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                );
                              }),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(rating.createdAt),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          if (rating.review != null && rating.review!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(rating.review!),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$title:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}