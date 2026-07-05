create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  avatar_url text,
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now())
);

alter table public.profiles enable row level security;

create or replace function public.set_profiles_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc'::text, now());
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;

create trigger set_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_profiles_updated_at();

create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, username)
  values (
    new.id,
    nullif(new.raw_user_meta_data ->> 'username', '')
  )
  on conflict (id) do update
  set username = coalesce(excluded.username, public.profiles.username);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_create_profile on auth.users;

create trigger on_auth_user_created_create_profile
after insert on auth.users
for each row
execute function public.handle_new_user_profile();

with auth_user_profiles as (
  select
    users.id,
    nullif(users.raw_user_meta_data ->> 'username', '') as username,
    coalesce(users.created_at, timezone('utc'::text, now())) as created_at
  from auth.users
),
unique_auth_usernames as (
  select username
  from auth_user_profiles
  where username is not null
  group by username
  having count(*) = 1
)
insert into public.profiles (id, username, created_at, updated_at)
select
  auth_user_profiles.id,
  case
    when unique_auth_usernames.username is not null
      and not exists (
        select 1
        from public.profiles existing_profiles
        where existing_profiles.username = auth_user_profiles.username
          and existing_profiles.id <> auth_user_profiles.id
      )
    then auth_user_profiles.username
    else null
  end,
  auth_user_profiles.created_at,
  timezone('utc'::text, now())
from auth_user_profiles
left join unique_auth_usernames
  on unique_auth_usernames.username = auth_user_profiles.username
on conflict (id) do nothing;

drop policy if exists "Profiles are readable by everyone" on public.profiles;
drop policy if exists "Users can insert their own profile" on public.profiles;
drop policy if exists "Users can update their own profile" on public.profiles;

grant select on public.profiles to anon, authenticated;
grant insert on public.profiles to authenticated;
revoke update on public.profiles from authenticated;
grant update (avatar_url) on public.profiles to authenticated;

create policy "Profiles are readable by everyone"
on public.profiles
for select
using (true);

create policy "Users can insert their own profile"
on public.profiles
for insert
to authenticated
with check ((select auth.uid()) = id);

create policy "Users can update their own profile"
on public.profiles
for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'avatars',
  'avatars',
  true,
  2097152,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Avatar images are publicly readable" on storage.objects;
drop policy if exists "Users can insert own avatar" on storage.objects;
drop policy if exists "Users can update own avatar" on storage.objects;
drop policy if exists "Users can delete own avatar" on storage.objects;

create policy "Avatar images are publicly readable"
on storage.objects
for select
using (bucket_id = 'avatars');

create policy "Users can insert own avatar"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (select auth.uid())::text = (storage.foldername(name))[1]
);

create policy "Users can update own avatar"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'avatars'
  and (select auth.uid())::text = (storage.foldername(name))[1]
)
with check (
  bucket_id = 'avatars'
  and (select auth.uid())::text = (storage.foldername(name))[1]
);

create policy "Users can delete own avatar"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'avatars'
  and (select auth.uid())::text = (storage.foldername(name))[1]
);
