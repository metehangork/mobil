import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../data/chat_repository.dart';
import '../cubit/messages_cubit.dart';
import 'chat_detail_page.dart';
import 'user_search_page.dart';

/// Messages tab root screen
class MessagesRootScreen extends StatefulWidget {
  const MessagesRootScreen({super.key});

  @override
  State<MessagesRootScreen> createState() => _MessagesRootScreenState();
}

class _MessagesRootScreenState extends State<MessagesRootScreen> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  Future<void> _onRefresh(BuildContext context) async {
    await context.read<MessagesCubit>().load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return BlocProvider(
      create: (ctx) {
        final getToken = () async {
          final s = ctx.read<AuthBloc>().state;
          if (s is AuthAuthenticated) return s.token;
          return null;
        };
        final cubit = MessagesCubit(ChatRepository(getToken: getToken));
        // initial load
        cubit.load();
        return cubit;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mesajlar'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Yeni Sohbet',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserSearchPage()),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<MessagesCubit, MessagesState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () => _onRefresh(context),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  if (state.loading && state.conversations.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.conversations.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverToBoxAdapter(child: _buildEmptyState()),
                    )
                  else
                    SliverList.separated(
                      itemBuilder: (ctx, i) {
                        final c = state.conversations[i];
                        return ListTile(
                          leading: CircleAvatar(child: Text(c.otherUserId.toString().substring(0, 1))),
                          title: Text('Kullanıcı #${c.otherUserId}'),
                          subtitle: Text(c.lastMessageText.isNotEmpty ? c.lastMessageText : 'Yeni sohbet'),
                          trailing: c.unreadCount > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    c.unreadCount.toString(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                )
                              : null,
                          onTap: () => _openChatDetail(context, c.id),
                        );
                      },
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemCount: state.conversations.length,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openChatDetail(BuildContext context, int conversationId) {
    // Find the conversation from state to get user details
    final cubit = context.read<MessagesCubit>();
    final state = cubit.state;
    
    if (state.conversations.isEmpty) return;
    
    final conversation = state.conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => state.conversations.first,
    );
    
    // Get current user ID from auth
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return ChatDetailPage(
        conversationId: conversationId,
        otherUserId: conversation.otherUserId,
        otherUserName: 'Kullanıcı #${conversation.otherUserId}',
      );
    }));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz mesaj yok',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Ders arkadaşlarınızla sohbet etmeye başlayın',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
