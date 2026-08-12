alter table app_config
  add column if not exists store_enabled boolean not null default true;
