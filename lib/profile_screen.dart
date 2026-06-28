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
