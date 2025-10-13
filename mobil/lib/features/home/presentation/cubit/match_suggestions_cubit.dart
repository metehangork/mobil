import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/models/user_model.dart';
import '../../data/mock_match_repository.dart';
import '../../domain/match_suggestion.dart';

part 'match_suggestions_state.dart';

class MatchSuggestionsCubit extends Cubit<MatchSuggestionsState> {
  final MockMatchRepository repository;
  final UserModel currentUser;

  MatchSuggestionsCubit({required this.repository, required this.currentUser})
      : super(MatchSuggestionsLoading());

  Future<void> load() async {
    emit(MatchSuggestionsLoading());
    try {
      final suggestions = await repository.buildSuggestions(currentUser);
      if (suggestions.isEmpty) {
        emit(MatchSuggestionsEmpty());
      } else {
        emit(MatchSuggestionsLoaded(suggestions));
      }
    } catch (e) {
      emit(MatchSuggestionsError(e.toString()));
    }
  }
}
