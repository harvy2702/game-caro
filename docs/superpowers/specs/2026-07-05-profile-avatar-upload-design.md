# Profile Avatar Upload Design

## Goal

Add a simple avatar upload flow to the signed-in profile page. A user can tap the avatar area, choose one image from their device, upload it to Supabase Storage, and see the new avatar on the profile screen.

The feature should stay free-tier friendly by using one public bucket, overwriting one avatar file per user, and avoiding thumbnails, background jobs, or retained upload history.

## Current Context

The app is a Flutter Caro game using Supabase Auth through `supabase_flutter`. `AuthGate` routes signed-in users to `CaroGameScreen`, and the game screen already opens `ProfileScreen` from the app bar.

`ProfileScreen` currently shows a dark themed profile card with a circular person icon, username, email, and the existing change password option.

The app already queries a `profiles` table during signup to check username uniqueness, but the linked Supabase project currently does not have `public.profiles`. A REST check returned `PGRST205`, meaning the table is missing from the schema cache. The avatar work must therefore create the profile table instead of only adding an avatar column.

## User Experience

The current circular person icon on `ProfileScreen` becomes the avatar control.

When `profiles.avatar_url` exists, the profile card shows that image clipped inside the circle. When it is missing or the image fails to load, the screen keeps the current cyan person icon fallback.

Tapping the avatar opens the system gallery image picker. The user selects one image. The first version will not include camera capture, cropping, a remove-avatar button, or multiple-image selection.

During upload, the avatar control shows a small loading state and ignores repeat taps. On success, the screen refreshes immediately and shows `Cập nhật ảnh đại diện thành công!`. On failure, the previous avatar or fallback remains visible and the app shows a Vietnamese error snackbar.

## Data And Storage

Use `public.profiles` as the source of truth for profile data:

- `id uuid primary key references auth.users(id) on delete cascade`
- `username text unique`
- `avatar_url text`
- `created_at timestamptz default now()`
- `updated_at timestamptz default now()`

Add a database trigger on `auth.users` so new signups automatically receive a profile row. The trigger copies `raw_user_meta_data.username` into `profiles.username`, matching the current signup flow.

The migration should also backfill profile rows for existing auth users so current accounts can upload avatars immediately after the feature ships.

Use one public Supabase Storage bucket named `avatars`. Store the current avatar for each user under a user-scoped path:

```text
{auth.uid()}/avatar.{extension}
```

Uploads use overwrite/upsert semantics so each user keeps one active avatar. This prevents unbounded storage growth on the free account.

Storage policies should allow public reads from the `avatars` bucket. Authenticated users may insert, update, or delete only objects whose first path segment equals their own `auth.uid()`.

Profile table policies should allow anonymous and authenticated reads of public profile fields needed by the app, including the existing pre-signup username uniqueness check. Users may update only their own row, and the avatar feature only needs to update `avatar_url`.

## Supabase Resource Creation

Implementation should use Supabase CLI-managed SQL migrations for database and storage resources where possible. The repository currently has only `supabase/.temp/linked-project.json`, so implementation should create the normal Supabase project config or relink the project before applying migrations if the CLI cannot detect the linked project.

Required resources:

- `public.profiles` table, indexes/constraints, RLS, and policies.
- `auth.users` trigger to create profile rows.
- `avatars` storage bucket marked public.
- Storage object policies for user-scoped writes.

The implementation should avoid paid features and avoid creating duplicate buckets or unnecessary storage transformations.

## Flutter Implementation Shape

Convert `ProfileScreen` from `StatelessWidget` to `StatefulWidget` so it can load and refresh avatar state.

Add `image_picker` for gallery selection. After a user chooses an image, the screen reads the bytes, determines a simple file extension/content type, uploads the image to the `avatars` bucket, obtains the public URL, and updates `profiles.avatar_url`.

Keep the existing profile display and change password behavior intact. The username and email display can continue using the existing auth metadata fallback, while avatar state comes from `profiles.avatar_url`.

For testability, keep small pieces injectable in the same spirit as `changePasswordOverride`, such as avatar URL overrides or upload callbacks for widget tests.

## Error Handling

Handle these cases clearly:

- No signed-in user: show a user-facing error and do not open upload.
- User cancels the picker: do nothing.
- Unsupported or unreadable image: show an error snackbar.
- Storage upload fails: leave the old avatar visible and show an error snackbar.
- Profile update fails after upload: show an error snackbar; do not claim success.
- Network image fails to render: show the icon fallback.

## Testing And Verification

Automated tests should cover the profile screen rendering without an avatar, rendering with an avatar URL, and upload callback/loading behavior where practical. Pure helper tests should cover avatar storage path or content-type decisions if that logic is factored out.

Manual Supabase verification should cover:

- `profiles` table exists.
- Signup creates a profile row.
- `avatars` bucket exists and is public.
- A signed-in user can upload only to their own folder.
- Tapping the avatar updates `profiles.avatar_url`.
- The profile screen refreshes to the uploaded image.
- Existing change password behavior still works.
