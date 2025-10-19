import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/chat_models.dart';
import '../../data/chat_repository.dart';

part 'chat_detail_state.dart';

class ChatDetailCubit extends Cubit<ChatDetailState> {
  final ChatRepository repo;
  final int conversationId;
  final int currentUserId;

  ChatDetailCubit({
    required this.repo,
    required this.conversationId,
    required this.currentUserId,
  }) : super(const ChatDetailState.initial());

  Future<void> loadInitial() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final messages = await repo.getMessages(conversationId, limit: 100);
      final ordered = List<ChatMessage>.from(messages.reversed);
      emit(state.copyWith(loading: false, messages: ordered));
      if (ordered.isNotEmpty) {
        await repo.markRead(conversationId, upTo: ordered.last.createdAt);
      }
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> refresh() async {
    try {
      final messages = await repo.getMessages(conversationId, limit: 100);
      final ordered = List<ChatMessage>.from(messages.reversed);
      emit(state.copyWith(messages: ordered, error: null));
      if (ordered.isNotEmpty) {
        await repo.markRead(conversationId, upTo: ordered.last.createdAt);
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.sending) return;
    emit(state.copyWith(sending: true, error: null));
    try {
      final sent = await repo.sendMessage(conversationId, text.trim());
      final updated = List<ChatMessage>.from(state.messages)..add(sent);
      emit(state.copyWith(messages: updated, sending: false));
    } catch (e) {
      emit(state.copyWith(sending: false, error: e.toString()));
    }
  }
}
