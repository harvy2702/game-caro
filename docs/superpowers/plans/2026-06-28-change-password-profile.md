# Change Password Profile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a simple signed-in profile screen with one `Đổi mật khẩu` option that verifies the old password and updates the Supabase password.

**Architecture:** Create a focused `ProfileScreen` in `lib/profile_screen.dart`. Keep validation as a pure top-level helper for tests, keep Supabase password change behavior inside the profile screen, and navigate to the profile screen from the existing `CaroGameScreen` app bar.

**Tech Stack:** Flutter, Material widgets, Supabase Auth via `supabase_flutter`, `flutter_test`.

---

## File Structure

- Create: `lib/profile_screen.dart`
  - Owns the profile page, password change dialog, local validation, loading/error state, and Supabase Auth calls.
  - Exposes `validatePasswordChangeInput` for focused tests.
- Modify: `lib/caro_game_screen.dart`
  - Imports `profile_screen.dart`.
  - Adds a profile icon in the app bar that pushes `ProfileScreen`.
- Modify: `test/widget_test.dart`
  - Replaces the generated counter test with focused validation and widget tests for the new profile screen.

## Task 1: Add Password Validation Helper

**Files:**
- Create: `lib/profile_screen.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Write failing validation tests**

Replace `test/widget_test.dart` with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:game_caro/profile_screen.dart';

void main() {
  group('validatePasswordChangeInput', () {
    test('requires all fields', () {
      expect(
        validatePasswordChangeInput(
          oldPassword: '',
          newPassword: 'abcdef',
          confirmPassword: 'abcdef',
        ),
        'Vui lòng nhập mật khẩu hiện tại.',
      );

      expect(
        validatePasswordChangeInput(
          oldPassword: 'oldpass',
          newPassword: '',
          confirmPassword: 'abcdef',
        ),
        'Vui lòng nhập mật khẩu mới.',
      );

      expect(
        validatePasswordChangeInput(
          oldPassword: 'oldpass',
          newPassword: 'abcdef',
          confirmPassword: '',
        ),
        'Vui lòng xác nhận mật khẩu mới.',
      );
    });

    test('validates new password rules', () {
      expect(
        validatePasswordChangeInput(
          oldPassword: 'oldpass',
          newPassword: '12345',
          confirmPassword: '12345',
        ),
        'Mật khẩu mới tối thiểu phải 6 ký tự.',
      );

      expect(
        validatePasswordChangeInput(
          oldPassword: 'oldpass',
          newPassword: 'newpass',
          confirmPassword: 'different',
        ),
        'Xác nhận mật khẩu không khớp.',
      );

      expect(
        validatePasswordChangeInput(
          oldPassword: 'samepass',
          newPassword: 'samepass',
          confirmPassword: 'samepass',
        ),
        'Mật khẩu mới phải khác mật khẩu hiện tại.',
      );
    });

    test('returns null when input is valid', () {
      expect(
        validatePasswordChangeInput(
          oldPassword: 'oldpass',
          newPassword: 'newpass',
          confirmPassword: 'newpass',
        ),
        isNull,
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
flutter test test/widget_test.dart
```

Expected: FAIL because `package:game_caro/profile_screen.dart` does not exist.

- [ ] **Step 3: Add the validation helper**

Create `lib/profile_screen.dart` with:

```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
flutter test test/widget_test.dart
```

Expected: PASS for all validation tests.

- [ ] **Step 5: Commit**

```bash
git add lib/profile_screen.dart test/widget_test.dart
git commit -m "test: add password validation coverage"
```

## Task 2: Build Profile Screen UI And Dialog

**Files:**
- Modify: `lib/profile_screen.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Add failing widget tests**

Append these tests inside `main()` in `test/widget_test.dart`, after the validation group:

```dart
  testWidgets('ProfileScreen shows account info and change password option', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileScreen(
          usernameOverride: 'demo_user',
          emailOverride: 'demo@caro.local',
        ),
      ),
    );

    expect(find.text('Hồ sơ'), findsOneWidget);
    expect(find.text('demo_user'), findsOneWidget);
    expect(find.text('demo@caro.local'), findsOneWidget);
    expect(find.text('Đổi mật khẩu'), findsOneWidget);
  });

  testWidgets('Change password option opens dialog with three fields', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileScreen(
          usernameOverride: 'demo_user',
          emailOverride: 'demo@caro.local',
        ),
      ),
    );

    await tester.tap(find.text('Đổi mật khẩu'));
    await tester.pumpAndSettle();

    expect(find.text('Mật khẩu hiện tại'), findsOneWidget);
    expect(find.text('Mật khẩu mới'), findsOneWidget);
    expect(find.text('Xác nhận mật khẩu mới'), findsOneWidget);
    expect(find.text('Cập nhật'), findsOneWidget);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
flutter test test/widget_test.dart
```

Expected: FAIL because `ProfileScreen` is not implemented.

- [ ] **Step 3: Implement the profile screen and dialog UI**

Replace `lib/profile_screen.dart` with:

```dart
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
    final user = Supabase.instance.client.auth.currentUser;
    return usernameOverride ?? user?.userMetadata?['username'] as String? ?? 'Người chơi';
  }

  String get _email {
    final user = Supabase.instance.client.auth.currentUser;
    return emailOverride ?? user?.email ?? 'Không có email';
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
```

- [ ] **Step 4: Run tests**

Run:

```bash
flutter test test/widget_test.dart
```

Expected: PASS for validation and profile widget tests.

- [ ] **Step 5: Commit**

```bash
git add lib/profile_screen.dart test/widget_test.dart
git commit -m "feat: add profile password screen"
```

## Task 3: Add Submit Behavior Regression Coverage

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `lib/profile_screen.dart`

- [ ] **Step 1: Add submit behavior tests**

Append these tests inside `main()` in `test/widget_test.dart`:

```dart
  testWidgets('Change password dialog shows validation errors before submit', (tester) async {
    var submitCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          usernameOverride: 'demo_user',
          emailOverride: 'demo@caro.local',
          changePasswordOverride: (_, __) async {
            submitCount++;
          },
        ),
      ),
    );

    await tester.tap(find.text('Đổi mật khẩu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cập nhật'));
    await tester.pump();

    expect(find.text('Vui lòng nhập mật khẩu hiện tại.'), findsOneWidget);
    expect(submitCount, 0);
  });

  testWidgets('Change password dialog submits valid passwords and shows success', (tester) async {
    var submittedOldPassword = '';
    var submittedNewPassword = '';

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          usernameOverride: 'demo_user',
          emailOverride: 'demo@caro.local',
          changePasswordOverride: (oldPassword, newPassword) async {
            submittedOldPassword = oldPassword;
            submittedNewPassword = newPassword;
          },
        ),
      ),
    );

    await tester.tap(find.text('Đổi mật khẩu'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Mật khẩu hiện tại'), 'oldpass');
    await tester.enterText(find.widgetWithText(TextField, 'Mật khẩu mới'), 'newpass');
    await tester.enterText(find.widgetWithText(TextField, 'Xác nhận mật khẩu mới'), 'newpass');
    await tester.tap(find.text('Cập nhật'));
    await tester.pumpAndSettle();

    expect(submittedOldPassword, 'oldpass');
    expect(submittedNewPassword, 'newpass');
    expect(find.text('Đổi mật khẩu thành công!'), findsOneWidget);
    expect(find.text('Mật khẩu hiện tại'), findsNothing);
  });

  testWidgets('Change password dialog keeps form open on submit failure', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          usernameOverride: 'demo_user',
          emailOverride: 'demo@caro.local',
          changePasswordOverride: (_, __) async {
            throw const AuthException('Invalid login credentials');
          },
        ),
      ),
    );

    await tester.tap(find.text('Đổi mật khẩu'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Mật khẩu hiện tại'), 'wrongpass');
    await tester.enterText(find.widgetWithText(TextField, 'Mật khẩu mới'), 'newpass');
    await tester.enterText(find.widgetWithText(TextField, 'Xác nhận mật khẩu mới'), 'newpass');
    await tester.tap(find.text('Cập nhật'));
    await tester.pumpAndSettle();

    expect(find.text('Mật khẩu hiện tại'), findsOneWidget);
    expect(find.text('Mật khẩu hiện tại không chính xác.'), findsOneWidget);
  });
```

- [ ] **Step 2: Run tests**

Run:

```bash
flutter test test/widget_test.dart
```

Expected: PASS because Task 2 implemented the submit behavior. These tests lock the behavior so later refactors do not break validation, success, or failure handling.

- [ ] **Step 3: Run static analysis**

Run:

```bash
flutter analyze
```

Expected: No analyzer errors. Existing warnings are acceptable only when they are unrelated to the files changed in this task.

- [ ] **Step 4: Run tests**

Run:

```bash
flutter test test/widget_test.dart
```

Expected: PASS for all tests.

- [ ] **Step 5: Commit**

```bash
git add test/widget_test.dart
git commit -m "test: cover profile password submit flow"
```

## Task 4: Add Profile Navigation From Game Screen

**Files:**
- Modify: `lib/caro_game_screen.dart`

- [ ] **Step 1: Import profile screen**

Add this import near the top of `lib/caro_game_screen.dart`:

```dart
import 'profile_screen.dart';
```

- [ ] **Step 2: Add profile action before logout**

In the `AppBar(actions: [...])` list in `lib/caro_game_screen.dart`, add this `IconButton` before the logout `IconButton`:

```dart
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white70),
            tooltip: 'Hồ sơ',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
```

- [ ] **Step 3: Format**

Run:

```bash
dart format lib/caro_game_screen.dart lib/profile_screen.dart test/widget_test.dart
```

Expected: Files are formatted with no errors.

- [ ] **Step 4: Run static analysis**

Run:

```bash
flutter analyze
```

Expected: No analyzer errors. Existing warnings are acceptable only if unrelated and already present before this task.

- [ ] **Step 5: Run tests**

Run:

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/caro_game_screen.dart lib/profile_screen.dart test/widget_test.dart
git commit -m "feat: link profile screen from game"
```

## Task 5: Manual Verification

**Files:**
- No planned file changes.

- [ ] **Step 1: Run the app**

Run:

```bash
flutter run -d chrome
```

Expected: App launches in Chrome and shows the existing auth/game flow.

- [ ] **Step 2: Verify profile navigation**

Manual checks:

- Sign in with an existing account.
- Click the `Hồ sơ` profile icon in the game app bar.
- Confirm the profile screen shows username/email and only the `Đổi mật khẩu` option.
- Use the back button to return to the game screen.

- [ ] **Step 3: Verify validation**

Manual checks in the `Đổi mật khẩu` dialog:

- Empty submit shows `Vui lòng nhập mật khẩu hiện tại.`
- Short new password shows `Mật khẩu mới tối thiểu phải 6 ký tự.`
- Mismatched confirm password shows `Xác nhận mật khẩu không khớp.`
- Same old/new password shows `Mật khẩu mới phải khác mật khẩu hiện tại.`

- [ ] **Step 4: Verify Supabase behavior**

Manual checks:

- Wrong old password shows `Mật khẩu hiện tại không chính xác.`
- Correct old password and valid new password shows `Đổi mật khẩu thành công!`
- User remains signed in after success.
- Sign out and sign in again with the new password.

- [ ] **Step 5: Final status**

Run:

```bash
git status --short
```

Expected: clean working tree after all commits.
