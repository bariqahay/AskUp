import 'package:flutter/material.dart';

class StudentSessionDetailScreen extends StatefulWidget {
  final String title;
  final String lecturer;
  final String code;

  const StudentSessionDetailScreen({
    super.key,
    required this.title,
    required this.lecturer,
    required this.code,
  });

  @override
  State<StudentSessionDetailScreen> createState() => _StudentSessionDetailScreenState();
}

class _StudentSessionDetailScreenState extends State<StudentSessionDetailScreen> {
  int _selectedTab = 0;
  final TextEditingController _questionController = TextEditingController();
  bool _isAnonymous = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  void _showAskQuestionDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '0/500',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
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
                        setState(() {
                          _isAnonymous = value ?? false;
                        });
                        Navigator.pop(context);
                        _showAskQuestionDialog();
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
                            '• Be clear and specific about what you want to know',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            '• Briefly explain why this question is important',
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
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Question sent successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
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
            child: _selectedTab == 0
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildQuestionCard(
          question: 'Can you explain the difference between supervised and unsupervised learning?',
          askedBy: 'Anonymous',
          number: 21,
          isAnswered: true,
          answer: 'Prof. Smith: Pertanyaan bagus! Supervised learning menggunakan data yang dilabel...',
        ),
        const SizedBox(height: 12),
        _buildQuestionCard(
          question: 'What are the main challenges when implementing neural networks?',
          askedBy: 'Student #6',
          number: 6,
          isAnswered: false,
        ),
        const SizedBox(height: 12),
        _buildQuestionCard(
          question: 'How does backpropagation work in neural networks?',
          askedBy: 'Anonymous',
          number: 15,
          isAnswered: false,
        ),
      ],
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
            color: Colors.black.withValues(alpha: 0.05),
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
              Icon(
                Icons.more_vert,
                size: 18,
                color: Colors.grey[400],
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPollCard(
          question: 'Which machine learning algorithm do you find most interesting?',
          options: [
            PollOption('Neural Networks', 0.35, true),
            PollOption('Decision Trees', 0.25, false),
            PollOption('Support Vector Machines', 0.20, false),
            PollOption('Random Forest', 0.20, false),
          ],
          totalVotes: 30,
          isActive: true,
        ),
        const SizedBox(height: 12),
        _buildPollCard(
          question: 'Have you completed the assignment on supervised learning?',
          options: [
            PollOption('Yes, fully completed', 0.60, false),
            PollOption('Partially completed', 0.25, false),
            PollOption('Not yet started', 0.15, false),
          ],
          totalVotes: 28,
          isActive: false,
        ),
      ],
    );
  }

  Widget _buildPollCard({
    required String question,
    required List<PollOption> options,
    required int totalVotes,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
          ...options.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildPollOption(option),
              )),
          const SizedBox(height: 8),
          if (isActive)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vote submitted!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B9BD5),
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
    );
  }

  Widget _buildPollOption(PollOption option) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: option.isSelected ? const Color(0xFF5B9BD5) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: option.isSelected ? const Color(0xFF5B9BD5) : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Radio<bool>(
            value: true,
            groupValue: option.isSelected,
            onChanged: (value) {},
            activeColor: Colors.white,
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (option.isSelected) return Colors.white;
              return Colors.grey[400];
            }),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.text,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: option.isSelected ? Colors.white : const Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: option.percentage,
                          backgroundColor: option.isSelected
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            option.isSelected ? Colors.white : const Color(0xFF5B9BD5),
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(option.percentage * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: option.isSelected ? Colors.white : Colors.grey[700],
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
            'Checked in at 9:15 AM',
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
            'September 16, 2025',
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

class PollOption {
  final String text;
  final double percentage;
  final bool isSelected;

  PollOption(this.text, this.percentage, this.isSelected);
}
