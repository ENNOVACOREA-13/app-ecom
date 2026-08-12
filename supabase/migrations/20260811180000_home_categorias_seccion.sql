alter table app_config
  add column if not exists home_categorias_titulo text not null default 'Categorías de Servicios',
  add column if not exists home_categorias_forma text not null default 'circulo';

alter table app_config
  drop constraint if exists app_config_home_categorias_forma_check;

alter table app_config
  add constraint app_config_home_categorias_forma_check
  check (home_categorias_forma in ('circulo', 'cuadrado'));
