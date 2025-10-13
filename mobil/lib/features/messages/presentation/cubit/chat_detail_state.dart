part of 'chat_detail_cubit.dart';

class ChatDetailState extends Equatable {
  final bool loading;
  final bool sending;
  final String? error;
  final List<ChatMessage> messages;

  const ChatDetailState({
    required this.loading,
    required this.sending,
    required this.error,
    required this.messages,
  });

  const ChatDetailState.initial()
      : loading = false,
        sending = false,
        error = null,
        messages = const [];

  ChatDetailState copyWith({
    bool? loading,
    bool? sending,
    String? error,
    List<ChatMessage>? messages,
  }) {
    return ChatDetailState(
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      error: error,
      messages: messages ?? this.messages,
    );
  }

  @override
  List<Object?> get props => [loading, sending, error, messages];
}
