part of 'messages_cubit.dart';

class MessagesState extends Equatable {
  final bool loading;
  final String? error;
  final List<ConversationSummary> conversations;

  const MessagesState({required this.loading, this.error, required this.conversations});

  const MessagesState.initial() : loading = false, error = null, conversations = const [];

  MessagesState copyWith({bool? loading, String? error, List<ConversationSummary>? conversations}) =>
      MessagesState(
        loading: loading ?? this.loading,
        error: error,
        conversations: conversations ?? this.conversations,
      );

  @override
  List<Object?> get props => [loading, error, conversations];
}
