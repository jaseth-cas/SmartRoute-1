-- 1. Permitir que los usuarios inserten su propio perfil
create policy "Usuarios pueden insertar su propio perfil"
    on public.perfiles for insert
    to authenticated
    with check (id = auth.uid());

-- 2. Función y Trigger automático al crearse un usuario en auth.users
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.perfiles (id, nombre, email, rol, telefono)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nombre', split_part(new.email, '@', 1)),
    new.email,
    coalesce(new.raw_user_meta_data->>'rol', 'student'),
    new.raw_user_meta_data->>'telefono'
  )
  on conflict (id) do update set
    nombre = excluded.nombre,
    rol = excluded.rol,
    telefono = coalesce(excluded.telefono, perfiles.telefono);
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
