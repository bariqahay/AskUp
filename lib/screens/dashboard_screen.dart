import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/active_session_card.dart';
import '../widgets/session_history_item.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String lecturerId;
  final String lecturerName;

  const DashboardScreen({
    Key? key,
    required this.lecturerId,
    required this.lecturerName,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> activeSessions = [];
  List<dynamic> sessionHistory = [];
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
          .select('id, title, start_time, end_time, status, classes(title, code)')
          .eq('classes.lecturer_id', widget.lecturerId)
          .eq('status', 'active');

      final history = await supabase
          .from('sessions')
          .select('id, title, start_time, end_time, status, classes(title, code)')
          .eq('classes.lecturer_id', widget.lecturerId)
          .neq('status', 'active');

      setState(() {
        activeSessions = active is List ? active : [];
        sessionHistory = history is List ? history : [];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("Error loading sessions: $e");
    }
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
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'ACTIVE SESSIONS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D2D2D),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        activeSessions.isEmpty
                            ? const Text('No active sessions available')
                            : Column(
                                children: [
                                  ...activeSessions.map((s) => ActiveSessionCard(
                                        title: s['title'] ?? 'Untitled',
                                        code: s['classes']?['code'] ?? '-',
                                        currentStudents: 0,
                                        totalStudents: 0,
                                        statusColor: const Color(0xFF4CAF50),
                                        progressColors: [
                                          const Color(0xFFFFA726),
                                          const Color(0xFF5B9BD5)
                                        ],
                                      )),
                                ],
                              ),

                        const SizedBox(height: 24),
                        const Text(
                          'SESSION HISTORY',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D2D2D),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        sessionHistory.isEmpty
                            ? const Text('No session history available')
                            : Column(
                                children: [
                                  ...sessionHistory.map(
                                    (s) => SessionHistoryItem(
                                      title: s['title'] ?? 'Untitled',
                                      time: s['start_time']?.toString() ?? '-',
                                      students: 'Unknown students',
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF5B9BD5),
        child: const Icon(Icons.add, size: 28),
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
