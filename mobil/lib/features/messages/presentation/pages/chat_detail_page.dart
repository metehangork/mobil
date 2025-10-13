import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../data/chat_models.dart';
import '../../data/chat_repository.dart';
import '../cubit/chat_detail_cubit.dart';

class ChatDetailPage extends StatefulWidget {
  final int conversationId;
  final int otherUserId;
  final String otherUserName;

  const ChatDetailPage({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) {
        final authState = ctx.read<AuthBloc>().state;
        final getToken = () async {
          final s = ctx.read<AuthBloc>().state;
          if (s is AuthAuthenticated) return s.token;
          return null;
        };
        final currentUserId = authState is AuthAuthenticated 
            ? int.tryParse(authState.user.id) ?? 0 
            : 0;
        final cubit = ChatDetailCubit(
          repo: ChatRepository(getToken: getToken),
          conversationId: widget.conversationId,
          currentUserId: currentUserId,
        );
        cubit.loadInitial();
        return cubit;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.otherUserName),
              const Text(
                'Çevrimiçi',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocConsumer<ChatDetailCubit, ChatDetailState>(
                listener: (context, state) {
                  if (state.messages.isNotEmpty) {
                    _scrollToBottom();
                  }
                  if (state.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.error!)),
                    );
                  }
                },
                builder: (context, state) {
                  if (state.loading && state.messages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text('Henüz mesaj yok'),
                          const SizedBox(height: 8),
                          const Text(
                            'İlk mesajı gönderin!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => context.read<ChatDetailCubit>().refresh(),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.messages.length,
                      itemBuilder: (ctx, i) {
                        final msg = state.messages[i];
                        final isMine = msg.senderId == context.read<ChatDetailCubit>().currentUserId;
                        return _buildMessageBubble(msg, isMine);
                      },
                    ),
                  );
                },
              ),
            ),
            _buildMessageComposer(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMine) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(18),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: isMine ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isMine ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer(BuildContext context) {
    return BlocBuilder<ChatDetailCubit, ChatDetailState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: state.sending ? null : () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !state.sending,
                    decoration: InputDecoration(
                      hintText: 'Mesaj yazın...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                state.sending
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send),
                        color: Theme.of(context).colorScheme.primary,
                        onPressed: () {
                          final text = _messageController.text.trim();
                          if (text.isNotEmpty) {
                            context.read<ChatDetailCubit>().sendMessage(text);
                            _messageController.clear();
                          }
                        },
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Şimdi';
    if (diff.inHours < 1) return '${diff.inMinutes}dk';
    if (diff.inDays < 1) return '${diff.inHours}sa';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
