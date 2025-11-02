import 'package:flutter/material.dart';
import 'package:unicampus/core/services/service_locator.dart';

class DebugApiTestPage extends StatelessWidget {
  const DebugApiTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Test Debug'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'API Bağlantı Testi',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              try {
                final authService = ServiceLocator.auth;
                final response = await authService.getCurrentUser();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Auth Test: ${response.isSuccess ? 'Başarılı' : 'Başarısız'}')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: $e')),
                );
              }
            },
            child: const Text('Auth API Test'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              try {
                final userService = ServiceLocator.user;
                final response = await userService.getMyProfile();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'User Test: ${response.isSuccess ? 'Başarılı' : 'Başarısız'}')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: $e')),
                );
              }
            },
            child: const Text('User API Test'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              try {
                final schoolService = ServiceLocator.school;
                final response = await schoolService.getSchools();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'School Test: ${response.isSuccess ? 'Başarılı' : 'Başarısız'}')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: $e')),
                );
              }
            },
            child: const Text('School API Test'),
          ),
        ],
      ),
    );
  }
}
