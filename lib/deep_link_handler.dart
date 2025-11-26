import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';

import 'screens/new_password_screen.dart';

class DeepLinkHandler extends StatefulWidget {
  final Widget child;
  const DeepLinkHandler({required this.child, super.key});

  @override
  State<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> {
  StreamSubscription? _sub;
  bool _handledThisLink = false;

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
  }

  void _handleIncomingLinks() {
    // --- WEB: uni_links tidak bekerja, jadi langsung return ---
    if (kIsWeb) return;

    // --- MOBILE: aman pakai uni_links ---
    _sub = linkStream.listen(
      (String? link) {
        if (link == null) return;
        if (!mounted) return;

        // Hindari navigasi berulang
        if (_handledThisLink) return;

        if (link.contains('reset-password')) {
          _handledThisLink = true;

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewPasswordScreen()),
          );
        }
      },
      onError: (err) {
        // optional log
        debugPrint("Deep link error: $err");
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
