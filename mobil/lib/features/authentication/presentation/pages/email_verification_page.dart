import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;
  
  const EmailVerificationPage({super.key, required this.email});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage>
    with TickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  int _countdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
    _startCountdown();
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _countdown = 60;
      _canResend = false;
    });
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdown > 0) {
        setState(() {
          _countdown--;
        });
        if (_countdown > 0) {
          _startCountdown();
        } else {
          setState(() {
            _canResend = true;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/register'),
        ),
        title: const Text('E-posta Doğrulama'),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // Başarılı doğrulama mesajı göster
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('✓ E-posta doğrulandı! Hoş geldin!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            // Ana sayfaya yönlendir
            Future.delayed(const Duration(milliseconds: 500), () {
              if (context.mounted) {
                context.go('/home');
              }
            });
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.email_outlined,
                    size: 50,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Başlık
                Text(
                  'E-postanı Doğrula',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Açıklama
                Text(
                  '${widget.email} adresine gönderilen\n6 haneli doğrulama kodunu gir',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  widget.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                
                const SizedBox(height: 48),
                
                // Doğrulama kodu input
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) => _buildCodeInput(index)),
                ),
                
                const SizedBox(height: 32),
                
                // Geri sayım ve tekrar gönder
                if (!_canResend)
                  Text(
                    'Yeni kod isteyebilmek için $_countdown saniye bekle',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Kod gelmedi mi?',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: _resendCode,
                        child: const Text(
                          'Tekrar Gönder',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                
                const Spacer(),
                
                // Doğrula butonu
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state is AuthLoading ? null : _verifyCode,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: state is AuthLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Doğrula',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeInput(int index) {
    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(
          color: _controllers[index].text.isNotEmpty
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withOpacity(0.5),
          width: _controllers[index].text.isNotEmpty ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
        ),
        onChanged: (value) {
          setState(() {});
          
          if (value.isNotEmpty) {
            // Sonraki input'a geç
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              // Son input, klavyeyi kapat
              _focusNodes[index].unfocus();
              _verifyCode();
            }
          } else {
            // Önceki input'a geç
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
        },
        onTap: () {
          _controllers[index].selection = TextSelection.fromPosition(
            TextPosition(offset: _controllers[index].text.length),
          );
        },
      ),
    );
  }

  void _verifyCode() {
    final code = _controllers.map((c) => c.text).join();
    
    if (code.length == 6) {
      context.read<AuthBloc>().add(
        AuthVerifyEmailEvent(email: widget.email, code: code),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen 6 haneli kodu tam olarak girin'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _resendCode() {
    context.read<AuthBloc>().add(const AuthResendCodeEvent());
    _startCountdown();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Doğrulama kodu tekrar gönderildi'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}