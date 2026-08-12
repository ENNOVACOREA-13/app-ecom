alter table app_config
  add column if not exists home_productos_titulo text not null default 'Productos Populares';
