import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/user_model.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../data/mock_match_repository.dart';
import '../cubit/match_suggestions_cubit.dart';
import '../../domain/match_suggestion.dart';
import '../../../../core/models/match_reason_model.dart';

/// Home tab root screen
class HomeRootScreen extends StatefulWidget {
  const HomeRootScreen({super.key});

  @override
  State<HomeRootScreen> createState() => _HomeRootScreenState();
}

class _HomeRootScreenState extends State<HomeRootScreen> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  bool get wantKeepAlive => true; // Preserve state when switching tabs

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      debugPrint('🔄 HomeRootScreen: Refreshed');
      setState(() => _isRefreshing = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return BlocProvider(
      create: (ctx) {
        final authState = context.read<AuthBloc>().state;
        UserModel current;
        if (authState is AuthAuthenticated) {
          current = authState.user;
        } else {
          // Zorunlu alanları doldurmak için minimal placeholder user
          current = UserModel(
            id: 'tmp',
            name: 'Unknown',
            email: 'tmp@example.com',
            university: 'Unknown Univ',
            department: 'Unknown Dept',
            classYear: 1,
            isVerified: false,
            courses: const [],
            createdAt: DateTime.now(),
          );
        }
        final cubit = MatchSuggestionsCubit(
          repository: MockMatchRepository(),
          currentUser: current,
        );
        cubit.load();
        return cubit;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ana Sayfa'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.push('/notifications'),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildMatchHeader(),
                    const SizedBox(height: 12),
                    _buildMatchSuggestions(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildRecentActivity(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchHeader() {
    return Row(
      children: [
        Icon(Icons.favorite_outline, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text('Sana Önerilenler', style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        TextButton(
          onPressed: () => context.read<MatchSuggestionsCubit>().load(),
          child: const Text('Yenile'),
        )
      ],
    );
  }

  Widget _buildMatchSuggestions() {
    return BlocBuilder<MatchSuggestionsCubit, MatchSuggestionsState>(
      builder: (context, state) {
        if (state is MatchSuggestionsLoading) {
          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
        }
        if (state is MatchSuggestionsEmpty) {
          return _buildInfoCard(
            icon: Icons.info_outline,
            title: 'Henüz başka öğrenci yok',
            subtitle: 'Arkadaşlarını davet et, eşleşmeler burada görünecek',
          );
        }
        if (state is MatchSuggestionsError) {
          return _buildInfoCard(
            icon: Icons.error_outline,
            title: 'Bir şey ters gitti',
            subtitle: state.message,
          );
        }
        if (state is MatchSuggestionsLoaded) {
          return Column(
            children: state.suggestions.map((s) => _buildMatchCard(s)).toList(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMatchCard(MatchSuggestion suggestion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(suggestion.user.name.isNotEmpty ? suggestion.user.name[0] : '?')),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(suggestion.user.name, style: Theme.of(context).textTheme.titleMedium),
                      Text('${(suggestion.score * 100).toInt()}% uyum',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.close)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: -4,
              children: suggestion.reasons.map((r) => _buildReasonChip(r)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonChip(MatchReason reason) {
    Color baseColor;
    switch (reason.type) {
      case MatchReasonType.sharedCourse:
        baseColor = Colors.indigo;
        break;
      case MatchReasonType.sharedInterest:
        baseColor = Colors.teal;
        break;
      case MatchReasonType.studyTime:
        baseColor = Colors.deepOrange;
        break;
      case MatchReasonType.criticalCourse:
        baseColor = Colors.red;
        break;
      case MatchReasonType.sameClass:
        baseColor = Colors.blueGrey;
        break;
      case MatchReasonType.complementary:
        baseColor = Colors.purple;
        break;
      case MatchReasonType.location:
        baseColor = Colors.green;
        break;
    }
    return Chip(
      avatar: Text(reason.icon, style: const TextStyle(fontSize: 14)),
      label: Text(reason.displayText, overflow: TextOverflow.ellipsis),
      backgroundColor: baseColor.withOpacity(0.15),
  labelStyle: TextStyle(color: baseColor, fontSize: 12),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String subtitle}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Merhaba! 👋',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Kafadar Kampüs\'e hoş geldiniz',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hızlı Erişim',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickActionButton(Icons.book, 'Derslerim'),
                _buildQuickActionButton(Icons.group, 'Gruplarım'),
                _buildQuickActionButton(Icons.chat, 'Mesajlar'),
                _buildQuickActionButton(Icons.event, 'Etkinlikler'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Son Aktiviteler',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz aktivite yok',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Dersler ve gruplara katılarak başlayın',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
