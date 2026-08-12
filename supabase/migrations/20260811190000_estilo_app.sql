alter table app_config
  add column if not exists font_family text not null default 'Poppins',
  add column if not exists container_radius numeric not null default 16,
  add column if not exists container_shadow numeric not null default 1,
  add column if not exists categorias_icono_tamano numeric not null default 22;
 