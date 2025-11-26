import 'package:uni_links/uni_links.dart';
import 'package:flutter/material.dart';
import 'screens/new_password_screen.dart';

class DeepLinkHandler extends StatefulWidget {
  final Widget child;
  const DeepLinkHandler({required this.child, super.key});

  @override
  State<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> {
  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
  }

  void _handleIncomingLinks() {
    linkStream.listen((String? link) {
      if (link != null && link.contains('reset-password')) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewPasswordScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
