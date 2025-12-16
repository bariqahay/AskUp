import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class StudentSessionDetailScreen extends StatefulWidget {
  final String title;
  final String lecturer;
  final String code;
  final String? sessionId;
  final String? studentId;

  const StudentSessionDetailScreen({
    super.key,
    required this.title,
    required this.lecturer,
    required this.code,
    this.sessionId,
    this.studentId,
  });

  @override
  State<StudentSessionDetailScreen> createState() => _StudentSessionDetailScreenState();
}

class _StudentSessionDetailScreenState extends State<StudentSessionDetailScreen> {
  final supabase = Supabase.instance.client;
  int _selectedTab = 0;
  final TextEditingController _questionController = TextEditingController();
  bool _isAnonymous = false;
  
  // Data
  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _polls = [];
  Map<String, String> _selectedPollOptions = {}; // pollId -> optionId
  bool _isCheckedIn = false;
  String? _checkinTime;
  bool _isLoading = true;
  
  // Realtime channels
  RealtimeChannel? _questionsChannel;
  RealtimeChannel? _pollsChannel;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtime();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _questionsChannel?.unsubscribe();
    _pollsChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.sessionId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Load questions with upvotes
      final questions = await supabase
          .from('questions')
          .select('*, users!questions_student_id_fkey(name)')
          .eq('session_id', widget.sessionId!)
          .order('upvotes_count', ascending: false);

      // Load polls
      final polls = await supabase
          .from('polls')
          .select('*, poll_options(*)')
          .eq('session_id', widget.sessionId!)
          .order('created_at', ascending: false);

      // Check if student is checked in
      if (widget.studentId != null) {
        final checkIn = await supabase
            .from('session_participants')
            .select('joined_at')
            .eq('session_id', widget.sessionId!)
            .eq('student_id', widget.studentId!)
            .maybeSingle();

        if (checkIn != null) {
          _isCheckedIn = true;
          _checkinTime = checkIn['joined_at'];
        }
      }

      setState(() {
        _questions = List<Map<String, dynamic>>.from(questions);
        _polls = List<Map<String, dynamic>>.from(polls);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupRealtime() {
    if (widget.sessionId == null) return;

    // Subscribe to questions changes
    _questionsChannel = supabase
        .channel('questions-${widget.sessionId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'questions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: widget.sessionId!,
          ),
          callback: (payload) {
            _loadData();
          },
        )
        .subscribe();

    // Subscribe to polls changes
    _pollsChannel = supabase
        .channel('polls-${widget.sessionId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'polls',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: widget.sessionId!,
          ),
          callback: (payload) {
            _loadData();
          },
        )
        .subscribe();
  }

  Future<void> _toggleUpvote(String questionId, bool hasUpvoted) async {
    if (widget.studentId == null) return;

    try {
      if (hasUpvoted) {
        // Remove upvote
        await supabase
            .from('question_upvotes')
            .delete()
            .eq('question_id', questionId)
            .eq('student_id', widget.studentId!);

        await supabase.rpc('decrement_upvote', params: {'question_id': questionId});
      } else {
        // Add upvote
        await supabase.from('question_upvotes').insert({
          'question_id': questionId,
          'student_id': widget.studentId!,
        });

        await supabase.rpc('increment_upvote', params: {'question_id': questionId});
      }

      _loadData();
    } catch (e) {
      debugPrint('Error toggling upvote: $e');
    }
  }

  Future<bool> _checkIfUpvoted(String questionId) async {
    if (widget.studentId == null) return false;

    try {
      final upvote = await supabase
          .from('question_upvotes')
          .select('id')
          .eq('question_id', questionId)
          .eq('student_id', widget.studentId!)
          .maybeSingle();

      return upvote != null;
    } catch (e) {
      return false;
    }
  }

  void _showAskQuestionDialog() {
    if (widget.sessionId == null || widget.studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot ask question: session or student ID missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ask a Question',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Your Question',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _questionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Write your question here...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '0/500',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _isAnonymous,
                      onChanged: (value) {
                        setState(() {
                          _isAnonymous = value ?? false;
                        });
                        Navigator.pop(context);
                        _showAskQuestionDialog();
                      },
                      activeColor: const Color(0xFFF5A623),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Send as Anonymous',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'None will be able to see your name',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFF5B9BD5),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Question Tips',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5B9BD5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '• Be clear and specific about what you want to know',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            '• Briefly explain why this question is important',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_questionController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a question'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        try {
                          await supabase.from('questions').insert({
                            'session_id': widget.sessionId,
                            'student_id': widget.studentId,
                            'content': _questionController.text.trim(),
                            'is_anonymous': _isAnonymous,
                            'upvotes_count': 0,
                            'status': 'pending',
                          });

                          Navigator.pop(context);
                          _questionController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Question sent successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B9BD5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text(
                        'SEND',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2D2D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            Text(
              '${widget.lecturer} • ${widget.code}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _buildTab('Q&A', 0, Icons.question_answer_outlined),
                _buildTab('Polls', 1, Icons.bar_chart),
                _buildTab('Check-in', 2, Icons.how_to_reg_outlined),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? _buildQATab()
                : _selectedTab == 1
                    ? _buildPollsTab()
                    : _buildCheckInTab(),
          ),
        ],
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton(
              onPressed: _showAskQuestionDialog,
              backgroundColor: const Color(0xFF5B9BD5),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildTab(String label, int index, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5B9BD5) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQATab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.question_answer_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No questions yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to ask!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        final question = _questions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildQuestionCard(
            questionId: question['id'],
            question: question['content'],
            askedBy: question['is_anonymous'] == true
                ? 'Anonymous'
                : question['users']['name'],
            upvotesCount: question['upvotes_count'] ?? 0,
            isAnswered: question['status'] == 'answered',
            answer: question['answer'],
          ),
        );
      },
    );
  }

  Widget _buildQuestionCard({
    required String questionId,
    required String question,
    required String askedBy,
    required int upvotesCount,
    required bool isAnswered,
    String? answer,
  }) {
    return FutureBuilder<bool>(
      future: _checkIfUpvoted(questionId),
      builder: (context, snapshot) {
        final hasUpvoted = snapshot.data ?? false;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isAnswered ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isAnswered ? 'Answered' : 'Pending',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isAnswered ? Colors.green[700] : Colors.orange[700],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          askedBy,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          question,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2D2D2D),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Upvote button
              Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _toggleUpvote(questionId, hasUpvoted),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: hasUpvoted
                              ? const Color(0xFF5B9BD5).withValues(alpha: 0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: hasUpvoted
                                ? const Color(0xFF5B9BD5)
                                : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasUpvoted ? Icons.arrow_upward : Icons.arrow_upward_outlined,
                              size: 16,
                              color: hasUpvoted
                                  ? const Color(0xFF5B9BD5)
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              upvotesCount.toString(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: hasUpvoted
                                    ? const Color(0xFF5B9BD5)
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (isAnswered && answer != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          answer,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPollsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_polls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No polls yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Polls will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _polls.length,
      itemBuilder: (context, index) {
        final poll = _polls[index];
        final pollId = poll['id'];
        final options = poll['poll_options'] as List;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildPollCard(
            pollId: pollId,
            question: poll['question'],
            options: options,
          ),
        );
      },
    );
  }

  Widget _buildPollCard({
    required String pollId,
    required String question,
    required List options,
  }) {
    final selectedOptionId = _selectedPollOptions[pollId];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '🔴 LIVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          ...options.map((option) {
            final optionId = option['id'];
            final isSelected = selectedOptionId == optionId;
            final totalVotes = options.fold<int>(0, (sum, opt) => sum + (opt['votes_count'] as int? ?? 0));
            final percentage = totalVotes > 0 ? (option['votes_count'] ?? 0) / totalVotes : 0.0;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildPollOption(
                optionId: optionId,
                text: option['option_text'],
                percentage: percentage,
                votesCount: option['votes_count'] ?? 0,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedPollOptions[pollId] = optionId;
                  });
                },
              ),
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedOptionId != null
                  ? () => _submitVote(pollId, selectedOptionId)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B9BD5),
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: Text(
                selectedOptionId != null ? 'Submit Vote' : 'Select an option',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selectedOptionId != null ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitVote(String pollId, String optionId) async {
    if (widget.studentId == null) return;

    try {
      // Check if already voted
      final existingVote = await supabase
          .from('poll_votes')
          .select('id')
          .eq('poll_id', pollId)
          .eq('student_id', widget.studentId!)
          .maybeSingle();

      if (existingVote != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have already voted on this poll'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Insert vote
      await supabase.from('poll_votes').insert({
        'poll_id': pollId,
        'option_id': optionId,
        'student_id': widget.studentId!,
      });

      // Increment votes count
      await supabase.rpc('increment_poll_votes', params: {
        'option_id': optionId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vote submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear selection and reload
        setState(() {
          _selectedPollOptions.remove(pollId);
        });
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPollOption({
    required String optionId,
    required String text,
    required double percentage,
    required int votesCount,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5B9BD5) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF5B9BD5) : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (value) => onTap(),
              activeColor: Colors.white,
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (isSelected) return Colors.white;
                return Colors.grey[400];
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: isSelected
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isSelected ? Colors.white : const Color(0xFF5B9BD5),
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(percentage * 100).toInt()}% ($votesCount)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isCheckedIn) {
      final checkinDateTime = _checkinTime != null
          ? DateTime.parse(_checkinTime!)
          : DateTime.now();
      final formattedTime = DateFormat('h:mm a').format(checkinDateTime);
      final formattedDate = DateFormat('MMMM d, yyyy').format(checkinDateTime);

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.green[600],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Already Present',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Checked in at $formattedTime',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your attendance is automatically recorded',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Not checked in yet
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.orange[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.qr_code_scanner,
              size: 60,
              color: Colors.orange[600],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Not Checked In',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan the QR code to check in',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange[700],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You were added to this session but haven\'t checked in yet',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PollOption {
  final String text;
  final double percentage;
  final bool isSelected;

  PollOption(this.text, this.percentage, this.isSelected);
}
