import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'student_session_detail_screen.dart';
import 'student_profile_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentDashboardScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _sessionCodeController = TextEditingController();

  List<Map<String, dynamic>> _activeSessions = [];
  bool _isLoading = true;

  // Stats
  int _totalQuestions = 0;
  int _totalPolls = 0;
  double _attendanceRate = 0.0;

  @override
  void initState() {
    super.initState();
    _loadActiveSessions();
    _loadStats();
  }

  @override
  void dispose() {
    _sessionCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveSessions() async {
    setState(() => _isLoading = true);
    try {
      // Get active sessions yang udah di-join student
      final participantSessions = await supabase
          .from('session_participants')
          .select('session_id')
          .eq('student_id', widget.studentId);

      if (participantSessions.isEmpty) {
        setState(() {
          _activeSessions = [];
          _isLoading = false;
        });
        return;
      }

      final sessionIds = participantSessions
          .map((p) => p['session_id'].toString())
          .toList();

      // Get session details
      final sessions = await supabase
          .from('sessions')
          .select('''
            id, 
            title, 
            session_code,
            classes!inner(
              code,
              users!classes_lecturer_id_fkey(name)
            )
          ''')
          .eq('status', 'active')
          .inFilter('id', sessionIds);

      final List<Map<String, dynamic>> sessionList =
          List<Map<String, dynamic>>.from(sessions);

      // Enrich dengan question count & poll status
      for (var session in sessionList) {
        final sessionId = session['id'].toString();

        // Count new questions
        final questions = await supabase
            .from('questions')
            .select('id')
            .eq('session_id', sessionId)
            .eq('status', 'approved'); // hanya approved questions

        session['new_questions'] = questions.length;

        // Check active poll
        final polls = await supabase
            .from('polls')
            .select('id')
            .eq('session_id', sessionId)
            .limit(1);

        session['has_active_poll'] = polls.isNotEmpty;
      }

      if (mounted) {
        setState(() {
          _activeSessions = sessionList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading sessions: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStats() async {
    try {
      // Total questions asked
      final questions = await supabase
          .from('questions')
          .select('id')
          .eq('student_id', widget.studentId);
      _totalQuestions = questions.length;

      // Total polls answered (need poll_responses table - assume exists)
      // If no poll_responses table, set to 0
      _totalPolls = 0; // TODO: implement when poll_responses table exists

      // Attendance rate
      final totalSessions = await supabase
          .from('session_participants')
          .select('id')
          .eq('student_id', widget.studentId);

      // Rough calculation - bisa lebih complex
      if (totalSessions.isNotEmpty) {
        _attendanceRate = 95.0; // placeholder calculation
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _joinSession() async {
    final code = _sessionCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      _showSnack('Please enter a session code', Colors.red);
      return;
    }

    try {
      // Find session by code
      final sessionRes = await supabase
          .from('sessions')
          .select('id, title, session_code, status, class_id, classes!inner(code, users!classes_lecturer_id_fkey(name))')
          .eq('session_code', code)
          .eq('status', 'active')
          .maybeSingle();

      if (sessionRes == null) {
        _showSnack('Session code not found or inactive', Colors.red);
        return;
      }

      final sessionId = sessionRes['id'].toString();

      // Check if already joined
      final alreadyJoined = await supabase
          .from('session_participants')
          .select('id')
          .eq('session_id', sessionId)
          .eq('student_id', widget.studentId)
          .maybeSingle();

      if (alreadyJoined != null) {
        _showSnack('You already joined this session', Colors.orange);
        
        // Navigate to session detail
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentSessionDetailScreen(
              sessionId: sessionId,
              studentId: widget.studentId,
              studentName: widget.studentName,
              title: sessionRes['title'] ?? 'Session',
              lecturer: sessionRes['classes']?['users']?['name'] ?? 'Lecturer',
              code: code,
            ),
          ),
        ).then((_) => _loadActiveSessions());
        return;
      }

      // Join session
      await supabase.from('session_participants').insert({
        'session_id': sessionId,
        'student_id': widget.studentId,
        'joined_at': DateTime.now().toIso8601String(),
      });

      _showSnack('Successfully joined session!', Colors.green);
      _sessionCodeController.clear();

      // Navigate to session detail
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudentSessionDetailScreen(
            sessionId: sessionId,
            studentId: widget.studentId,
            studentName: widget.studentName,
            title: sessionRes['title'] ?? 'Session',
            lecturer: sessionRes['classes']?['users']?['name'] ?? 'Lecturer',
            code: code,
          ),
        ),
      ).then((_) => _loadActiveSessions());

    } catch (e) {
      debugPrint('Error joining session: $e');
      _showSnack('Error: $e', Colors.red);
    }
  }

  void _scanQRCode() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.black,
              title: const Text('Scan QR Code'),
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final code = barcodes.first.rawValue;
                    if (code != null) {
                      Navigator.pop(context);
                      _sessionCodeController.text = code;
                      _joinSession();
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadActiveSessions();
            await _loadStats();
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Hi, ${widget.studentName}! ',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                          const Text(
                            '👋',
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ready to learn?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentProfileScreen(
                            studentId: widget.studentId,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5A623),
                        borderRadius: BorderRadius.circular(22.5),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(widget.studentName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'JOIN SESSION',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _sessionCodeController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'Enter session code',
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
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _joinSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B9BD5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'JOIN',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _scanQRCode,
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          size: 18,
                          color: Color(0xFFF5A623),
                        ),
                        label: const Text(
                          'SCAN QR CODE',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF5A623),
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ACTIVE SESSIONS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (_activeSessions.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_activeSessions.length} Joined',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _activeSessions.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'No active sessions. Join one using the code above!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        )
                      : Column(
                          children: _activeSessions.map((session) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildActiveSessionCard(
                                sessionId: session['id'].toString(),
                                title: session['title'] ?? 'Session',
                                lecturer: session['classes']?['users']?['name'] ?? 'Lecturer',
                                code: session['session_code'] ?? '-',
                                newQuestions: session['new_questions'] ?? 0,
                                hasActivePoll: session['has_active_poll'] ?? false,
                              ),
                            );
                          }).toList(),
                        ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B9BD5), Color(0xFF4A8BC2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B9BD5).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Your Stats',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('$_totalQuestions', 'Questions Asked'),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          _buildStatItem('$_totalPolls', 'Polls Answered'),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          _buildStatItem('${_attendanceRate.toStringAsFixed(0)}%', 'Attendance'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSessionCard({
    required String sessionId,
    required String title,
    required String lecturer,
    required String code,
    required int newQuestions,
    required bool hasActivePoll,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentSessionDetailScreen(
              sessionId: sessionId,
              studentId: widget.studentId,
              studentName: widget.studentName,
              title: title,
              lecturer: lecturer,
              code: code,
            ),
          ),
        ).then((_) => _loadActiveSessions());
      },
      child: Container(
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$lecturer • $code',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (newQuestions > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A623),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$newQuestions new question${newQuestions > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (newQuestions > 0) const SizedBox(width: 8),
                if (hasActivePoll)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B9BD5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Active poll',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}