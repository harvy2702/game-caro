import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  group('avatar upload helpers', () {
    test('builds a stable per-user avatar storage path', () {
      expect(
        avatarStoragePath(userId: 'user-123', fileName: 'photo.PNG'),
        'user-123/avatar.png',
      );

      expect(
        avatarStoragePath(userId: 'user-123', fileName: 'photo.jpeg'),
        'user-123/avatar.jpg',
      );

      expect(
        avatarStoragePath(userId: 'user-123', fileName: 'photo.unknown'),
        'user-123/avatar.jpg',
      );
    });

    test('returns supported avatar content types', () {
      expect(avatarContentTypeFromPath('user-123/avatar.jpg'), 'image/jpeg');
      expect(avatarContentTypeFromPath('user-123/avatar.png'), 'image/png');
      expect(avatarContentTypeFromPath('user-123/avatar.webp'), 'image/webp');
      expect(avatarContentTypeFromPath('user-123/avatar.gif'), 'image/gif');
      expect(avatarContentTypeFromPath('user-123/avatar.bin'), 'image/jpeg');
    });
  });

  testWidgets('ProfileScreen shows account info and change password option', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileScreen(
          usernameOverride: 'demo_user',
          emailOverride: 'demo@caro.local',
          skipInitialAvatarLoad: true,
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
          skipInitialAvatarLoad: true,
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

  testWidgets('Change password dialog shows validation errors before submit', (tester) async {
    var submitCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          usernameOverride: 'demo_user',
          emailOverride: 'demo@caro.local',
          skipInitialAvatarLoad: true,
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
          skipInitialAvatarLoad: true,
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
          skipInitialAvatarLoad: true,
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

  testWidgets('ProfileScreen shows avatar fallback when no avatar URL exists', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileScreen(
          usernameOverride: 'demo_user',
          emailOverride: 'demo@caro.local',
          skipInitialAvatarLoad: true,
        ),
      ),
    );

    expect(find.byTooltip('Đổi ảnh đại diện'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('ProfileScreen shows network avatar when avatar URL exists', (tester) async {
    const avatarUrl = 'https://example.com/avatar.jpg';

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileScreen(
          usernameOverride: 'demo_user',
          emailOverride: 'demo@caro.local',
          avatarUrlOverride: avatarUrl,
          skipInitialAvatarLoad: true,
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is NetworkImage &&
            (widget.image as NetworkImage).url == avatarUrl,
      ),
      findsOneWidget,
    );
  });

  testWidgets('ProfileScreen uploads avatar when avatar is tapped', (tester) async {
    var uploadCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          usernameOverride: 'demo_user',
          emailOverride: 'demo@caro.local',
          skipInitialAvatarLoad: true,
          uploadAvatarOverride: () async {
            uploadCount++;
            return 'https://example.com/new-avatar.jpg';
          },
        ),
      ),
    );

    await tester.tap(find.byTooltip('Đổi ảnh đại diện'));
    await tester.pumpAndSettle();

    expect(uploadCount, 1);
    expect(find.text('Cập nhật ảnh đại diện thành công!'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is NetworkImage &&
            (widget.image as NetworkImage).url == 'https://example.com/new-avatar.jpg',
      ),
      findsOneWidget,
    );
  });

  testWidgets('ProfileScreen shows avatar upload errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          usernameOverride: 'demo_user',
          emailOverride: 'demo@caro.local',
          skipInitialAvatarLoad: true,
          uploadAvatarOverride: () async {
            throw StateError('Không thể cập nhật ảnh đại diện.');
          },
        ),
      ),
    );

    await tester.tap(find.byTooltip('Đổi ảnh đại diện'));
    await tester.pumpAndSettle();

    expect(find.text('Không thể cập nhật ảnh đại diện.'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });
}
