import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/socket_service.dart';
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
  final SocketService _socketService = SocketService();
  bool _isSocketConnected = false;
  bool _isOtherUserOnline = false;
  bool _isOtherUserTyping = false;

  // Typing indicator debounce timers
  Timer? _typingDebounceTimer;
  Timer? _stopTypingTimer;
  bool _isCurrentlyTyping = false;

  // ChatDetailCubit referansı (stream listener'lardan erişmek için)
  ChatDetailCubit? _cubit;

  // Stream subscription'ları dispose için sakla
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _statusSubscription;
  StreamSubscription<Map<String, dynamic>>? _typingSubscription;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Typing debounce timer'larını iptal et
    _typingDebounceTimer?.cancel();
    _stopTypingTimer?.cancel();
    // Stream subscription'ları iptal et
    _connectionSubscription?.cancel();
    _messageSubscription?.cancel();
    _statusSubscription?.cancel();
    _typingSubscription?.cancel();
    // Not: SocketService singleton olduğu için dispose etmiyoruz
    super.dispose();
  }

  /// Socket.io event'lerini dinle (Socket main.dart'ta başlatılıyor!)
  void _initializeSocket() {
    print('🔌 [ChatDetailPage] Socket stream listener\'ları kuruluyor...');

    // NOT: Socket artık main.dart'ta AuthBloc ile başlatılıyor!
    // Burada sadece stream listener'ları kuruyoruz!

    // Eski subscription'ları iptal et (eğer varsa)
    _connectionSubscription?.cancel();
    _messageSubscription?.cancel();
    _statusSubscription?.cancel();
    _typingSubscription?.cancel();

    // İLK OLARAK mevcut bağlantı durumunu kontrol et
    final currentConnectionState = _socketService.isConnected;
    print('🔌 [ChatDetailPage] İlk bağlantı durumu: $currentConnectionState');
    if (mounted) {
      setState(() {
        _isSocketConnected = currentConnectionState;
      });
    }

    // Bağlantı durumu - YENİ subscription oluştur
    _connectionSubscription =
        _socketService.connectionStream.listen((isConnected) {
      print('🔌 [ChatDetailPage] connectionStream değişti: $isConnected');
      if (mounted) {
        setState(() {
          _isSocketConnected = isConnected;
        });
        print(
            '🔌 [ChatDetailPage] setState ile _isSocketConnected güncellendi: $_isSocketConnected');
      }
    });

    // Mesaj event'lerini dinle - YENİ subscription oluştur
    _messageSubscription = _socketService.messageStream.listen((event) {
      if (!mounted) return;

      final type = event['type'];
      final data = event['data'];

      switch (type) {
        case 'new_message':
          // Yeni mesaj geldi - sadece bu konuşmaya aitse ekle
          final convId = data['conversation_id'] ?? data['conversationId'];
          if (convId == widget.conversationId) {
            _handleNewMessage(data);
          }
          break;

        case 'message_sent':
          // Kendi mesajımız gönderildi - refresh
          _cubit?.refresh();
          break;

        case 'message_read':
          // Mesaj okundu - UI'ı güncelle
          final readConvId = data['conversation_id'] ?? data['conversationId'];
          if (readConvId == widget.conversationId) {
            _cubit?.refresh();
          }
          break;

        case 'message_error':
          // Hata oluştu
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mesaj gönderilemedi: ${data['error']}'),
              backgroundColor: Colors.red,
            ),
          );
          break;
      }
    });

    // Online/offline durum değişiklikleri - YENİ subscription oluştur
    _statusSubscription = _socketService.statusStream.listen((data) {
      if (!mounted) return;
      if (data['userId'] == widget.otherUserId.toString()) {
        setState(() {
          _isOtherUserOnline = data['status'] == 'online';
        });
      }
    });

    // Yazıyor bildirimi - YENİ subscription oluştur
    _typingSubscription = _socketService.typingStream.listen((data) {
      if (!mounted) return;
      if (data['userId'] == widget.otherUserId.toString()) {
        setState(() {
          _isOtherUserTyping = data['isTyping'] == true;
        });
      }
    });
  }

  /// Yeni mesaj geldiğinde işle
  void _handleNewMessage(Map<String, dynamic> messageData) {
    print(
        '🔥 NEW MESSAGE RECEIVED: ${messageData['message_text']} from ${messageData['sender_id']}');

    // Tek refresh yeterli - forceUpdate timestamp'i zaten değişiyor
    _cubit?.refresh();

    // Scroll'u en alta kaydır (smooth, focus bozmadan)
    _scrollToBottom();

    // Mesajı okundu olarak işaretle (sadece ID parameter gerekli, userId JWT'den alınıyor)
    if (messageData['id'] != null) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _socketService.markMessageAsRead(
          messageId: messageData['id'] is int
              ? messageData['id']
              : int.parse(messageData['id'].toString()),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (!mounted || !_scrollController.hasClients) return;

    // Küçük bir delay ile scroll yap (UI render olduktan sonra)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      // jumpTo kullan - animasyon klavye focus'unu bozabilir
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  /// Typing indicator - debounced (300ms)
  void _handleTypingIndicator(String text) {
    if (!_isSocketConnected) return;

    // Önceki debounce timer'ı iptal et
    _typingDebounceTimer?.cancel();

    // Eğer text boşsa, hemen "typing stopped" gönder
    if (text.isEmpty) {
      if (_isCurrentlyTyping) {
        _socketService.sendTyping(
          receiverId: widget.otherUserId.toString(),
          isTyping: false,
        );
        _isCurrentlyTyping = false;
      }
      _stopTypingTimer?.cancel();
      return;
    }

    // Text dolu - 300ms bekle sonra "typing started" gönder
    _typingDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!_isCurrentlyTyping) {
        _socketService.sendTyping(
          receiverId: widget.otherUserId.toString(),
          isTyping: true,
        );
        _isCurrentlyTyping = true;
      }

      // 3 saniye sonra otomatik "typing stopped" gönder
      _stopTypingTimer?.cancel();
      _stopTypingTimer = Timer(const Duration(seconds: 3), () {
        if (_isCurrentlyTyping) {
          _socketService.sendTyping(
            receiverId: widget.otherUserId.toString(),
            isTyping: false,
          );
          _isCurrentlyTyping = false;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) {
        final authState = ctx.read<AuthBloc>().state;
        Future<String?> getToken() async {
          final s = ctx.read<AuthBloc>().state;
          if (s is AuthAuthenticated) return s.token;
          return null;
        }

        final currentUserId = authState is AuthAuthenticated
            ? int.tryParse(authState.user.id) ?? 0
            : 0;
        final cubit = ChatDetailCubit(
          repo: ChatRepository(getToken: getToken),
          conversationId: widget.conversationId,
          currentUserId: currentUserId,
        );
        cubit.loadInitial();

        // State değişkenine ata (stream listener'lardan erişmek için)
        _cubit = cubit;

        return cubit;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.otherUserName),
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: _isOtherUserOnline ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isOtherUserOnline ? 'Çevrimiçi' : 'Çevrimdışı',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            // Socket bağlantı durumu göstergesi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                _isSocketConnected
                    ? Icons.cloud_done
                    : Icons.cloud_off_outlined,
                size: 20,
                color: _isSocketConnected ? Colors.green : Colors.orange,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            // Yazıyor bildirimi
            if (_isOtherUserTyping)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey[100],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 16),
                    Text(
                      '${widget.otherUserName} yazıyor',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                      ),
                    ),
                  ],
                ),
              ),
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
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.5),
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
                        final isMine = msg.senderId ==
                            context.read<ChatDetailCubit>().currentUserId;
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(msg.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMine ? Colors.white70 : Colors.black54,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  // Okundu tiki (✓✓)
                  Icon(
                    msg.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: msg.isRead ? Colors.lightBlueAccent : Colors.white70,
                  ),
                ],
              ],
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
                color: Colors.black.withValues(alpha: 0.1),
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
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (text) {
                      // Typing indicator - debounced (300ms)
                      _handleTypingIndicator(text);
                    },
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
                            // Typing indicator'ı durdur
                            _typingDebounceTimer?.cancel();
                            _stopTypingTimer?.cancel();
                            if (_isCurrentlyTyping) {
                              _socketService.sendTyping(
                                receiverId: widget.otherUserId.toString(),
                                isTyping: false,
                              );
                              _isCurrentlyTyping = false;
                            }

                            // Socket.io ile real-time gönder
                            if (_isSocketConnected) {
                              _socketService.sendMessage(
                                conversationId: widget.conversationId,
                                text: text,
                              );
                              // Socket mesajı gönderdi, UI'ı hemen güncelle
                              Future.delayed(const Duration(milliseconds: 100),
                                  () {
                                if (mounted) {
                                  context.read<ChatDetailCubit>().refresh();
                                }
                              });
                            } else {
                              // Fallback: REST API ile gönder
                              context.read<ChatDetailCubit>().sendMessage(text);
                            }
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
