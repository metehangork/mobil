import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocConsumer<AuthBloc, AuthState>(listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Başarılı giriş
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✔ Giriş başarılı'),
              backgroundColor: Colors.green,
              duration: Duration(milliseconds: 1200),
            ),
          );
          Future.delayed(const Duration(milliseconds: 300), () {
            if (context.mounted) context.go('/home');
          });
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }, builder: (context, state) {
        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight - 48),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo ve başlık
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.school,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 32),

                          Text(
                            'UniCampus',
                            style: Theme.of(context).textTheme.headlineLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          Text(
                            'Ders arkadaşın seni bekliyor!',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Email input
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'E-posta',
                              hintText: 'ornek@email.com',
                              prefixIcon: Icon(Icons.email),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'E-posta adresi gerekli';
                              }
                              if (!value.contains('@')) {
                                return 'Geçerli bir e-posta adresi girin';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password input
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Şifre',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Şifre gerekli';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Giriş yap butonu
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              return ElevatedButton(
                                onPressed: state is AuthLoading
                                    ? null
                                    : () {
                                        if (_formKey.currentState!.validate()) {
                                          context.read<AuthBloc>().add(
                                                AuthLoginEvent(
                                                  email: _emailController.text
                                                      .trim(),
                                                  password:
                                                      _passwordController.text,
                                                ),
                                              );
                                        }
                                      },
                                child: state is AuthLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text('Giriş Yap'),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Şifremi unuttum
                          TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            child: const Text('Şifremi Unuttum'),
                          ),

                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              context.go('/register');
                            },
                            child: const Text('Hesabın yok mu? Kayıt ol'),
                          ),
                        ],
                      ), // Column
                    ), // Form
                  ), // IntrinsicHeight
                ), // ConstrainedBox
              ); // SingleChildScrollView
            }, // builder
          ), // LayoutBuilder
        ); // SafeArea
      }),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
