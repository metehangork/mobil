part of 'chat_detail_cubit.dart';

class ChatDetailState extends Equatable {
  final bool loading;
  final bool sending;
  final String? error;
  final List<ChatMessage> messages;
  final DateTime
      lastUpdate; // Her refresh'te değişecek, Equatable rebuild tetikleyecek

  const ChatDetailState({
    required this.loading,
    required this.sending,
    required this.error,
    required this.messages,
    required this.lastUpdate,
  });

  ChatDetailState.initial()
      : loading = false,
        sending = false,
        error = null,
        messages = const [],
        lastUpdate = DateTime.now();

  ChatDetailState copyWith({
    bool? loading,
    bool? sending,
    String? error,
    List<ChatMessage>? messages,
    bool forceUpdate = false, // refresh() çağrıldığında true olacak
  }) {
    return ChatDetailState(
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      error: error,
      messages: messages ?? this.messages,
      lastUpdate: forceUpdate ? DateTime.now() : this.lastUpdate,
    );
  }

  @override
  List<Object?> get props => [loading, sending, error, messages, lastUpdate];
}
