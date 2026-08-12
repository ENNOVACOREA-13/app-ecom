alter table app_config
  add column if not exists home_sections jsonb not null default '[
    {"key":"categorias","visible":true},
    {"key":"banner_promo","visible":true},
    {"key":"productos","visible":true}
  ]'::jsonb;
