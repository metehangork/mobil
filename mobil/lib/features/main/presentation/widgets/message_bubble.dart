import 'package:flutter/material.dart';
import '../mock/chat_mock.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const MessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMe = message.sender == 'Me';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.sender, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isMe ? Colors.white : null)),
            const SizedBox(height: 6),
            Text(message.text, style: TextStyle(color: isMe ? Colors.white : null)),
            const SizedBox(height: 4),
            Text(message.time, style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey)),
          ],
        ),
      ),
    );
  }
}
