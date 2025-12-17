import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_session_detail_screen.dart';

class QRScannerScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const QRScannerScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final supabase = Supabase.instance.client;
  final MobileScannerController cameraController = MobileScannerController();

  bool _locked = false; // 🔒 LOGIC LOCK (NOT UI STATE)

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

    // ================= CORE LOGIC =================

  Future<void> _processQRCode(String? rawCode) async {
    if (_locked) return;
    if (rawCode == null || rawCode.trim().isEmpty) return;

    _locked = true;
    cameraController.stop();

    try {
      String sessionId = rawCode.trim();
      if (sessionId.startsWith('askup://session/')) {
        sessionId = sessionId.replaceFirst('askup://session/', '');
      }

      if (sessionId.isEmpty) {
        _fail('Invalid QR code');
        return;
      }

      final session = await supabase
          .from('sessions')
          .select(
            'id, title, status, classes!inner(title, code)',
          )
          .eq('id', sessionId)
          .eq('status', 'active')
          .maybeSingle();

      if (session == null) {
        _fail('Session not found or inactive');
        return;
      }

      await supabase.from('session_participants').insert({
        'session_id': session['id'],
        'student_id': widget.studentId,
      });

      if (!mounted) return;

      // ✅ JANGAN POP DULU, langsung push Session Detail
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentSessionDetailScreen(
            sessionId: session['id'],
            title: session['title'],
            lecturer: session['classes']['title'],
            code: session['classes']['code'],
            studentId: widget.studentId,
            studentName: widget.studentName,
          ),
        ),
      );

      // ✅ Pas balik dari Session Detail, baru pop QR Scanner dengan true
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      final msg = e.toString().contains('duplicate')
          ? 'You already joined this session'
          : 'Failed to join session';

      _fail(msg);
    }
  }

  // ================= ERROR HANDLER =================

  void _fail(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );

    _locked = false;
    cameraController.start(); // 🔄 RESUME CAMERA
  }

  // ================= UI =================

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
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              cameraController.torchEnabled
                  ? Icons.flash_on
                  : Icons.flash_off,
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
              for (final barcode in capture.barcodes) {
                _processQRCode(barcode.rawValue);
              }
            },
          ),
          CustomPaint(
            painter: ScannerOverlay(),
            child: Container(),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
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
                    'Position the QR code inside the frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (_locked) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================= OVERLAY =================

class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scanSize = size.width * 0.7;
    final left = (size.width - scanSize) / 2;
    final top = (size.height - scanSize) / 2;

    final overlay = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, scanSize, scanSize),
        const Radius.circular(16),
      ));

    final path = Path.combine(PathOperation.difference, overlay, hole);

    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, scanSize, scanSize),
        const Radius.circular(16),
      ),
      Paint()
        ..color = const Color(0xFF5B9BD5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
