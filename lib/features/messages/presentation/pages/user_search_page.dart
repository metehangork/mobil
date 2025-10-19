import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../data/chat_repository.dart';
import 'chat_detail_page.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        throw Exception('Not authenticated');
      }

      final repo = ChatRepository(
        getToken: () async => authState.token,
      );

      final results = await repo.searchUsers(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _startConversation(int otherUserId, String displayName) async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final repo = ChatRepository(
        getToken: () async => authState.token,
      );

      final conversationId = await repo.ensureConversation(otherUserId);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ChatDetailPage(
              conversationId: conversationId,
              otherUserId: otherUserId,
              otherUserName: displayName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sohbet başlatılamadı: $e')),
        );
      }
    }
  }

  String _getDisplayName(Map<String, dynamic> user) {
    final firstName = user['first_name'] as String? ?? '';
    final lastName = user['last_name'] as String? ?? '';
    final email = user['email'] as String;

    if (firstName.isEmpty && lastName.isEmpty) {
      return email;
    }

    return '$firstName $lastName'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Ara'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'E-posta veya isim girin...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _results = [];
                            _error = null;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _performSearch,
            ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Hata: $_error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (!_isSearching && _error == null && _results.isEmpty && _searchController.text.trim().length >= 2)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Kullanıcı bulunamadı'),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final user = _results[index];
                final userId = (user['id'] as num).toInt();
                final displayName = _getDisplayName(user);
                final email = user['email'] as String;

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    ),
                  ),
                  title: Text(displayName),
                  subtitle: Text(email),
                  trailing: const Icon(Icons.chat_bubble_outline),
                  onTap: () => _startConversation(userId, displayName),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
