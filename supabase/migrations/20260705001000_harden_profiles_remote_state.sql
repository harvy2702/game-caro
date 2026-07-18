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

grant select on public.profiles to anon, authenticated;
grant insert on public.profiles to authenticated;

revoke update on public.profiles from anon, authenticated;
revoke update (id, username, created_at, updated_at) on public.profiles from anon, authenticated;

grant update (avatar_url) on public.profiles to authenticated;
