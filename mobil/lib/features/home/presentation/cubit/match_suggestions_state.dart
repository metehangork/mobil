part of 'match_suggestions_cubit.dart';

abstract class MatchSuggestionsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MatchSuggestionsLoading extends MatchSuggestionsState {}

class MatchSuggestionsEmpty extends MatchSuggestionsState {}

class MatchSuggestionsLoaded extends MatchSuggestionsState {
  final List<MatchSuggestion> suggestions;
  MatchSuggestionsLoaded(this.suggestions);

  @override
  List<Object?> get props => [suggestions];
}

class MatchSuggestionsError extends MatchSuggestionsState {
  final String message;
  MatchSuggestionsError(this.message);

  @override
  List<Object?> get props => [message];
}
