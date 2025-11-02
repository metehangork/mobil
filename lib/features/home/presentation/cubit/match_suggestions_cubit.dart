import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/match_reason_model.dart';
import '../../data/i_match_repository.dart';
import '../../domain/match_suggestion.dart';

part 'match_suggestions_state.dart';

class MatchSuggestionsCubit extends Cubit<MatchSuggestionsState> {
  final IMatchRepository repository;
  final UserModel currentUser;

  MatchSuggestionsCubit({required this.repository, required this.currentUser})
      : super(MatchSuggestionsLoading());

  Future<void> load() async {
    emit(MatchSuggestionsLoading());
    try {
      final matches = await repository.getSuggestedMatches();
      if (matches.isEmpty) {
        emit(MatchSuggestionsEmpty());
      } else {
        // Convert to MatchSuggestion objects
        final suggestions = matches
            .map((match) => MatchSuggestion(
                  user: UserModel(
                    id: match['id'],
                    name: match['name'],
                    email: match['email'],
                    university: match['university'],
                    department: match['department'],
                    classYear: 1,
                    isVerified: true,
                    courses: const [],
                    createdAt: DateTime.now(),
                  ),
                  score: match['score'] ?? 0.0,
                  reasons: (match['reasons'] as List?)
                          ?.map((r) => MatchReason(
                                type: MatchReasonType.sharedCourse,
                                displayText: r.toString(),
                                data: null,
                                urgency: 5,
                                icon: '📚',
                              ))
                          .toList() ??
                      [],
                ))
            .toList();
        emit(MatchSuggestionsLoaded(suggestions));
      }
    } catch (e) {
      emit(MatchSuggestionsError(e.toString()));
    }
  }
}
