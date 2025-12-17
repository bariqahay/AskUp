import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class LecturerPollResultsScreen extends StatefulWidget {
  final String sessionId;
  final String sessionTitle;

  const LecturerPollResultsScreen({
    Key? key,
    required this.sessionId,
    required this.sessionTitle,
  }) : super(key: key);

  @override
  State<LecturerPollResultsScreen> createState() => _LecturerPollResultsScreenState();
}

class _LecturerPollResultsScreenState extends State<LecturerPollResultsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _polls = [];
  bool _isLoading = true;
  RealtimeChannel? _pollsChannel;
  RealtimeChannel? _votesChannel;

  @override
  void initState() {
    super.initState();
    _loadPolls();
    _setupRealtime();
  }

  @override
  void dispose() {
    _pollsChannel?.unsubscribe();
    _votesChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadPolls() async {
    setState(() => _isLoading = true);
    try {
      final polls = await _supabase
          .from('polls')
          .select('*, poll_options(*)')
          .eq('session_id', widget.sessionId)
          .order('created_at', ascending: false);

      // Get total votes for each poll (manual count)
      for (var poll in polls) {
        final votes = await _supabase
            .from('poll_votes')
            .select('id')
            .eq('poll_id', poll['id']);
        poll['total_votes'] = votes.length; // ✅ Simple count
      }

      setState(() {
        _polls = List<Map<String, dynamic>>.from(polls);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading polls: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupRealtime() {
    _pollsChannel = _supabase
        .channel('polls-${widget.sessionId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'polls',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: widget.sessionId,
          ),
          callback: (payload) => _loadPolls(),
        )
        .subscribe();

    _votesChannel = _supabase
        .channel('poll-votes-${widget.sessionId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'poll_votes',
          callback: (payload) => _loadPolls(),
        )
        .subscribe();
  }

  Future<void> _deletePoll(String pollId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Poll?'),
        content: const Text('This action cannot be undone. All votes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('polls').delete().eq('id', pollId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Poll deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadPolls();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📊', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  'Poll Results',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            Text(
              widget.sessionTitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _polls.isEmpty
              ? _buildEmptyState(isDark)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _polls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildPollCard(_polls[index], isDark, textColor),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No polls created yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first poll to engage students',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollCard(Map<String, dynamic> poll, bool isDark, Color textColor) {
    final options = poll['poll_options'] as List;
    final totalVotes = poll['total_votes'] as int;
    final pollType = poll['poll_type'] as String;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
        boxShadow: isDark
            ? []
            : [
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.red),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B9BD5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.how_to_vote,
                          size: 14,
                          color: const Color(0xFF5B9BD5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$totalVotes ${totalVotes == 1 ? 'vote' : 'votes'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5B9BD5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: textColor, size: 20),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deletePoll(poll['id']);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 12),
                            Text('Delete Poll', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Question
          Text(
            poll['question'],
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 8),

          // Poll Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPollTypeColor(pollType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _getPollTypeLabel(pollType),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _getPollTypeColor(pollType),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Results
          if (totalVotes > 0) ...[
            // Chart
            if (options.length <= 5)
              SizedBox(
                height: 200,
                child: _buildBarChart(options, totalVotes, isDark),
              )
            else
              _buildListResults(options, totalVotes, isDark, textColor),

            const SizedBox(height: 20),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No votes yet. Results will appear as students vote.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Detailed Results
          ...options.map((option) {
            final percentage = totalVotes > 0
                ? (option['votes_count'] / totalVotes * 100)
                : 0.0;
            return _buildOptionResult(
              option['option_text'],
              option['votes_count'],
              percentage,
              isDark,
              textColor,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBarChart(List options, int totalVotes, bool isDark) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: options.map((o) => (o['votes_count'] as int).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= options.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    String.fromCharCode(65 + value.toInt()),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: options.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: (entry.value['votes_count'] as int).toDouble(),
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF5B9BD5),
                    Color(0xFF4A8BC2),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 32,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListResults(List options, int totalVotes, bool isDark, Color textColor) {
    return Column(
      children: options.map((option) {
        final percentage = totalVotes > 0
            ? (option['votes_count'] / totalVotes * 100)
            : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '${percentage.toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5B9BD5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 10,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF5B9BD5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${option['votes_count']}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOptionResult(String text, int votes, double percentage, bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800]?.withOpacity(0.5) : Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 6,
                      backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF5B9BD5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${percentage.toInt()}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5B9BD5),
                  ),
                ),
                Text(
                  '$votes ${votes == 1 ? 'vote' : 'votes'}',
                  style: TextStyle(
                    fontSize: 11,
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

  Color _getPollTypeColor(String type) {
    switch (type) {
      case 'multiple_choice':
        return const Color(0xFF5B9BD5);
      case 'yes_no':
        return const Color(0xFF34C759);
      case 'rating_scale':
        return const Color(0xFFF5A623);
      default:
        return Colors.grey;
    }
  }

  String _getPollTypeLabel(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'yes_no':
        return 'Yes/No';
      case 'rating_scale':
        return 'Rating Scale';
      default:
        return type;
    }
  }
}