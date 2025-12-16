import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_session_detail_screen.dart';

class QRScannerScreen extends StatefulWidget {
  final String studentId;
  final String studentName; // Add this parameter

  const QRScannerScreen({
    super.key,
    required this.studentId,
    required this.studentName, // Add this parameter
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final supabase = Supabase.instance.client;
  MobileScannerController cameraController = MobileScannerController();
  bool isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _processQRCode(String? code) async {
    if (code == null || isProcessing) return;

    setState(() => isProcessing = true);

    try {
      // Format QR: "askup://session/{session_id}" atau langsung session_id
      String sessionId = code;
      if (code.startsWith('askup://session/')) {
        sessionId = code.replaceFirst('askup://session/', '');
      }

      // Cek apakah session valid
      final sessionData = await supabase
          .from('sessions')
          .select('id, title, class_id, session_code, classes!inner(title, code, lecturer_id)')
          .eq('id', sessionId)
          .eq('status', 'active')
          .maybeSingle();

      if (sessionData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session not found or inactive'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => isProcessing = false);
        return;
      }

      // Check-in student ke session (join session)
      await supabase.from('session_participants').insert({
        'session_id': sessionId,
        'student_id': widget.studentId,
      });

      if (mounted) {
        // Navigate ke session detail
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StudentSessionDetailScreen(
              title: sessionData['title'],
              lecturer: sessionData['classes']['title'],
              code: sessionData['classes']['code'],
              sessionId: sessionId,
              studentId: widget.studentId,
              studentName: widget.studentName, // Pass the student name
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().contains('duplicate') ? 'Already joined this session' : e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan QR Code',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              cameraController.torchEnabled ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                _processQRCode(barcode.rawValue);
              }
            },
          ),
          // Overlay with scanning area
          CustomPaint(
            painter: ScannerOverlay(),
            child: Container(),
          ),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Position the QR code within the frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (isProcessing) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = size.width * 0.7;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;

    // Create path for overlay with hole
    final Path overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final Path scanAreaPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize),
        const Radius.circular(16),
      ));

    // Subtract scan area from overlay
    final Path finalPath = Path.combine(
      PathOperation.difference,
      overlayPath,
      scanAreaPath,
    );

    // Dark overlay with transparent center
    final Paint overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6);

    canvas.drawPath(finalPath, overlayPaint);

    // Border
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF5B9BD5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize),
        const Radius.circular(16),
      ),
      borderPaint,
    );

    // Corner lines
    final Paint cornerPaint = Paint()
      ..color = const Color(0xFF5B9BD5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 30;

    // Top-left
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), cornerPaint);

    // Top-right
    canvas.drawLine(Offset(left + scanAreaSize, top), Offset(left + scanAreaSize - cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left + scanAreaSize, top), Offset(left + scanAreaSize, top + cornerLength), cornerPaint);

    // Bottom-left
    canvas.drawLine(Offset(left, top + scanAreaSize), Offset(left + cornerLength, top + scanAreaSize), cornerPaint);
    canvas.drawLine(Offset(left, top + scanAreaSize), Offset(left, top + scanAreaSize - cornerLength), cornerPaint);

    // Bottom-right
    canvas.drawLine(Offset(left + scanAreaSize, top + scanAreaSize), Offset(left + scanAreaSize - cornerLength, top + scanAreaSize), cornerPaint);
    canvas.drawLine(Offset(left + scanAreaSize, top + scanAreaSize), Offset(left + scanAreaSize, top + scanAreaSize - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}