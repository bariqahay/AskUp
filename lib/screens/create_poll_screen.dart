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

  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _questionController.addListener(() => setState(() {}));
    _timeLimitController.addListener(() => setState(() {}));
    for (var controller in _optionControllers) {
      controller.addListener(() => setState(() {}));
    }
  }

  void _addOption() {
    if (_optionControllers.length < 10) {
      setState(() {
        final newController = TextEditingController();
        newController.addListener(() => setState(() {}));
        _optionControllers.add(newController);
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
    if (_questionController.text.trim().isEmpty) {
      _showSnackBar('Please enter a poll question', Colors.red);
      return;
    }

    if (_selectedPollType == 'multiple_choice') {
      final validOptions = _optionControllers
          .where((c) => c.text.trim().isNotEmpty)
          .toList();
      
      if (validOptions.length < 2) {
        _showSnackBar('Please add at least 2 options', Colors.orange);
        return;
      }
    }

    setState(() => _isCreating = true);

    try {
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
        final yesNoOptions = [
          {'poll_id': pollId, 'option_text': 'Yes', 'votes_count': 0},
          {'poll_id': pollId, 'option_text': 'No', 'votes_count': 0},
        ];
        await _supabase.from('poll_options').insert(yesNoOptions);
      }

      if (mounted) {
        _showSnackBar('Poll created successfully! 🎉', Colors.green);
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isCreating = false);
      _showSnackBar('Error creating poll: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Create Poll',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('📊', style: TextStyle(fontSize: 20)),
              ],
            ),
            Text(
              'Engage your students with live polling',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          if (_tabController.index == 0)
            TextButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Preview'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5B9BD5),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Modern Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B9BD5), Color(0xFF4A8BC2)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B9BD5).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  icon: Icon(Icons.create, size: 20),
                  text: 'CREATE',
                ),
                Tab(
                  icon: Icon(Icons.preview, size: 20),
                  text: 'PREVIEW',
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCreateTab(isDark, textColor),
                _buildPreviewTab(isDark, textColor),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _tabController.index == 0
          ? _buildBottomBar(isDark)
          : null,
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _isCreating ? null : _createPoll,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B9BD5),
              disabledBackgroundColor: Colors.grey[400],
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
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rocket_launch, size: 22),
                      SizedBox(width: 12),
                      Text(
                        'LAUNCH POLL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateTab(bool isDark, Color textColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Indicator
          _buildStepIndicator(isDark),
          
          const SizedBox(height: 24),

          // Poll Type Selection
          _buildSectionHeader('1. Choose Poll Type', Icons.category_outlined, isDark, textColor),
          const SizedBox(height: 16),
          
          _buildPollTypeCard(
            icon: '📊',
            title: 'Multiple Choice',
            subtitle: 'Let students pick from options',
            value: 'multiple_choice',
            color: const Color(0xFF5B9BD5),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          
          _buildPollTypeCard(
            icon: '👍',
            title: 'Yes or No',
            subtitle: 'Quick binary decision',
            value: 'yes_no',
            color: const Color(0xFF34C759),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          
          _buildPollTypeCard(
            icon: '⭐',
            title: 'Star Rating',
            subtitle: 'Get quality feedback (1-5)',
            value: 'rating_scale',
            color: const Color(0xFFF5A623),
            isDark: isDark,
          ),

          const SizedBox(height: 32),

          // Poll Question
          _buildSectionHeader('2. Write Your Question', Icons.help_outline, isDark, textColor),
          const SizedBox(height: 16),
          
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
              ),
              boxShadow: isDark ? [] : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _questionController,
              maxLines: 4,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'e.g., What is the capital of Indonesia?',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                  fontSize: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(20),
                counter: Text(
                  '${_questionController.text.length}/200',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ),
              maxLength: 200,
            ),
          ),

          const SizedBox(height: 32),

          // Options Section (for Multiple Choice)
          if (_selectedPollType == 'multiple_choice') ...[
            _buildSectionHeader('3. Add Answer Options', Icons.list_alt, isDark, textColor),
            const SizedBox(height: 16),

            ..._optionControllers.asMap().entries.map((entry) {
              return _buildOptionField(entry.key, entry.value, isDark, textColor);
            }).toList(),
            
            const SizedBox(height: 12),
            
            if (_optionControllers.length < 10)
              OutlinedButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text(
                  'Add Another Option',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF5B9BD5),
                  side: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                ),
              ),
            
            const SizedBox(height: 32),
          ],

          // Settings Section
          _buildSectionHeader('${_selectedPollType == 'multiple_choice' ? '4' : '3'}. Poll Settings', Icons.settings_outlined, isDark, textColor),
          const SizedBox(height: 16),

          // Live Results Toggle
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _showResultsLive
                        ? const Color(0xFF5B9BD5).withOpacity(0.1)
                        : (isDark ? Colors.grey[800] : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.visibility,
                    color: _showResultsLive ? const Color(0xFF5B9BD5) : Colors.grey[400],
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Results',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Show results as students vote',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _showResultsLive,
                  onChanged: (value) => setState(() => _showResultsLive = value),
                  activeColor: const Color(0xFF5B9BD5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Time Limit
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _timeLimitController.text.isNotEmpty
                            ? const Color(0xFFF5A623).withOpacity(0.1)
                            : (isDark ? Colors.grey[800] : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.timer_outlined,
                        color: _timeLimitController.text.isNotEmpty
                            ? const Color(0xFFF5A623)
                            : Colors.grey[400],
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time Limit',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Optional time constraint',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _timeLimitController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textColor, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Enter minutes (optional)',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    suffixText: _timeLimitController.text.isNotEmpty ? 'min' : null,
                    suffixStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 80), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    final steps = _selectedPollType == 'multiple_choice' ? 4 : 3;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF5B9BD5).withOpacity(0.1),
            const Color(0xFF4A8BC2).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF5B9BD5).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF5B9BD5),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Complete $steps simple steps to launch your poll',
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark, Color textColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF5B9BD5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF5B9BD5),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionField(int index, TextEditingController controller, bool isDark, Color textColor) {
    final letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B9BD5), Color(0xFF4A8BC2)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B9BD5).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                letters[index],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: controller.text.isNotEmpty
                      ? const Color(0xFF5B9BD5).withOpacity(0.3)
                      : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
                ),
              ),
              child: TextField(
                controller: controller,
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Option ${index + 1}',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          if (_optionControllers.length > 2) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
              onPressed: () => _removeOption(index),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPollTypeCard({
    required String icon,
    required String title,
    required String subtitle,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    final isSelected = _selectedPollType == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedPollType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(isDark ? 0.15 : 0.08)
              : (isDark ? Colors.grey[850] : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.15)
                    : (isDark ? Colors.grey[800] : Colors.grey[50]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 28),
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
                      fontSize: 16,
                      color: isSelected ? color : (isDark ? Colors.grey[200] : Colors.grey[900]),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedScale(
              scale: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTab(bool isDark, Color textColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Preview Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF5B9BD5).withOpacity(isDark ? 0.2 : 0.1),
                  const Color(0xFF4A8BC2).withOpacity(isDark ? 0.15 : 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF5B9BD5).withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B9BD5).withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.white),
                      SizedBox(width: 6),
                                              Text(
                        'LIVE POLL',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Question
                Text(
                  _questionController.text.isEmpty
                      ? 'Your question will appear here...'
                      : _questionController.text,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                    color: textColor,
                  ),
                ),
                
                const SizedBox(height: 24),

                // Options Preview
                if (_selectedPollType == 'multiple_choice')
                  ..._buildMultipleChoicePreview(isDark, textColor),
                if (_selectedPollType == 'yes_no')
                  ..._buildYesNoPreview(isDark),
                if (_selectedPollType == 'rating_scale')
                  _buildRatingScalePreview(isDark),

                // Settings Info
                if (_timeLimitController.text.isNotEmpty || _showResultsLive) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800]?.withOpacity(0.5) : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        if (_timeLimitController.text.isNotEmpty) ...[
                          Icon(
                            Icons.timer,
                            size: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_timeLimitController.text} min limit',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (_timeLimitController.text.isNotEmpty && _showResultsLive)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '•',
                              style: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
                            ),
                          ),
                        if (_showResultsLive) ...[
                          Icon(
                            Icons.visibility,
                            size: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Live results',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.blue[900]?.withOpacity(0.2) : Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.blue[700]! : Colors.blue[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: isDark ? Colors.blue[300] : Colors.blue[700],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This is how students will see your poll in real-time',
                    style: TextStyle(
                      color: isDark ? Colors.blue[300] : Colors.blue[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMultipleChoicePreview(bool isDark, Color textColor) {
    final validOptions = _optionControllers
        .where((c) => c.text.trim().isNotEmpty)
        .toList();

    if (validOptions.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800]?.withOpacity(0.5) : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Add options in the Create tab to see preview',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return validOptions.asMap().entries.map((entry) {
      final letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800]?.withOpacity(0.5) : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF5B9BD5),
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    letters[entry.key],
                    style: const TextStyle(
                      color: Color(0xFF5B9BD5),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  entry.value.text,
                  style: TextStyle(
                    fontSize: 15,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildYesNoPreview(bool isDark) {
    return [
      _buildYesNoButton('👍', 'Yes', const Color(0xFF34C759), isDark),
      const SizedBox(height: 12),
      _buildYesNoButton('👎', 'No', Colors.red, isDark),
    ];
  }

  Widget _buildYesNoButton(String emoji, String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800]?.withOpacity(0.5) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
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

  Widget _buildRatingScalePreview(bool isDark) {
    return Column(
      children: [
        Text(
          'Tap to rate',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800]?.withOpacity(0.5) : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.star_border_rounded,
                  color: const Color(0xFFF5A623),
                  size: 42,
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '5',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
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