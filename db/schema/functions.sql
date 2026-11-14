-- FOOD-104, FOOD-106, FOOD-107

set search_path to trofimov_food, exts;

create or replace procedure add_product(
	p_restaurant_id uuid,
	p_product_category_id uuid,
	p_name varchar,
	p_price numeric,
	p_rating numeric,
	p_status product_state,
	p_description text,
	p_photo_url text default null) as $$
begin
	if p_restaurant_id is null or p_restaurant_id not in (select restaurant_id from restaurant) then
		raise exception 'add_product: ресторан % не найден', p_restaurant_id;
	elseif p_product_category_id is null or p_product_category_id not in (select product_category_id from product_category) then
		raise exception 'add_product: категория % не найдена', p_product_category_id;
	elseif p_name is null or p_name = '' or p_status is null or p_description is null then
		raise exception 'add_product: у блюда должны быть название, статус и описание';
	elseif p_price is null or p_price < 0 then
		raise exception 'add_product: цена не может быть отрицательной, передано %', p_price;
	elseif p_rating < 0 or p_rating > 5 then
		raise exception 'add_product: рейтинг должен быть от 0 до 5, передано %', p_rating;
	end if;

	insert into product (product_name, product_category_id, price, restaurant_id, photo_url, rating, status, description)
	values (p_name, p_product_category_id, p_price, p_restaurant_id, p_photo_url, p_rating, p_status, p_description);

	raise notice 'add_product: блюдо «%» добавлено', p_name;
end;
$$ language plpgsql;

create or replace function get_statistic(
	out restaurant_name varchar,
	out best_product_name varchar,
	out total_amount numeric,
	out avg_amount numeric,
	out best_user varchar) returns setof record as $$
begin
	return query
		with sold as materialized (
			select o.order_id, o.restaurant_id, o.client_id, o.total_amount order_total
			from "order" o
			where o.status = 'доставлен'),
		dishes as materialized (
			select s.restaurant_id, p.product_name, sum(os.quantity) + random() / 1000 weight
			from sold s
			join order_structure os on os.order_id = s.order_id
			join product p on p.product_id = os.product_id
			group by s.restaurant_id, p.product_id),
		buyers as materialized (
			select s.restaurant_id, c.login, count(*) + random() / 2 weight
			from sold s
			join client c on c.client_id = s.client_id
			group by s.restaurant_id, c.client_id),
		top_dish as (
			select d.restaurant_id, max(d.weight) weight
			from dishes d
			group by d.restaurant_id),
		top_buyer as (
			select b.restaurant_id, max(b.weight) weight
			from buyers b
			group by b.restaurant_id),
		money as (
			select s.restaurant_id, sum(s.order_total) total_sum, round(avg(s.order_total), 2) avg_sum
			from sold s
			group by s.restaurant_id)
		select r.restaurant_name, d.product_name, coalesce(m.total_sum, 0), coalesce(m.avg_sum, 0), b.login
		from restaurant r
		left join money m on m.restaurant_id = r.restaurant_id
		left join top_dish td on td.restaurant_id = r.restaurant_id
		left join dishes d on d.restaurant_id = td.restaurant_id and d.weight = td.weight
		left join top_buyer tb on tb.restaurant_id = r.restaurant_id
		left join buyers b on b.restaurant_id = tb.restaurant_id and b.weight = tb.weight
		order by r.restaurant_name;
end;
$$ language plpgsql;

create or replace procedure courier_salary() as $$
declare
	v_from timestamp = date_trunc('month', localtimestamp);
	v_year int = date_part('year', localtimestamp);
	v_month int = date_part('month', localtimestamp);
begin
	with s as materialized (
		select c.courier_id,
			c.status,
			coalesce(cp.coefficient_used, c.coefficient) coef,
			cp.coefficient_used is null is_new,
			count(o.order_id) cnt,
			coalesce(sum(o.commission), 0) comm
		from courier c
		left join courier_pay cp on cp.courier_id = c.courier_id
			and cp.year = v_year
			and cp.month = v_month
		left join "order" o on o.courier_id = c.courier_id
			and o.status = 'доставлен'
			and o.order_timestamp >= v_from
			and o.order_timestamp < v_from + interval '1 month'
		group by c.courier_id, cp.coefficient_used),
	upd as (
		update courier_pay cp
		set amount = (select round(s.coef * s.comm, 2) from s where s.courier_id = cp.courier_id)
		where cp.year = v_year and cp.month = v_month),
	ins as (
		insert into courier_pay (year, month, courier_id, amount, coefficient_used)
		select v_year, v_month, s.courier_id, round(s.coef * s.comm, 2), s.coef
		from s
		where s.is_new)
	update courier c
	set coefficient = (
		select
			case
				when s.cnt <= 150 then 0.1
				when s.cnt <= 250 then 0.2
				when s.cnt <= 500 then 0.3
				else 0.5
			end
		from s
		where s.courier_id = c.courier_id)
	where c.status != 'уволен';

	raise notice 'courier_salary: зарплата за %.% рассчитана', v_month, v_year;
end;
$$ language plpgsql;
