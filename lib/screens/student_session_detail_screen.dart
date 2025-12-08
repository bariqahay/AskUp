import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class StudentSessionDetailScreen extends StatefulWidget {
  final String sessionId;
  final String studentId;
  final String studentName;
  final String title;
  final String lecturer;
  final String code;

  const StudentSessionDetailScreen({
    super.key,
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    required this.title,
    required this.lecturer,
    required this.code,
  });

  @override
  State<StudentSessionDetailScreen> createState() => _StudentSessionDetailScreenState();
}

class _StudentSessionDetailScreenState extends State<StudentSessionDetailScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _questionController = TextEditingController();
  bool _isAnonymous = false;
  int _selectedTab = 0;

  // Data
  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _polls = [];
  Map<String, dynamic>? _checkInData;
  bool _isLoading = true;

  // Realtime subscriptions
  RealtimeChannel? _questionsChannel;
  RealtimeChannel? _pollsChannel;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtimeSubscriptions();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _questionsChannel?.unsubscribe();
    _pollsChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadQuestions(),
      _loadPolls(),
      _loadCheckInData(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadQuestions() async {
    try {
      final response = await supabase
          .from('questions')
          .select('''
            id,
            content,
            status,
            answer,
            answered_at,
            created_at,
            student_id,
            users!questions_student_id_fkey(name)
          ''')
          .eq('session_id', widget.sessionId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _questions = (response as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading questions: $e');
    }
  }

  Future<void> _loadPolls() async {
    try {
      final response = await supabase
          .from('polls')
          .select('''
            id,
            question,
            poll_type,
            show_results_live,
            time_limit_minutes,
            created_at,
            poll_options(
              id,
              option_text,
              votes_count
            )
          ''')
          .eq('session_id', widget.sessionId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _polls = (response as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading polls: $e');
    }
  }

  Future<void> _loadCheckInData() async {
    try {
      final response = await supabase
          .from('session_participants')
          .select('joined_at')
          .eq('session_id', widget.sessionId)
          .eq('student_id', widget.studentId)
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _checkInData = Map<String, dynamic>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Error loading check-in: $e');
    }
  }

  void _setupRealtimeSubscriptions() {
    // Subscribe to questions changes
    _questionsChannel = supabase
        .channel('questions_${widget.sessionId}')
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

    // Subscribe to polls changes
    _pollsChannel = supabase
        .channel('polls_${widget.sessionId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'polls',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: widget.sessionId,
          ),
          callback: (payload) {
            _loadPolls();
          },
        )
        .subscribe();
  }

  Future<void> _submitQuestion() async {
    final content = _questionController.text.trim();
    if (content.isEmpty) {
      _showSnack('Please write your question', Colors.red);
      return;
    }

    if (content.length > 500) {
      _showSnack('Question is too long (max 500 characters)', Colors.red);
      return;
    }

    try {
      await supabase.from('questions').insert({
        'session_id': widget.sessionId,
        'student_id': widget.studentId,
        'content': content,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      _questionController.clear();
      _isAnonymous = false;
      Navigator.pop(context);
      _showSnack('Question sent successfully!', Colors.green);
    } catch (e) {
      debugPrint('Error submitting question: $e');
      _showSnack('Failed to send question', Colors.red);
    }
  }

  Future<void> _votePoll(String pollId, String optionId) async {
    try {
      // Check if already voted (you may need a poll_votes table)
      // For now, just increment votes_count
      final currentOption = await supabase
          .from('poll_options')
          .select('votes_count')
          .eq('id', optionId)
          .single();

      await supabase
          .from('poll_options')
          .update({'votes_count': (currentOption['votes_count'] ?? 0) + 1})
          .eq('id', optionId);

      _showSnack('Vote submitted!', Colors.green);
      _loadPolls();
    } catch (e) {
      debugPrint('Error voting: $e');
      _showSnack('Failed to submit vote', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  void _showAskQuestionDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
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
                  maxLength: 500,
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
                          setDialogState(() {
                            _isAnonymous = value ?? false;
                          });
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
                              '• Be clear and specific\n• Explain why it matters',
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
                        onPressed: _submitQuestion,
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTab == 0
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
    if (_questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.question_answer_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No questions yet',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to ask!',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuestions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _questions.length,
        itemBuilder: (context, index) {
          final q = _questions[index];
          final isAnswered = q['status'] == 'answered';
          final isAnonymous = q['student_id'] != widget.studentId;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildQuestionCard(
              question: q['content'] ?? '',
              askedBy: isAnonymous ? 'Anonymous' : 'You',
              number: _questions.length - index,
              isAnswered: isAnswered,
              answer: q['answer'],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionCard({
    required String question,
    required String askedBy,
    required int number,
    required bool isAnswered,
    String? answer,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Row(
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
                  const SizedBox(width: 8),
                  Text(
                    '#$number',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
  }

  Widget _buildPollsTab() {
    if (_polls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No polls available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPolls,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _polls.length,
        itemBuilder: (context, index) {
          final poll = _polls[index];
          final options = (poll['poll_options'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ?? [];
          
          final totalVotes = options.fold<int>(
            0,
            (sum, opt) => sum + ((opt['votes_count'] as int?) ?? 0),
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPollCard(
              pollId: poll['id'].toString(),
              question: poll['question'] ?? '',
              options: options,
              totalVotes: totalVotes,
              isActive: true, // You can add logic to check if poll is still active
            ),
          );
        },
      ),
    );
  }

  Widget _buildPollCard({
    required String pollId,
    required String question,
    required List<Map<String, dynamic>> options,
    required int totalVotes,
    required bool isActive,
  }) {
    String? selectedOptionId;

    return StatefulBuilder(
      builder: (context, setState) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                    color: isActive ? Colors.blue[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isActive ? '🔴 LIVE' : 'Closed',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.blue[700] : Colors.grey[600],
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
              final optionId = option['id'].toString();
              final isSelected = selectedOptionId == optionId;
              final percentage = totalVotes > 0
                  ? (option['votes_count'] ?? 0) / totalVotes
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: isActive
                      ? () {
                          setState(() {
                            selectedOptionId = optionId;
                          });
                        }
                      : null,
                  child: _buildPollOption(
                    text: option['option_text'] ?? '',
                    percentage: percentage,
                    isSelected: isSelected,
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            if (isActive)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedOptionId != null
                      ? () => _votePoll(pollId, selectedOptionId!)
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
                  child: const Text(
                    'Vote',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (!isActive)
              Text(
                '$totalVotes students have voted',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollOption({
    required String text,
    required double percentage,
    required bool isSelected,
  }) {
    return Container(
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
            onChanged: (value) {},
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
                              ? Colors.white.withOpacity(0.3)
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
                      '${(percentage * 100).toInt()}%',
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
    );
  }

  Widget _buildCheckInTab() {
    if (_checkInData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_reg_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Check-in data not available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final joinedAt = DateTime.parse(_checkInData!['joined_at']);
    final timeStr = '${joinedAt.hour}:${joinedAt.minute.toString().padLeft(2, '0')} ${joinedAt.hour >= 12 ? 'PM' : 'AM'}';
    final months = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final dateStr = '${months[joinedAt.month]} ${joinedAt.day}, ${joinedAt.year}';

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
            'Checked in at $timeStr',
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
            dateStr,
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
}