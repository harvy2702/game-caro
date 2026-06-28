# Change Password Profile Design

## Goal

Add a very simple signed-in profile screen to the Caro app. The screen has only one account option: changing the current user's password.

## Current Context

The app is a Flutter application using Supabase Auth. `AuthGate` in `lib/main.dart` sends signed-out users to `AuthScreen` and signed-in users to `CaroGameScreen`. The game screen already shows a dark themed app bar, user metadata in the score area, and a logout action.

## User Experience

`CaroGameScreen` will add a profile/account icon in the app bar. Tapping it opens a new `ProfileScreen`.

`ProfileScreen` follows the existing dark visual style. It shows the signed-in user's username and email when available, plus one option: `Đổi mật khẩu`.

Tapping `Đổi mật khẩu` opens a compact dark themed `AlertDialog` containing the password change form. The form asks for:

- `Mật khẩu hiện tại`
- `Mật khẩu mới`
- `Xác nhận mật khẩu mới`

Each password field is obscured by default and can be toggled visible.

## Validation

The form validates before calling Supabase:

- All fields are required.
- The new password must be at least 6 characters.
- The confirmation password must match the new password.
- The new password must be different from the old password.

## Supabase Flow

On submit, the UI disables the submit action and shows loading. The app verifies the old password by signing in again with the current user's email and the old password. If verification succeeds, it updates the password with Supabase Auth.

On success, the app closes the change password form and shows a green snackbar: `Đổi mật khẩu thành công!`.

On failure, the form remains open and shows a clear Vietnamese error message. The user must remain signed in.

## Components

- `ProfileScreen`: a simple page for account information and the change password entry.
- Change password form: a compact `AlertDialog` owned by `ProfileScreen`.
- Shared helper behavior may be kept local to `ProfileScreen` unless reuse becomes necessary.

## Testing

Manual verification must cover:

- Navigating from the game screen to the profile screen.
- Opening the change password form.
- Required field validation.
- New password minimum length validation.
- Confirm password mismatch validation.
- Old password verification failure.
- Successful password update.
- Returning to the game screen without signing out.
