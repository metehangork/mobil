import 'package:flutter/material.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_composer.dart';
import '../mock/chat_mock.dart';

class ChatView extends StatefulWidget {
  final String roomId;
  final String roomName;
  const ChatView({super.key, required this.roomId, required this.roomName});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final List<ChatMessage> _messages = List.from(sampleMessages);

  void _send(String text) {
    setState(() {
      _messages.insert(0, ChatMessage(sender: 'Me', text: text, time: 'Now'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.info_outline)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                return MessageBubble(message: m);
              },
            ),
          ),
          SafeArea(child: MessageComposer(onSend: _send)),
        ],
      ),
    );
  }
}
