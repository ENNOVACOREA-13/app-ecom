-- Buckets de Storage privados sin las 4 políticas completas
-- (SELECT/INSERT/UPDATE/DELETE) — sin SELECT, cualquier subida con
-- upsert:true falla (bug real encontrado 2026-08-20, y justo por eso es
-- fácil no notar cuando falta: parece un problema de permisos de
-- escritura, no de lectura).
select
  b.id as bucket,
  array_agg(distinct p.cmd order by p.cmd) as comandos_con_politica,
  'le falta al menos uno de SELECT/INSERT/UPDATE/DELETE' as problema
from storage.buckets b
left join pg_policies p
  on p.schemaname = 'storage' and p.tablename = 'objects'
  and (
    position(b.id in coalesce(p.qual, '')) > 0
    or position(b.id in coalesce(p.with_check, '')) > 0
  )
where b.public = false
group by b.id
having count(distinct p.cmd) < 4;
