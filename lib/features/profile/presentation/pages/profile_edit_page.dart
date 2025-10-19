import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../../core/models/user_model.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _hobbiesController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    _nameController = TextEditingController(text: user.name);
    _bioController = TextEditingController(text: user.bio);
    _hobbiesController = TextEditingController(text: user.hobbies.join(', '));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _hobbiesController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final currentState = context.read<AuthBloc>().state;
      if (currentState is AuthAuthenticated) {
        final updatedUser = currentState.user.copyWith(
          name: _nameController.text,
          bio: _bioController.text,
          hobbies: _hobbiesController.text.split(',').map((e) => e.trim()).toList(),
        );
        context.read<AuthBloc>().add(AuthUpdateProfileEvent(updatedUser: updatedUser));
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
            tooltip: 'Kaydet',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: const Icon(Icons.person, size: 50),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                          onPressed: () {
                            // TODO: Fotoğraf yükleme mantığı
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ad Soyad boş bırakılamaz.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Hakkımda (Bio)',
                  hintText: 'Kendinden kısaca bahset...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hobbiesController,
                decoration: const InputDecoration(
                  labelText: 'İlgi Alanları',
                  hintText: 'Futbol, Müzik, Kitaplar (virgülle ayırın)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              // TODO: Eşleşme tercihlerini düzenlemek için widget'lar eklenecek
            ],
          ),
        ),
      ),
    );
  }
}
