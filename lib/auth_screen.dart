// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Chuyển username thành email nội bộ
  String _getEmail(String input) {
    final cleaned = input.trim();
    if (cleaned.contains('@')) {
      return cleaned;
    }
    // Chuyển username viết hoa/thường về chữ thường để tránh phân biệt khi đăng nhập
    return '${cleaned.toLowerCase()}@caro.local';
  }

  // Đăng ký tài khoản
  Future<void> _signUp() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    // Kiểm tra định dạng username hợp lệ (không chứa dấu cách, chỉ chữ cái và số)
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!username.contains('@') && !usernameRegex.hasMatch(username)) {
      setState(() {
        _errorMessage = 'Tên đăng nhập chỉ gồm chữ cái, số và dấu gạch dưới.';
        _isLoading = false;
      });
      return;
    }

    try {
      // 1. Kiểm tra xem username đã tồn tại trong bảng profiles hay chưa
      final existing = await _supabase
          .from('profiles')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      if (existing != null) {
        setState(() {
          _errorMessage = 'Tên đăng nhập này đã được sử dụng!';
          _isLoading = false;
        });
        return;
      }

      // 2. Tiến hành đăng ký
      final email = _getEmail(username);
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      if (response.user != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký tài khoản thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _translateAuthError(e.message);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Đã có lỗi xảy ra: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Đăng nhập tài khoản
  Future<void> _signIn() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final email = _getEmail(username);

    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _translateAuthError(e.message);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Đã có lỗi xảy ra: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Dịch thông báo lỗi Auth của Supabase sang tiếng Việt
  String _translateAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Tên đăng nhập hoặc mật khẩu không chính xác.';
    }
    if (message.contains('User already registered')) {
      return 'Tên đăng nhập hoặc email này đã đăng ký.';
    }
    if (message.contains('Password should be')) {
      return 'Mật khẩu phải chứa ít nhất 6 ký tự.';
    }
    if (message.contains('Network connection lost') || message.contains('Failed host lookup')) {
      return 'Không có kết nối internet. Vui lòng kiểm tra lại.';
    }
    return message;
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_isSignUp) {
      _signUp();
    } else {
      _signIn();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF00E5FF);
    final secondaryColor = const Color(0xFFFF4081);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon Game Caro Premium
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.sports_esports,
                      size: 64,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Caro Premium',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp ? 'Đăng ký tài khoản mới' : 'Đăng nhập để tiếp tục chơi',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Khung Form Đăng nhập/Đăng ký
                  Card(
                    color: const Color(0xFF1E1E24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFF2C2C35), width: 1.5),
                    ),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Ô nhập Username
                          TextFormField(
                            controller: _usernameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Tên đăng nhập',
                              labelStyle: const TextStyle(color: Colors.white60),
                              prefixIcon: const Icon(Icons.person, color: Colors.white60),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF2C2C35)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primaryColor),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: secondaryColor),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: secondaryColor),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Vui lòng nhập tên đăng nhập';
                              }
                              if (val.trim().length < 3) {
                                return 'Tên đăng nhập tối thiểu 3 ký tự';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Ô nhập Mật khẩu
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu',
                              labelStyle: const TextStyle(color: Colors.white60),
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white60),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white60,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF2C2C35)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primaryColor),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: secondaryColor),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: secondaryColor),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Vui lòng nhập mật khẩu';
                              }
                              if (val.length < 6) {
                                return 'Mật khẩu tối thiểu phải 6 ký tự';
                              }
                              return null;
                            },
                          ),

                          // Hiển thị thông báo lỗi (nếu có)
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: secondaryColor.withOpacity(0.1),
                                border: Border.all(color: secondaryColor.withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: secondaryColor, fontSize: 13),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Nút Xác nhận (Đăng nhập / Đăng ký)
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isSignUp ? secondaryColor : primaryColor,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                      ),
                                    )
                                  : Text(
                                      _isSignUp ? 'ĐĂNG KÝ' : 'ĐĂNG NHẬP',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Nút chuyển đổi giữa Đăng nhập / Đăng ký
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                        _errorMessage = null;
                        _formKey.currentState?.reset();
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: _isSignUp ? primaryColor : secondaryColor,
                    ),
                    child: Text(
                      _isSignUp
                          ? 'Đã có tài khoản? Đăng nhập ngay'
                          : 'Chưa có tài khoản? Đăng ký ngay',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
