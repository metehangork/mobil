class ChatMessage {
  final String sender;
  final String text;
  final String time;

  ChatMessage({required this.sender, required this.text, required this.time});
}

final sampleMessages = [
  ChatMessage(sender: 'Ali', text: 'Merhaba, toplantı saat kaçta?', time: '09:00'),
  ChatMessage(sender: 'Me', text: '10:30 iyi mi?', time: '09:02'),
  ChatMessage(sender: 'Ayşe', text: 'Ben katılıyorum', time: '09:05'),
];
