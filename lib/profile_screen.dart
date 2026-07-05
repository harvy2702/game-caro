// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String? validatePasswordChangeInput({
  required String oldPassword,
  required String newPassword,
  required String confirmPassword,
}) {
  if (oldPassword.isEmpty) {
    return 'Vui lòng nhập mật khẩu hiện tại.';
  }
  if (newPassword.isEmpty) {
    return 'Vui lòng nhập mật khẩu mới.';
  }
  if (confirmPassword.isEmpty) {
    return 'Vui lòng xác nhận mật khẩu mới.';
  }
  if (newPassword.length < 6) {
    return 'Mật khẩu mới tối thiểu phải 6 ký tự.';
  }
  if (newPassword != confirmPassword) {
    return 'Xác nhận mật khẩu không khớp.';
  }
  if (oldPassword == newPassword) {
    return 'Mật khẩu mới phải khác mật khẩu hiện tại.';
  }
  return null;
}

String avatarStoragePath({
  required String userId,
  required String fileName,
}) {
  final extension = _avatarFileExtension(fileName);
  return '$userId/avatar.$extension';
}

String avatarContentTypeFromPath(String path) {
  final lowerPath = path.toLowerCase();
  if (lowerPath.endsWith('.png')) return 'image/png';
  if (lowerPath.endsWith('.webp')) return 'image/webp';
  if (lowerPath.endsWith('.gif')) return 'image/gif';
  return 'image/jpeg';
}

String _avatarFileExtension(String fileName) {
  final lowerName = fileName.toLowerCase();
  if (lowerName.endsWith('.png')) return 'png';
  if (lowerName.endsWith('.webp')) return 'webp';
  if (lowerName.endsWith('.gif')) return 'gif';
  return 'jpg';
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    this.usernameOverride,
    this.emailOverride,
    this.changePasswordOverride,
  });

  final String? usernameOverride;
  final String? emailOverride;
  final Future<void> Function(String oldPassword, String newPassword)? changePasswordOverride;

  String get _username {
    if (usernameOverride != null) return usernameOverride!;
    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['username'] as String? ?? 'Người chơi';
  }

  String get _email {
    if (emailOverride != null) return emailOverride!;
    final user = Supabase.instance.client.auth.currentUser;
    return user?.email ?? 'Không có email';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16161C),
        elevation: 0,
        title: const Text(
          'Hồ sơ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: const Color(0xFF1A1A22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF2C2C35), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Color(0xFF00E5FF), size: 32),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: const Color(0xFF1A1A22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF2C2C35), width: 1),
              ),
              child: ListTile(
                leading: const Icon(Icons.lock_outline, color: Color(0xFF00E5FF)),
                title: const Text('Đổi mật khẩu', style: TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () => _showChangePasswordDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => _ChangePasswordDialog(
        onSubmit: changePasswordOverride ?? _changePassword,
      ),
    );
  }

  Future<void> _changePassword(String oldPassword, String newPassword) async {
    final supabase = Supabase.instance.client;
    final email = supabase.auth.currentUser?.email;

    if (email == null || email.isEmpty) {
      throw const AuthException('Không tìm thấy email của tài khoản hiện tại.');
    }

    await supabase.auth.signInWithPassword(
      email: email,
      password: oldPassword,
    );

    await supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.onSubmit});

  final Future<void> Function(String oldPassword, String newPassword) onSubmit;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final validationError = validatePasswordChangeInput(
      oldPassword: oldPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.onSubmit(oldPassword, newPassword);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi mật khẩu thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _translateAuthError(e.message);
      });
    } catch (e) {
      if (!mounted) return;
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

  String _translateAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Mật khẩu hiện tại không chính xác.';
    }
    if (message.contains('Password should be')) {
      return 'Mật khẩu mới tối thiểu phải 6 ký tự.';
    }
    if (message.contains('Network connection lost') || message.contains('Failed host lookup')) {
      return 'Không có kết nối internet. Vui lòng kiểm tra lại.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF2C2C35), width: 1),
      ),
      title: const Text(
        'Đổi mật khẩu',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPasswordField(
              controller: _oldPasswordController,
              label: 'Mật khẩu hiện tại',
              obscureText: _obscureOldPassword,
              onToggle: () {
                setState(() {
                  _obscureOldPassword = !_obscureOldPassword;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              controller: _newPasswordController,
              label: 'Mật khẩu mới',
              obscureText: _obscureNewPassword,
              onToggle: () {
                setState(() {
                  _obscureNewPassword = !_obscureNewPassword;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Xác nhận mật khẩu mới',
              obscureText: _obscureConfirmPassword,
              onToggle: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4081).withOpacity(0.1),
                  border: Border.all(color: const Color(0xFFFF4081).withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFFF4081), fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E5FF),
            foregroundColor: Colors.black,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : const Text('Cập nhật', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white60),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.white60,
          ),
          onPressed: onToggle,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2C2C35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00E5FF)),
        ),
      ),
    );
  }
}
