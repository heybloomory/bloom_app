import 'package:flutter/material.dart';
import '../../core/services/ai_api_service.dart';

class AskBloomoryScreen extends StatefulWidget {
  const AskBloomoryScreen({super.key});

  @override
  State<AskBloomoryScreen> createState() => _AskBloomoryScreenState();
}

class _AskBloomoryScreenState extends State<AskBloomoryScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _loading = false;

  final List<_Msg> _msgs = [
    _Msg.bot("Hi 👋 Ask me anything about BloomoryAI!"),
  ];

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _msgs.add(_Msg.user(text));
      _loading = true;
    });
    _controller.clear();

    try {
      final reply = await AiApiService.ask(text);
      setState(() => _msgs.add(_Msg.bot(reply)));
    } catch (e) {
      setState(() => _msgs.add(_Msg.bot("Error: $e")));
    } finally {
      setState(() => _loading = false);
      await Future.delayed(const Duration(milliseconds: 50));
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      appBar: AppBar(
        title: const Text("Ask BloomoryAI"),
        backgroundColor: const Color(0xFF0B0F1A),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _msgs.length,
              itemBuilder: (_, i) {
                final m = _msgs[i];
                final isUser = m.role == _Role.user;

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 340),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blue.withOpacity(0.18)
                          : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.10)),
                    ),
                    child: Text(
                      m.text,
                      style: const TextStyle(color: Colors.white, height: 1.3),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.10),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Ask me anything about Bloomory...",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.55)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loading ? null : _send,
                  icon: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _Role { user, bot }

class _Msg {
  final _Role role;
  final String text;
  _Msg(this.role, this.text);

  factory _Msg.user(String t) => _Msg(_Role.user, t);
  factory _Msg.bot(String t) => _Msg(_Role.bot, t);
}
