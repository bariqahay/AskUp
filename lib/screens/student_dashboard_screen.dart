import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_session_detail_screen.dart';
import 'student_profile_screen.dart';
import 'qr_scanner_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  final String? studentId;

  const StudentDashboardScreen({super.key, this.studentId});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _sessionCodeController = TextEditingController();
  
  // Real data from database
  List<Map<String, dynamic>> _activeSessions = [];
  bool _isLoading = true;
  int _questionsCount = 0;
  int _pollsCount = 0;
  int _attendancePercentage = 0;
  String _studentName = 'Student';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _sessionCodeController.dispose();
    super.dispose();
  }

void _showError(String message) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}

Future<void> _loadDashboardData() async {
  if (widget.studentId == null) {
    setState(() => _isLoading = false);
    return;
  }

  setState(() => _isLoading = true);

  try {
    // Load student name
    final userData = await supabase
        .from('users')
        .select('name')
        .eq('id', widget.studentId!)
        .maybeSingle();

    if (userData != null) {
      _studentName = userData['name'] ?? 'Student';
    }

    // 🔥 LOAD JOINED SESSIONS - Filter active di client untuk debug lebih mudah
    final participants = await supabase
        .from('session_participants')
        .select(
          'session_id, sessions!inner(id, title, session_code, status, class_id, classes!inner(title, code))',
        )
        .eq('student_id', widget.studentId!);

    debugPrint('📊 Raw participants data: ${participants.length} sessions found');

    final List<Map<String, dynamic>> activeSessions = [];

    for (final p in participants) {
      final session = p['sessions'];
      
      // ✅ Debug log untuk lihat struktur data
      debugPrint('Session data: $session');
      
      // ✅ Null safety check
      if (session == null) {
        debugPrint('⚠️ Session is null for participant');
        continue;
      }

      // ✅ Filter active sessions di client
      final sessionStatus = session['status'] as String?;
      if (sessionStatus != 'active') {
        debugPrint('⏭️ Skipping session ${session['id']} - status: $sessionStatus');
        continue;
      }

      final sessionId = session['id'] as String;
      final sessionTitle = session['title'] as String? ?? 'Untitled Session';
      final sessionCode = session['session_code'] as String? ?? 'N/A';

      // ✅ Safe access to nested classes data
      final classData = session['classes'];
      String classTitle = 'Unknown Class';
      String classCode = 'N/A';
      
      if (classData != null && classData is Map) {
        classTitle = classData['title'] as String? ?? 'Unknown Class';
        classCode = classData['code'] as String? ?? 'N/A';
      }

      // ✅ Count pending questions
      final questions = await supabase
          .from('questions')
          .select('id')
          .eq('session_id', sessionId)
          .eq('status', 'pending');

      debugPrint('❓ Questions for session $sessionId: ${questions.length}');

      // ✅ Check for polls (tanpa status karena kolom tidak ada)
      // Asumsi: poll dianggap active jika belum ada tanggal expired
      final allPolls = await supabase
          .from('polls')
          .select('id, created_at, time_limit_minutes')
          .eq('session_id', sessionId);

      debugPrint('📊 All polls for session $sessionId: ${allPolls.length} found');

      // ✅ Filter active polls berdasarkan time limit
      final now = DateTime.now();
      final activePolls = allPolls.where((poll) {
        final timeLimitMinutes = poll['time_limit_minutes'] as int?;
        
        // Jika tidak ada time limit, poll selalu active
        if (timeLimitMinutes == null || timeLimitMinutes == 0) {
          return true;
        }
        
        // Check apakah poll masih dalam time limit
        final createdAt = DateTime.parse(poll['created_at'] as String);
        final expiresAt = createdAt.add(Duration(minutes: timeLimitMinutes));
        
        return now.isBefore(expiresAt);
      }).toList();

      debugPrint('✅ Active polls (within time limit): ${activePolls.length}');

      activeSessions.add({
        'id': sessionId,
        'title': sessionTitle,
        'session_code': sessionCode,
        'class_title': classTitle,
        'class_code': classCode,
        'new_questions': questions.length,
        'has_active_poll': activePolls.isNotEmpty,
      });
    }

    debugPrint('✅ Final active sessions: ${activeSessions.length}');

    // Stats
    final questionsCount = await supabase
        .from('questions')
        .select('id')
        .eq('student_id', widget.studentId!);

    // ✅ Hitung total sessions (semua sessions)
    // Atau filter yang active/completed saja jika mau
    final allSessions = await supabase
        .from('sessions')
        .select('id');
        // Bisa juga pakai: .in_('status', ['active', 'completed'])

    debugPrint('📈 Total sessions: ${allSessions.length}');
    debugPrint('📈 Student joined: ${participants.length}');

    final attendancePercent = allSessions.isNotEmpty
        ? ((participants.length / allSessions.length) * 100).round()
        : 0;

    // ✅ Hitung polls yang sudah dijawab student ini
    final pollsAnswered = await supabase
        .from('poll_votes')
        .select('id')
        .eq('student_id', widget.studentId!);

    setState(() {
      _activeSessions = activeSessions;
      _questionsCount = questionsCount.length;
      _pollsCount = pollsAnswered.length;
      _attendancePercentage = attendancePercent;
      _isLoading = false;
    });

    debugPrint('🎉 Dashboard loaded successfully!');
  } catch (e, stackTrace) {
    debugPrint('❌ Dashboard error: $e');
    debugPrint('Stack trace: $stackTrace');
    setState(() => _isLoading = false);
  }
}


  void _joinSession() async {
    final code = _sessionCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      _showError('Please enter a session code');
      return;
    }

    if (widget.studentId == null) {
      _showError('Student ID not found');
      return;
    }

    try {
      // Query session by SESSION CODE
      final session = await supabase
        .from('sessions')
        .select('id, title, session_code, status, classes!inner(title, code)')
        .eq('session_code', code)
        .eq('status', 'active')
        .maybeSingle();

      if (session == null) {
        _showError('Session not found or not active');
        return;
      }

      // Check-in student
      await supabase.from('session_participants').insert({
        'session_id': session['id'],
        'student_id': widget.studentId,
      });

      if (mounted) {
        // Clear input
        _sessionCodeController.clear();
        
        // ✅ Navigate to session detail dengan await
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentSessionDetailScreen(
              title: session['title'],
              lecturer: session['classes']['title'],
              code: session['classes']['code'],
              sessionId: session['id'],
              studentId: widget.studentId!,
              studentName: _studentName,
            ),
          ),
        );

        // ✅ Pas balik dari Session Detail, refresh dashboard
        _loadDashboardData();
      }
    } catch (e) {
      debugPrint('Join session error: $e');
      if (mounted) {
        _showError(e.toString().contains('duplicate') 
            ? 'Already joined this session' 
            : 'Error joining session');
      }
    }
  }

    void _scanQRCode() {
      if (widget.studentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student ID not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QRScannerScreen(
            studentId: widget.studentId!,
            studentName: _studentName,
          ),
        ),
      ).then((_) => _loadDashboardData());
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Hi, $_studentName! ',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const Text(
                          '👋',
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to learn?',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey,
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
                          studentId: widget.studentId!,
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
                        _getInitials(_studentName),
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

            // Join Session Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark ? [] : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JOIN SESSION',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _sessionCodeController,
                    decoration: InputDecoration(
                      hintText: 'Enter session code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: _joinSession,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: Divider(color: isDark ? Colors.grey[700] : Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: isDark ? Colors.grey[700] : Colors.grey[300])),
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
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
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

            // Active Sessions Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ACTIVE SESSIONS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
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

            // Active Sessions List
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _activeSessions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No active sessions',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Join a session using code or QR scanner',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: _activeSessions.map((session) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildActiveSessionCard(
                              sessionId: session['id'],
                              title: session['title'],
                              lecturer: session['class_title'],
                              code: session['class_code'],
                              newQuestions: session['new_questions'],
                              hasActivePoll: session['has_active_poll'],
                              isDark: isDark,
                              cardColor: cardColor,
                              textColor: textColor,
                            ),
                          );
                        }).toList(),
                      ),

            const SizedBox(height: 16),

            // Stats Card
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
                      color: const Color(0xFF5B9BD5).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Stats',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('$_questionsCount', 'Questions Asked'),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        _buildStatItem('$_pollsCount', 'Polls Answered'),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        _buildStatItem('$_attendancePercentage%', 'Attendance'),
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
    );
  }

  Widget _buildActiveSessionCard({
    required String sessionId,
    required String title,
    required String lecturer,
    required String code,
    required int newQuestions,
    required bool hasActivePoll,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentSessionDetailScreen(
              sessionId: sessionId,
              studentId: widget.studentId!,
              studentName: _studentName,
              title: title,
              lecturer: lecturer,
              code: code,
            ),
          ),
        ).then((_) => _loadDashboardData());
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isDark ? [] : [
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$lecturer • $code',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
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