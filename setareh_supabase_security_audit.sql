-- انبار ستاره | بررسی فقط‌خواندنی امنیت Supabase
-- این فایل هیچ داده یا تنظیمی را تغییر نمی‌دهد.
-- در Supabase > SQL Editor اجرا کنید و خروجی را برای بررسی بفرستید.

-- 1) وضعیت فعال بودن RLS برای جدول‌های انبار
select
  n.nspname as schema_name,
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as force_rls
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in (
    'warehouse_inventory',
    'warehouse_memberships',
    'warehouse_private_state',
    'users'
  )
order by c.relname;

-- 2) تمام Policyهای موجود روی جدول‌های انبار
select
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual as using_expression,
  with_check
from pg_policies
where schemaname = 'public'
  and tablename in (
    'warehouse_inventory',
    'warehouse_memberships',
    'warehouse_private_state',
    'users'
  )
order by tablename, policyname;

-- 3) ساختار واقعی ستون‌ها و نوع داده‌ها
select
  table_name,
  ordinal_position,
  column_name,
  data_type,
  is_nullable,
  column_default
from information_schema.columns
where table_schema = 'public'
  and table_name in (
    'warehouse_inventory',
    'warehouse_memberships',
    'warehouse_private_state',
    'users'
  )
order by table_name, ordinal_position;

-- 4) مجوزهای مستقیم جدول‌ها برای نقش‌های دیتابیس
select
  table_name,
  grantee,
  privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name in (
    'warehouse_inventory',
    'warehouse_memberships',
    'warehouse_private_state',
    'users'
  )
order by table_name, grantee, privilege_type;
