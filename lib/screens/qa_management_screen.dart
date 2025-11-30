import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QAManagementScreen extends StatefulWidget {
  final String sessionId;

  const QAManagementScreen({Key? key, required this.sessionId}) : super(key: key);

  @override
  State<QAManagementScreen> createState() => _QAManagementScreenState();
}

class _QAManagementScreenState extends State<QAManagementScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  final _answerController = TextEditingController();
  
  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _filteredQuestions = [];
  String _selectedFilter = 'All';
  bool _isLoading = true;
  String? _expandedQuestionId;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    _supabase
        .channel('questions_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'questions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: widget.sessionId,
          ),
          callback: (payload) {
            _loadQuestions();
          },
        )
        .subscribe();
  }

  Future<void> _loadQuestions() async {
    try {
      final response = await _supabase
          .from('questions')
          .select('''
            id,
            content,
            created_at,
            status,
            answer,
            answered_at,
            student_id,
            users!questions_student_id_fkey(name)
          ''')
          .eq('session_id', widget.sessionId)
          .order('created_at', ascending: false);

      setState(() {
        _questions = List<Map<String, dynamic>>.from(response);
        _filterQuestions();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading questions: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterQuestions() {
    setState(() {
      if (_selectedFilter == 'All') {
        _filteredQuestions = _questions;
      } else if (_selectedFilter == 'Pending') {
        _filteredQuestions = _questions.where((q) => q['status'] == 'pending').toList();
      } else if (_selectedFilter == 'Approved') {
        _filteredQuestions = _questions.where((q) => q['status'] == 'approved').toList();
      } else if (_selectedFilter == 'Answered') {
        _filteredQuestions = _questions.where((q) => q['status'] == 'answered').toList();
      }

      // Apply search filter
      if (_searchController.text.isNotEmpty) {
        _filteredQuestions = _filteredQuestions
            .where((q) => q['content']
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _updateQuestionStatus(String questionId, String newStatus) async {
    try {
      await _supabase.from('questions').update({'status': newStatus}).eq('id', questionId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Question status updated to $newStatus')),
      );
      _loadQuestions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Future<void> _answerQuestion(String questionId) async {
    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an answer')),
      );
      return;
    }

    try {
      await _supabase.from('questions').update({
        'answer': _answerController.text.trim(),
        'answered_at': DateTime.now().toIso8601String(),
        'status': 'answered',
      }).eq('id', questionId);

      _answerController.clear();
      setState(() => _expandedQuestionId = null);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer submitted successfully')),
      );
      _loadQuestions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting answer: $e')),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'answered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  int _getFilterCount(String filter) {
    if (filter == 'All') return _questions.length;
    if (filter == 'Pending') return _questions.where((q) => q['status'] == 'pending').length;
    if (filter == 'Approved') return _questions.where((q) => q['status'] == 'approved').length;
    if (filter == 'Answered') return _questions.where((q) => q['status'] == 'answered').length;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Q&A Management',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Moderate and respond to student questions',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _filterQuestions(),
              decoration: InputDecoration(
                hintText: 'Search Question...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', _getFilterCount('All')),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending', _getFilterCount('Pending')),
                  const SizedBox(width: 8),
                  _buildFilterChip('Approved', _getFilterCount('Approved')),
                  const SizedBox(width: 8),
                  _buildFilterChip('Answered', _getFilterCount('Answered')),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Questions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredQuestions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.question_answer_outlined,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No questions found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredQuestions.length,
                        itemBuilder: (context, index) {
                          final question = _filteredQuestions[index];
                          return _buildQuestionCard(question);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
          _filterQuestions();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final questionId = question['id'];
    final isExpanded = _expandedQuestionId == questionId;
    final status = question['status'] ?? 'pending';
    final studentName = question['users']?['name'] ?? 'Anonymous';
    final createdAt = DateTime.parse(question['created_at']);
    final timeAgo = _formatTimeAgo(createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange[100],
                  radius: 16,
                  child: const Icon(Icons.person, size: 18, color: Colors.orange),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Question Content
            Text(
              question['content'],
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),

            // Answer Section (if answered)
            if (question['answer'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                        const SizedBox(width: 6),
                        Text(
                          'Your Answer:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question['answer'],
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action Buttons
            if (status != 'answered')
              Row(
                children: [
                  if (status == 'pending') ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateQuestionStatus(questionId, 'approved'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('APPROVE', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateQuestionStatus(questionId, 'rejected'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('HIDE', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                  if (status == 'approved') ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _expandedQuestionId = isExpanded ? null : questionId;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          isExpanded ? 'CANCEL' : 'REPLY',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

            // Answer Input (when expanded)
            if (isExpanded) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _answerController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Type your answer here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _answerQuestion(questionId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('SEND REPLY', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _answerController.dispose();
    _supabase.channel('questions_channel').unsubscribe();
    super.dispose();
  }
}