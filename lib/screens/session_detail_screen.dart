import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dashboard_screen.dart';
import 'create_poll_screen.dart';
import 'qa_management_screen.dart';

class SessionDetailScreen extends StatefulWidget {
  final String sessionId;
  final String title;
  final String classCode;
  final int totalStudents;
  final String lecturerId;
  final String lecturerName;

  const SessionDetailScreen({
    super.key,
    required this.sessionId,
    required this.title,
    required this.classCode,
    required this.totalStudents,
    required this.lecturerId,
    required this.lecturerName,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final supabase = Supabase.instance.client;

  bool _loading = true;
  bool _sessionActive = true;

  int presentCount = 0;
  int newQuestionsCount = 0;
  int activePollCount = 0;
  String latestPollId = '';

  RealtimeChannel? _participantsChannel;
  RealtimeChannel? _questionsChannel;
  RealtimeChannel? _pollsChannel;

  @override
  void initState() {
    super.initState();
    _initData();
    _subscribeRealtime();
  }

  Future<void> _initData() async {
    setState(() => _loading = true);
    try {
      /// 1. session status
      final sessionRes = await supabase
          .from('sessions')
          .select('status')
          .eq('id', widget.sessionId)
          .maybeSingle();

      if (sessionRes != null) {
        _sessionActive = sessionRes['status'] == 'active';
      }

      /// 2. present count
      final participants = await supabase
          .from('session_participants')
          .select('id')
          .eq('session_id', widget.sessionId);

      presentCount = participants.length;

      /// 3. questions count
      final questions = await supabase
          .from('questions')
          .select('id')
          .eq('session_id', widget.sessionId);
      newQuestionsCount = questions.length;

      /// 4. polls count
      final polls = await supabase
          .from('polls')
          .select('id')
          .eq('session_id', widget.sessionId);
      activePollCount = polls.length;

      /// 5. latest poll
      final latest = await supabase
          .from('polls')
          .select('id')
          .eq('session_id', widget.sessionId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (latest != null) {
        latestPollId = latest['id'];
      }
    } catch (e) {
      debugPrint('init data error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _subscribeRealtime() {
    _participantsChannel = supabase.channel('participants-${widget.sessionId}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'session_participants',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'session_id',
          value: widget.sessionId,
        ),
        callback: (payload) {
          if (payload.eventType == PostgresChangeEvent.insert) {
            setState(() => presentCount++);
          } else if (payload.eventType == PostgresChangeEvent.delete) {
            setState(() => presentCount--);
          }
        },
      )
      ..subscribe();

    _questionsChannel = supabase.channel('questions-${widget.sessionId}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'questions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'session_id',
          value: widget.sessionId,
        ),
        callback: (payload) {
          if (payload.eventType == PostgresChangeEvent.insert) {
            setState(() => newQuestionsCount++);
          } else if (payload.eventType == PostgresChangeEvent.delete) {
            setState(() => newQuestionsCount--);
          }
        },
      )
      ..subscribe();

    _pollsChannel = supabase.channel('polls-${widget.sessionId}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'polls',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'session_id',
          value: widget.sessionId,
        ),
        callback: (payload) {
          if (payload.eventType == PostgresChangeEvent.insert) {
            setState(() {
              activePollCount++;
              latestPollId = payload.newRecord['id'];
            });
          } else if (payload.eventType == PostgresChangeEvent.delete) {
            setState(() => activePollCount--);
          }
        },
      )
      ..subscribe();
  }

  Future<void> _endSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('End Session'),
        content: const Text('Are you sure to end this session?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('End')),
        ],
      ),
    );
    if (confirm != true) return;

    await supabase.from('sessions').update({
      'status': 'completed',
      'end_time': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', widget.sessionId);

    setState(() => _sessionActive = false);

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Session ended')));
    }
  }

  @override
  void dispose() {
    _participantsChannel?.unsubscribe();
    _questionsChannel?.unsubscribe();
    _pollsChannel?.unsubscribe();
    super.dispose();
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
    required Color cardColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Theme variables untuk dark mode support
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              'Code: ${widget.classCode}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /// Student Check-in Card with QR
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isDark ? [] : [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Student Check-in',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: QrImageView(
                            data: 'askup://session/${widget.sessionId}',
                            size: 150,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.classCode,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Students can scan the QR code or enter the code to join',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Stats Row
                  Row(
                    children: [
                      _statCard(
                        icon: Icons.person,
                        value: '$presentCount/${widget.totalStudents}',
                        label: 'Present',
                        iconColor: Colors.blue,
                        isDark: isDark,
                        cardColor: cardColor,
                        textColor: textColor,
                      ),
                      const SizedBox(width: 12),
                      _statCard(
                        icon: Icons.help_outline,
                        value: '$newQuestionsCount',
                        label: 'New Questions',
                        iconColor: Colors.orange,
                        isDark: isDark,
                        cardColor: cardColor,
                        textColor: textColor,
                      ),
                      const SizedBox(width: 12),
                      _statCard(
                        icon: Icons.poll,
                        value: '$activePollCount',
                        label: 'Active Poll',
                        iconColor: Colors.green,
                        isDark: isDark,
                        cardColor: cardColor,
                        textColor: textColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// Manage Q&A Button
                  _actionButton(
                    title: 'MANAGE Q&A',
                    subtitle: 'Review and respond to questions',
                    icon: Icons.question_answer,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QAManagementScreen(sessionId: widget.sessionId),
                        ),
                      );
                    },
                    isDark: isDark,
                    cardColor: cardColor,
                  ),

                  const SizedBox(height: 12),

                  /// Create Poll Button
                  _actionButton(
                    title: 'CREATE POLL',
                    subtitle: 'Engage students with questions',
                    icon: Icons.poll,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreatePollScreen(sessionId: widget.sessionId),
                        ),
                      );
                    },
                    isDark: isDark,
                    cardColor: cardColor,
                  ),

                  const SizedBox(height: 20),

                  /// Session Status Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isDark ? [] : [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 12,
                              color: _sessionActive
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _sessionActive
                                  ? 'Session Active'
                                  : 'Session Ended',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _sessionActive
                              ? 'Students can join using the QR code or session code. The session will remain active until you end it.'
                              : 'This session has ended. Students can no longer join.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        if (_sessionActive) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton(
                              onPressed: () async {
                                await _endSession();

                                if (mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DashboardScreen(
                                        lecturerId: widget.lecturerId,
                                        lecturerName: widget.lecturerName,
                                      ),
                                    ),
                                    (route) => false,
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('End Session'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}