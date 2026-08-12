alter table app_config
  add column if not exists draft_config jsonb;
