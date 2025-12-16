import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePollScreen extends StatefulWidget {
  final String sessionId;

  const CreatePollScreen({Key? key, required this.sessionId}) : super(key: key);

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _questionController = TextEditingController();
  final _timeLimitController = TextEditingController();
  
  late TabController _tabController;
  String _selectedPollType = 'multiple_choice';
  bool _showResultsLive = true;
  bool _isCreating = false;

  // Multiple Choice Options
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _addOption() {
    if (_optionControllers.length < 10) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  Future<void> _createPoll() async {
    // Validation
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a poll question')),
      );
      return;
    }

    if (_selectedPollType == 'multiple_choice') {
      final validOptions = _optionControllers
          .where((c) => c.text.trim().isNotEmpty)
          .toList();
      
      if (validOptions.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least 2 options')),
        );
        return;
      }
    }

    setState(() => _isCreating = true);

    try {
      // Insert poll
      final pollResponse = await _supabase
          .from('polls')
          .insert({
            'session_id': widget.sessionId,
            'question': _questionController.text.trim(),
            'poll_type': _selectedPollType,
            'show_results_live': _showResultsLive,
            'time_limit_minutes': _timeLimitController.text.isNotEmpty 
                ? int.tryParse(_timeLimitController.text) 
                : null,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final pollId = pollResponse['id'];

      // Insert options for multiple choice and rating scale
      if (_selectedPollType == 'multiple_choice') {
        final options = _optionControllers
            .where((c) => c.text.trim().isNotEmpty)
            .map((c) => {
                  'poll_id': pollId,
                  'option_text': c.text.trim(),
                  'votes_count': 0,
                })
            .toList();

        await _supabase.from('poll_options').insert(options);
      } else if (_selectedPollType == 'rating_scale') {
        // Create 5 options for rating scale (1-5 stars)
        final ratingOptions = List.generate(
          5,
          (index) => {
            'poll_id': pollId,
            'option_text': '${index + 1} Star${index + 1 > 1 ? 's' : ''}',
            'votes_count': 0,
          },
        );

        await _supabase.from('poll_options').insert(ratingOptions);
      } else if (_selectedPollType == 'yes_no') {
        // Create Yes/No options
        final yesNoOptions = [
          {'poll_id': pollId, 'option_text': 'Yes', 'votes_count': 0},
          {'poll_id': pollId, 'option_text': 'No', 'votes_count': 0},
        ];

        await _supabase.from('poll_options').insert(yesNoOptions);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Poll created successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating poll: $e')),
      );
    }
  }

  void _showPreview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Poll Preview'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _questionController.text.isEmpty
                    ? 'Your question will appear here'
                    : _questionController.text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Type: ${_selectedPollType.replaceAll('_', ' ').toUpperCase()}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              if (_selectedPollType == 'multiple_choice') ...[
                const Text('Options:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._optionControllers.asMap().entries.map((entry) {
                  if (entry.value.text.trim().isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + entry.key),
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(entry.value.text)),
                      ],
                    ),
                  );
                }).toList(),
              ],
              if (_selectedPollType == 'yes_no') ...[
                const Text('Options:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildPreviewOption('👍', 'Yes'),
                const SizedBox(height: 8),
                _buildPreviewOption('👎', 'No'),
              ],
              if (_selectedPollType == 'rating_scale') ...[
                const Text('Rating Scale:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => Icon(
                      Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewOption(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
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
            Text(
              'CREATE POLL',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Engage students with interactive questions',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[700]
                    : Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              labelColor: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
              unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'CREATE'),
                Tab(text: 'PREVIEW'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCreateTab(),
                _buildPreviewTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poll Type Section
          Text(
            'Poll Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
          const SizedBox(height: 12),

          // Multiple Choice Option
          _buildPollTypeCard(
            icon: '📊',
            title: 'Multiple Choice',
            subtitle: 'A/B/C/D Options',
            value: 'multiple_choice',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),

          // Yes/No Option
          _buildPollTypeCard(
            icon: '👍',
            title: 'Yes/No',
            subtitle: 'Simple Binary Choice',
            value: 'yes_no',
            color: Colors.green,
          ),
          const SizedBox(height: 12),

          // Rating Scale Option
          _buildPollTypeCard(
            icon: '⭐',
            title: 'Rating Scale',
            subtitle: '1-5 Star Rating',
            value: 'rating_scale',
            color: Colors.amber,
          ),

          const SizedBox(height: 24),

          // Poll Question Section
          Text(
            'Poll Question',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _questionController,
            maxLines: 3,
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black),
            decoration: InputDecoration(
              hintText: 'Ask a clear, engaging question...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Options for Multiple Choice
          if (_selectedPollType == 'multiple_choice') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Options',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Add Option'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ..._optionControllers.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + entry.key),
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: entry.value,
                        decoration: InputDecoration(
                          hintText: 'Option ${entry.key + 1}',
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
                    if (_optionControllers.length > 2)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => _removeOption(entry.key),
                      ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 12),
          ],

          // Poll Settings Section
          const Text(
            'Poll Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Show Results Live
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Show Results Live',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Students can see results as others vote',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _showResultsLive,
                  onChanged: (value) {
                    setState(() => _showResultsLive = value);
                  },
                  activeColor: Colors.blue,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Time Limit
          const Text(
            'Time limit (minutes)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _timeLimitController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'No Limit',
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: Icon(Icons.timer_outlined, color: Colors.grey[400]),
            ),
          ),

          const SizedBox(height: 32),

          // Start Poll Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isCreating ? null : _createPoll,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isCreating
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '🎉',
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'START POLL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.poll, color: Colors.blue, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'LIVE POLL',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _questionController.text.isEmpty
                      ? 'Your question will appear here'
                      : _questionController.text,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Preview based on poll type
                if (_selectedPollType == 'multiple_choice')
                  ..._buildMultipleChoicePreview(),
                if (_selectedPollType == 'yes_no')
                  ..._buildYesNoPreview(),
                if (_selectedPollType == 'rating_scale')
                  _buildRatingScalePreview(),

                const SizedBox(height: 16),

                // Settings preview
                if (_timeLimitController.text.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Time limit: ${_timeLimitController.text} minutes',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This is how students will see your poll',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMultipleChoicePreview() {
    final validOptions = _optionControllers
        .where((c) => c.text.trim().isNotEmpty)
        .toList();

    if (validOptions.isEmpty) {
      return [
        Text(
          'Add options to see preview',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ];
    }

    return validOptions.asMap().entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + entry.key),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.value.text,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildYesNoPreview() {
    return [
      _buildYesNoButton('👍', 'Yes', Colors.green),
      const SizedBox(height: 12),
      _buildYesNoButton('👎', 'No', Colors.red),
    ];
  }

  Widget _buildYesNoButton(String emoji, String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingScalePreview() {
    return Column(
      children: [
        const Text(
          'Tap to rate',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.star_border,
                color: Colors.amber,
                size: 40,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPollTypeCard({
    required String icon,
    required String title,
    required String subtitle,
    required String value,
    required Color color,
  }) {
    final isSelected = _selectedPollType == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPollType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSelected ? color : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _timeLimitController.dispose();
    _tabController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}