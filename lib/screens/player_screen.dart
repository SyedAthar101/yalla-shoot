import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/match_model.dart';

class PlayerScreen extends StatefulWidget {
  final YallaMatch match;

  const PlayerScreen({super.key, required this.match});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final WebViewController _controller;
  double _progress = 0;
  bool _landscape = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p / 100),
          onPageFinished: (_) => setState(() => _progress = 0),
        ),
      )
      ..loadRequest(Uri.parse(widget.match.streamUrl));
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Future<void> _toggleOrientation() async {
    setState(() => _landscape = !_landscape);
    if (_landscape) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF931800),
        title: Text(
          '${widget.match.homeTeam} - ${widget.match.awayTeam}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
                _landscape ? Icons.stay_current_portrait : Icons.fullscreen),
            onPressed: _toggleOrientation,
            tooltip: 'Fullscreen',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
        bottom: _progress > 0 && _progress < 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFFC107)),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          Expanded(child: WebViewWidget(controller: _controller)),
          Container(
            width: double.infinity,
            color: const Color(0xFF1B1B24),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              'البث من نفس مصدر الموقع — إذا توقف البث، جرّب التحديث أو انتظر قليلاً.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
