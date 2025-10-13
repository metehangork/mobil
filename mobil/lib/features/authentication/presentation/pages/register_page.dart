import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../widgets/searchable_dropdown.dart';
// DİKKAT: Sunum katmanı sayfaları için kullanılacak tek AuthBloc
import '../bloc/auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedUniversity;
  String? _selectedDepartment;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
          onPressed: () => context.go('/welcome'),
        ),
        title: const Text('Hesap Oluştur'),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          debugPrint('🔄 Register BLoC state değişti: ${state.runtimeType}');
          if (state is AuthRegistrationSuccess) {
            debugPrint('✅ AuthRegistrationSuccess - Navigate to verify-email');
            context.go('/verify-email?email=${Uri.encodeComponent(state.email)}');
          } else if (state is AuthError) {
            debugPrint('❌ AuthError: ${state.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Üniversite Bilgilerinle\nKayıt Ol',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Sadece doğrulanmış üniversite öğrencileri\nplatformumuza katılabilir',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Form fields
                _buildTextField(
                  controller: _nameController,
                  label: 'Ad',
                  icon: Icons.person,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Ad gerekli';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _surnameController,
                  label: 'Soyad',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Soyad gerekli';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Üniversite arama dropdown'ı
                SearchableDropdown(
                  label: 'Üniversite seçin',
                  icon: Icons.school,
                  value: _selectedUniversity,
                  apiEndpoint: 'schools',
                  displayField: 'name',
                  valueField: 'name',
                  onChanged: (value) {
                    setState(() {
                      _selectedUniversity = value;
                      _selectedDepartment = null; // Üniversite değişince bölümü sıfırla
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Üniversite seçin';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Bölüm arama dropdown'ı
                SearchableDropdown(
                  label: 'Bölüm seçin',
                  icon: Icons.book,
                  value: _selectedDepartment,
                  apiEndpoint: 'departments',
                  displayField: 'name',
                  valueField: 'name',
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartment = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bölüm seçin';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _emailController,
                  label: 'E-posta',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  hint: 'ornek@email.com',
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'E-posta gerekli';
                    }
                    if (!value!.contains('@')) {
                      return 'Geçerli bir e-posta adresi girin';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _passwordController,
                  label: 'Şifre',
                  icon: Icons.lock,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Şifre gerekli';
                    }
                    if (value!.length < 6) {
                      return 'Şifre en az 6 karakter olmalı';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Şifre Tekrar',
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Şifre tekrarı gerekli';
                    }
                    if (value != _passwordController.text) {
                      return 'Şifreler eşleşmiyor';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Şartlar ve koşullar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Kayıt olarak Kullanım Koşulları ve Gizlilik Politikasını kabul etmiş olursunuz.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Kayıt ol butonu
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state is AuthLoading ? null : _handleRegister,
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
                                'Kayıt Ol',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Giriş yap linki
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Zaten hesabın var mı?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Login sayfasına git
                        context.go('/login');
                      },
                      child: const Text(
                        'Giriş Yap',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? hint,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  void _handleRegister() {
    debugPrint('🔥 _handleRegister çağrıldı');
    if (_formKey.currentState?.validate() ?? false) {
      debugPrint('✅ Form validation başarılı');
      debugPrint('📧 Email: ${_emailController.text.trim()}');
      context.read<AuthBloc>().add(
        AuthRegisterEvent(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _nameController.text.trim(),
          lastName: _surnameController.text.trim(),
          university: _selectedUniversity!,
        ),
      );
      debugPrint('🚀 AuthRegisterEvent gönderildi');
    } else {
      debugPrint('❌ Form validation başarısız');
    }
  }
}