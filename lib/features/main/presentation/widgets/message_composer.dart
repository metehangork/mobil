import 'package:flutter/material.dart';

class MessageComposer extends StatefulWidget {
  final void Function(String) onSend;
  const MessageComposer({super.key, required this.onSend});

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final _controller = TextEditingController();
  bool _canSend = false;

  void _textChanged() {
    setState(() {
      _canSend = _controller.text.trim().isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_textChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_textChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.emoji_emotions_outlined)),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration:
                  const InputDecoration.collapsed(hintText: 'Mesaj yaz...'),
              minLines: 1,
              maxLines: 5,
            ),
          ),
          if (_canSend)
            IconButton(onPressed: _handleSend, icon: const Icon(Icons.send)),
        ],
      ),
    );
  }
}
