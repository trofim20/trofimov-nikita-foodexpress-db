-- FOOD-109

do $$
begin
	if (select count(*) from pg_roles where rolname = 'inspector') = 0 then
		create role inspector with login password 'NetoSQL2025';
	end if;
	execute 'grant connect on database ' || quote_ident(current_database()) || ' to inspector';
end;
$$;

alter role inspector with login password 'NetoSQL2025';
alter role inspector set search_path to trofimov_food, exts, public;

grant all privileges on schema trofimov_food to inspector;
grant all privileges on all tables in schema trofimov_food to inspector;
grant all privileges on all functions in schema trofimov_food to inspector;
grant all privileges on all procedures in schema trofimov_food to inspector;
alter default privileges in schema trofimov_food grant all privileges on tables to inspector;

grant usage on schema exts to inspector;
grant execute on function exts.uuid_generate_v4() to inspector;

grant usage on schema pg_catalog to inspector;
grant usage on schema information_schema to inspector;
