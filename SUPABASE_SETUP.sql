-- انبار ستاره: اجرای این فایل در Supabase SQL Editor
-- ابتدا مطمئن شوید ستون‌های جدول با این نام‌ها و نوع‌ها وجود دارند.
-- warehouse_memberships: warehouse_id text, user_id uuid, role text
-- warehouse_inventory: warehouse_id text, item_id text, code text, name text,
-- size text, grade text, stock_m2 numeric, brand text, updated_at timestamptz

alter table public.warehouse_memberships enable row level security;
alter table public.warehouse_inventory enable row level security;

-- کاربر فقط عضویت خودش را می‌خواند.
drop policy if exists "setareh_member_read_self" on public.warehouse_memberships;
create policy "setareh_member_read_self"
on public.warehouse_memberships for select to authenticated
using (user_id = auth.uid());

-- هر عضو انبار فقط موجودی همان انبار را می‌بیند.
drop policy if exists "setareh_members_read_inventory" on public.warehouse_inventory;
create policy "setareh_members_read_inventory"
on public.warehouse_inventory for select to authenticated
using (
  warehouse_id = 'setareh'
  and exists (
    select 1 from public.warehouse_memberships m
    where m.warehouse_id = warehouse_inventory.warehouse_id
      and m.user_id = auth.uid()
      and m.role in ('manager','viewer')
  )
);

-- فقط مدیر همان انبار می‌تواند کالا اضافه کند.
drop policy if exists "setareh_manager_insert_inventory" on public.warehouse_inventory;
create policy "setareh_manager_insert_inventory"
on public.warehouse_inventory for insert to authenticated
with check (
  warehouse_id = 'setareh'
  and exists (
    select 1 from public.warehouse_memberships m
    where m.warehouse_id = warehouse_inventory.warehouse_id
      and m.user_id = auth.uid() and m.role = 'manager'
  )
);

-- فقط مدیر همان انبار می‌تواند کالا را ویرایش کند.
drop policy if exists "setareh_manager_update_inventory" on public.warehouse_inventory;
create policy "setareh_manager_update_inventory"
on public.warehouse_inventory for update to authenticated
using (
  warehouse_id = 'setareh'
  and exists (
    select 1 from public.warehouse_memberships m
    where m.warehouse_id = warehouse_inventory.warehouse_id
      and m.user_id = auth.uid() and m.role = 'manager'
  )
)
with check (
  warehouse_id = 'setareh'
  and exists (
    select 1 from public.warehouse_memberships m
    where m.warehouse_id = warehouse_inventory.warehouse_id
      and m.user_id = auth.uid() and m.role = 'manager'
  )
);

-- فقط مدیر همان انبار می‌تواند کالا را حذف کند.
drop policy if exists "setareh_manager_delete_inventory" on public.warehouse_inventory;
create policy "setareh_manager_delete_inventory"
on public.warehouse_inventory for delete to authenticated
using (
  warehouse_id = 'setareh'
  and exists (
    select 1 from public.warehouse_memberships m
    where m.warehouse_id = warehouse_inventory.warehouse_id
      and m.user_id = auth.uid() and m.role = 'manager'
  )
);

-- هیچ policy برای viewer روی INSERT/UPDATE/DELETE تعریف نشده است؛
-- در نتیجه RLS این عملیات را برای او مسدود می‌کند.
