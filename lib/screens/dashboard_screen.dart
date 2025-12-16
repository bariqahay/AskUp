// dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/active_session_card.dart';
import '../widgets/session_history_item.dart';
import 'profile_screen.dart';
import 'session_detail_screen.dart';

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
    setState(() => isLoading = true);
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

      final activeList =
          (active ?? <dynamic>[]).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final historyList =
          (history ?? <dynamic>[]).map((e) => Map<String, dynamic>.from(e as Map)).toList();

      // Get all session IDs
      final allSessionIds = [
        ...activeList.map((s) => s['id'].toString()),
        ...historyList.map((s) => s['id'].toString()),
      ];

      // Batch query: Count students for all sessions in one query
      final Map<String, int> studentCounts = {};
      if (allSessionIds.isNotEmpty) {
        final participants = await supabase
            .from('session_participants')
            .select('session_id')
            .inFilter('session_id', allSessionIds);

        // Count students per session
        for (var p in (participants ?? [])) {
          final sessionId = p['session_id'].toString();
          studentCounts[sessionId] = (studentCounts[sessionId] ?? 0) + 1;
        }
      }

      // Inject total_students from batch query results
      for (var s in activeList) {
        s['total_students'] = studentCounts[s['id'].toString()] ?? 0;
      }
      for (var s in historyList) {
        s['total_students'] = studentCounts[s['id'].toString()] ?? 0;
      }

      if (mounted) {
        setState(() {
          activeSessions = activeList;
          sessionHistory = historyList;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      debugPrint("Error loading sessions: $e");
    }
  }

  String _formatTime(dynamic time) {
    if (time == null) return '-';
    try {
      final dt = DateTime.parse(time.toString());
      return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '-';
    }
  }

  void _showCreateSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateSessionDialog(
        lecturerId: widget.lecturerId,
        onSessionCreated: () {
          _loadSessions();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadSessions,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('ACTIVE SESSIONS'),
                            const SizedBox(height: 12),

                            // Active sessions
                            activeSessions.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: Text(
                                        'No active sessions available',
                                        style: TextStyle(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: activeSessions.length,
                                    itemBuilder: (context, index) {
                                      final s = activeSessions[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => SessionDetailScreen(
                                                  sessionId: s['id'].toString(),
                                                  title: s['title'] ?? 'Untitled',
                                                  classCode: s['classes']?['code'] ?? '-',
                                                  totalStudents: s['total_students'] ?? 0,
                                                  lecturerId: widget.lecturerId,
                                                  lecturerName: widget.lecturerName,
                                                ),
                                              ),
                                            );
                                          },
                                          child: ActiveSessionCard(
                                            title: s['title'] ?? 'Untitled',
                                            code: s['classes']?['code'] ?? '-',
                                            currentStudents: s['total_students'] ?? 0,
                                            totalStudents: s['total_students'] ?? 0,
                                            statusColor: const Color(0xFF4CAF50),
                                            progressColors: const [
                                              Color(0xFFFFA726),
                                              Color(0xFF5B9BD5),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                            const SizedBox(height: 24),
                            _sectionTitle('SESSION HISTORY'),
                            const SizedBox(height: 12),

                            // Session history
                            sessionHistory.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: Text(
                                        'No session history available',
                                        style: TextStyle(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: sessionHistory.length,
                                    itemBuilder: (context, index) {
                                      final s = sessionHistory[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: SessionHistoryItem(
                                          title: s['title'] ?? 'Untitled',
                                          time: _formatTime(s['start_time']),
                                          students: '${s['total_students'] ?? 0} students',
                                        ),
                                      );
                                    },
                                  ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSessionDialog,
        backgroundColor: const Color(0xFF5B9BD5),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;
    
    return Container(
      color: cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left column with greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Hi, ${widget.lecturerName}!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('👋', style: TextStyle(fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready to engage your students?',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Avatar
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    lecturerData: {
                      'id': widget.lecturerId,
                      'name': widget.lecturerName,
                      'email': 'lecturer@example.com',
                      'role': 'lecturer',
                      'department': 'CS',
                      'employee_id': 'L123',
                      'avatar_url': '',
                      'push_notifications': true,
                      'email_updates': true,
                      'created_at': DateTime.now().toIso8601String(),
                    },
                  ),
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

/* -------------------------
   Create Session Dialog
   ------------------------- */
class _CreateSessionDialog extends StatefulWidget {
  final String lecturerId;
  final VoidCallback onSessionCreated;

  const _CreateSessionDialog({
    required this.lecturerId,
    required this.onSessionCreated,
  });

  @override
  State<_CreateSessionDialog> createState() => _CreateSessionDialogState();
}

class _CreateSessionDialogState extends State<_CreateSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _sessionNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final supabase = Supabase.instance.client;

  String? _selectedClassId;
  List<Map<String, dynamic>> _classes = [];
  bool _isLoadingClasses = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    _sessionNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    try {
      final response = await supabase
          .from('classes')
          .select('id, title, code')
          .eq('lecturer_id', widget.lecturerId);

      final list = (response ?? <dynamic>[])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (mounted) {
        setState(() {
          _classes = list;
          _isLoadingClasses = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingClasses = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading classes: $e')),
        );
      }
    }
  }

  Future<void> _createSession() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Please select a class')));
      }
      return;
    }

    if (mounted) setState(() => _isCreating = true);

    try {
      await supabase.from('sessions').insert({
        'class_id': _selectedClassId,
        'title': _sessionNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'start_time': DateTime.now().toIso8601String(),
        'status': 'active',
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session created successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        widget.onSessionCreated();
      }
    } catch (e) {
      if (mounted) setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error creating session: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header dengan padding yang aman
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Create New Session',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 22,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Divider(height: 1, color: Colors.grey[300]),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Select class
                      const Text(
                        'Select Class',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      _isLoadingClasses
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : DropdownButtonFormField<String>(
                              value: _selectedClassId,
                              decoration: InputDecoration(
                                hintText: 'Choose a class',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              items: _classes.map((cls) {
                                return DropdownMenuItem<String>(
                                  value: cls['id'].toString(),
                                  child: Text('${cls['code']} - ${cls['title']}'),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedClassId = v),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a class';
                                }
                                return null;
                              },
                            ),
                      const SizedBox(height: 16),

                      // Session name
                      const Text(
                        'Session Name',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _sessionNameController,
                        decoration: InputDecoration(
                          hintText: 'e.g., Introduction to AI',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a session name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      const Text(
                        'Description (Optional)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Brief description of the session...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Pro tip
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💡', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pro Tip',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1976D2),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'A clear session name helps students identify and join the right class quickly.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom buttons dengan padding yang aman
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B9BD5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'CREATE SESSION',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}