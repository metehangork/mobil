import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/chat_models.dart';
import '../../data/chat_repository.dart';

part 'messages_state.dart';

class MessagesCubit extends Cubit<MessagesState> {
  final ChatRepository repo;
  MessagesCubit(this.repo) : super(const MessagesState.initial());

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final items = await repo.listConversations();
      emit(state.copyWith(loading: false, conversations: items));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
