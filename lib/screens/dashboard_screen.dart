import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/active_session_card.dart';
import '../widgets/session_history_item.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String lecturerId;
  final String lecturerName;

  const DashboardScreen({
    super.key,
    required this.lecturerId,
    required this.lecturerName,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> activeSessions = [];
  List<Map<String, dynamic>> sessionHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final active = await supabase
          .from('sessions')
          .select(
            'id, title, start_time, end_time, status, class_id, '
            'classes!inner(title, code, lecturer_id)',
          )
          .eq('classes.lecturer_id', widget.lecturerId)
          .eq('status', 'active');

      final history = await supabase
          .from('sessions')
          .select(
            'id, title, start_time, end_time, status, class_id, '
            'classes!inner(title, code, lecturer_id)',
          )
          .eq('classes.lecturer_id', widget.lecturerId)
          .neq('status', 'active');

      // Convert ke List<Map>
      final activeList =
          List<Map<String, dynamic>>.from(active as List<dynamic>);
      final historyList =
          List<Map<String, dynamic>>.from(history as List<dynamic>);

      // Inject total_students
      for (var s in activeList) {
        s['total_students'] = await _getStudentCount(s['id']);
      }
      for (var s in historyList) {
        s['total_students'] = await _getStudentCount(s['id']);
      }

      setState(() {
        activeSessions = activeList;
        sessionHistory = historyList;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error loading sessions: $e");
    }
  }

  Future<int> _getStudentCount(int sessionId) async {
    try {
      final res = await supabase
          .from('questions')
          .select('student_id')
          .eq('session_id', sessionId);

      if (res == null) return 0;

      final rows = List<Map<String, dynamic>>.from(res as List<dynamic>);
      final uniqueIds = <dynamic>{};

      for (var r in rows) {
        final id = r['student_id'];
        if (id != null) uniqueIds.add(id);
      }

      return uniqueIds.length;
    } catch (e) {
      debugPrint('Error counting students for session $sessionId: $e');
      return 0;
    }
  }

  String _formatTime(dynamic time) {
    if (time == null) return '-';
    final dt = DateTime.parse(time);
    return '${dt.day}/${dt.month} '
        '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadSessions,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _sectionTitle('ACTIVE SESSIONS'),
                          const SizedBox(height: 12),
                          activeSessions.isEmpty
                              ? const Text('No active sessions available')
                              : Column(
                                  children: activeSessions.map((s) {
                                    return ActiveSessionCard(
                                      title: s['title'] ?? 'Untitled',
                                      code: s['classes']?['code'] ?? '-',
                                      currentStudents: s['total_students'] ?? 0,
                                      totalStudents: s['total_students'] ?? 0,
                                      statusColor: const Color(0xFF4CAF50),
                                      progressColors: const [
                                        Color(0xFFFFA726),
                                        Color(0xFF5B9BD5),
                                      ],
                                    );
                                  }).toList(),
                                ),

                          const SizedBox(height: 24),
                          _sectionTitle('SESSION HISTORY'),
                          const SizedBox(height: 12),
                          sessionHistory.isEmpty
                              ? const Text('No session history available')
                              : Column(
                                  children: sessionHistory.map((s) {
                                    return SessionHistoryItem(
                                      title: s['title'] ?? 'Untitled',
                                      time: _formatTime(s['start_time']),
                                      students:
                                          '${s['total_students'] ?? 0} students',
                                    );
                                  }).toList(),
                                ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF5B9BD5),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2D2D2D),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Hi, ${widget.lecturerName}!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const Text(' 👋', style: TextStyle(fontSize: 18)),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Ready to engage your students?',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF5B9BD5),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'PS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
