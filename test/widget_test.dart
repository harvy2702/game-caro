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
