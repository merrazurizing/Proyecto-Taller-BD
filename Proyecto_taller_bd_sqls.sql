/*vista

V.5. Cree una vista con el valor promedio de los indicadores hospitalarios por Hospital, Servicio de Salud y año

trigger

T.1. Cree un trigger para que cada vez que se ingresa un nuevo establecimiento de salud, se verifique si depende de un servicio de salud, si es así, de
corresponder al servicio de salud que corresponde a la comuna donde se ubica.


funcion

F.5. Escriba una función que liste la cantidad de atenciones médicas por Establecimiento de salud, sexo y tipo de previsión, en un año pasado por
parámetro

*/

-- vista ------------------------------------------------------------------------------------

create view vista5 as
select empresa.nombre as Hospital, servicio_salud.nombre as servicio_salud, indicador_hospital.año ,avg(indicador_hospital.valor) as promedio_valor
from establecimiento_salud join hospital using (rut_empresa) join indicador_hospital using (rut_empresa) join empresa  using (rut_empresa)
join servicio_salud using(codigo_servicio_salud)
group by empresa.nombre,servicio_salud.nombre,indicador_hospital.año

-- trigger ------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION insert_establecimiento_salud()
RETURNS trigger AS $$
DECLARE

id_comuna_servicio_salud int;
id_comuna_establecimiento_salud int;

BEGIN

select into id_comuna_servicio_salud cod_ine_com from comuna where codigo_servicio_salud=new.codigo_servicio_salud;

select into id_comuna_establecimiento_salud cod_ine_com from empresa where rut_empresa=new.rut_empresa;



if(new.codigo_servicio_salud is not null) then 
	if(id_comuna_servicio_salud != id_comuna_establecimiento_salud) then
		raise exception 'comunas no coiciden';
		return null;
	else return new;
	end if;
else    
return new;
end if;

END; $$ LANGUAGE 'plpgsql' VOLATILE;


 
CREATE TRIGGER insert_establecimiento_salud_insert
BEFORE INSERT ON establecimiento_salud
FOR EACH ROW  
EXECUTE PROCEDURE insert_establecimiento_salud();


-- funcion ------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION funcion5(año_buscar int)
RETURNS SETOF RECORD AS $$
DECLARE

consulta CURSOR FOR SELECT rut_empresa as establecimiento_salud, sexo ,prevision, NULL::int as catidad_atenciones 
FROM atencion_medica join establecimiento_salud using (rut_empresa) join persona using(rut_persona) where EXTRACT(YEAR FROM fecha) =año_buscar;
fila_cursor RECORD;

BEGIN OPEN consulta;
LOOP
    FETCH consulta INTO fila_cursor;
    EXIT WHEN NOT FOUND;
    fila_cursor.cantidad_atenciones= (select count(id_a_medica) from atencion_medica join 
    establecimiento_salud using (rut_empresa) join persona using(rut_persona) 
    where rut_empresa=fila_cursor.establecimiento_salud and sexo = fila_cursor.sexo 
    and prevision=fila_cursor.prevision);
    RETURN NEXT fila_cursor;
END LOOP;
CLOSE consulta;
RETURN;
END;
$$ LANGUAGE 'plpgsql';


